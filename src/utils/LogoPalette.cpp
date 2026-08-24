#include "LogoPalette.h"

#include "../database/DatabaseManager.h"
#include "LogUtils.h"
#include "Logging.h"

#include <QBuffer>
#include <QImage>
#include <QImageReader>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QUrl>

#include <algorithm>
#include <array>
#include <cmath>

namespace {

// Analyse : les pixels quasi transparents (bords adoucis, fond detoure) ne
// disent rien de la couleur du logo.
constexpr int kAlphaFloor = 96;
// Histogramme grossier : 12 secteurs de teinte x 4 niveaux de clarte, plus
// une classe achromatique par niveau (index kHueBins * kLumBins + niveau).
constexpr int kHueBins = 12;
constexpr int kLumBins = 4;
// Au-dela, la teinte compte : en deca le pixel est un gris.
constexpr float kGrayLimit = 0.15f;
// Bascule fond sombre / fond clair : luminance ou les deux candidats (clarte
// HSL 0.11 et 0.91) offrent le meme rapport de contraste WCAG.
constexpr double kLuminancePivot = 0.18;
// Une image opaque a ce point remplit sa vignette : le fond ne se voit qu'en
// lisere, il vaut mieux l'accorder au logo que le faire contraster.
constexpr double kOpaqueCoverage = 0.92;
// Taille d'analyse : au-dela on n'apprend plus rien sur la couleur dominante.
constexpr int kSampleSize = 96;
// Requetes simultanees : le defilement d'une grille peut demander des
// centaines de logos d'un coup.
constexpr int kMaxInFlight = 4;

// Prefixe des entrees de cache. A incrementer des que la derivation change,
// sinon les fonds calcules par l'ancienne formule restent servis.
const QLatin1String kCachePrefix("logo_bg1:");
// Fond par defaut du theme : memorise pour ne pas re-analyser a chaque session.
const QLatin1String kThemeBackdrop("-");

QString cacheKey(const QString &source)
{
    return kCachePrefix + source;
}

// Luminance relative WCAG : c'est elle, et non la clarte HSL, qui dit si une
// couleur ressortira sur un fond sombre ou sur un fond clair.
double relativeLuminance(const QColor &color)
{
    const auto linear = [](float channel) {
        return channel <= 0.04045f ? double(channel) / 12.92
                                   : std::pow((double(channel) + 0.055) / 1.055, 2.4);
    };
    return 0.2126 * linear(color.redF())
         + 0.7152 * linear(color.greenF())
         + 0.0722 * linear(color.blueF());
}

// Fond derive de la couleur dominante du logo et de sa part de pixels opaques.
QColor backdropFromDominant(const QColor &dominant, double coverage)
{
    float h = 0.0f, s = 0.0f, l = 0.0f, a = 0.0f;
    dominant.getHslF(&h, &s, &l, &a);
    const bool achromatic = (h < 0.0f || s < 0.10f);
    if (h < 0.0f)
        h = 0.0f;

    if (coverage > kOpaqueCoverage) {
        // Logo plein : le fond ne depasse qu'en lisere, un ton assorti et plus
        // sombre habille mieux la tuile qu'un contraste franc.
        if (achromatic)
            return {};
        return QColor::fromHslF(h, std::min(s, 0.55f),
                                std::clamp(l * 0.5f, 0.12f, 0.42f));
    }

    // Logo detoure : ses pixels se posent directement sur le fond, il faut
    // donc contraster avec eux. Le seuil est le point ou les deux fonds
    // candidats donnent le meme rapport de contraste WCAG.
    const bool lightLogo = relativeLuminance(dominant) > kLuminancePivot;
    // Glyphes clairs sans teinte (le cas le plus courant) : le fond sombre du
    // theme fait deja le travail.
    if (achromatic && lightLogo)
        return {};

    return QColor::fromHslF(h, std::min(s, lightLogo ? 0.40f : 0.28f),
                            lightLogo ? 0.11f : 0.91f);
}

// Decodage reduit : QImageReader sait demander une image mise a l'echelle au
// decodeur, ce qui evite de developper un PNG 1024x1024 pour 96 pixels utiles.
QImage readSample(QImageReader &reader)
{
    reader.setAutoTransform(true);
    const QSize size = reader.size();
    if (size.isValid() && (size.width() > kSampleSize || size.height() > kSampleSize))
        reader.setScaledSize(size.scaled(kSampleSize, kSampleSize, Qt::KeepAspectRatio));
    return reader.read();
}

} // namespace

LogoPalette::LogoPalette(QObject *parent)
    : QObject(parent)
    , m_nam(new QNetworkAccessManager(this))
{
}

QColor LogoPalette::backdrop(const QString &source)
{
    if (source.isEmpty())
        return {};

    const auto known = m_backdrops.constFind(source);
    if (known != m_backdrops.constEnd())
        return *known;

    const QString cached = DatabaseManager::instance().getCache(cacheKey(source));
    if (!cached.isEmpty()) {
        const QColor color = (cached == kThemeBackdrop) ? QColor() : QColor(cached);
        m_backdrops.insert(source, color);
        m_requested.insert(source);
        return color;
    }

    if (!m_requested.contains(source)) {
        m_requested.insert(source);
        m_queue.enqueue(source);
        pumpQueue();
    }
    return {};
}

QColor LogoPalette::backdropOf(const QImage &source)
{
    if (source.isNull())
        return {};

    QImage image = source;
    if (image.width() > kSampleSize || image.height() > kSampleSize)
        image = image.scaled(kSampleSize, kSampleSize, Qt::KeepAspectRatio,
                             Qt::FastTransformation);
    if (image.format() != QImage::Format_ARGB32)
        image = image.convertToFormat(QImage::Format_ARGB32);

    struct Bin { double weight = 0.0; double r = 0.0, g = 0.0, b = 0.0; };
    std::array<Bin, kHueBins * kLumBins + kLumBins> bins {};

    qint64 opaque = 0;
    const qint64 total = qint64(image.width()) * image.height();
    if (total <= 0)
        return {};

    for (int y = 0; y < image.height(); ++y) {
        const QRgb *line = reinterpret_cast<const QRgb *>(image.constScanLine(y));
        for (int x = 0; x < image.width(); ++x) {
            const QRgb pixel = line[x];
            if (qAlpha(pixel) < kAlphaFloor)
                continue;
            ++opaque;

            float h = 0.0f, s = 0.0f, l = 0.0f, a = 0.0f;
            QColor::fromRgb(pixel).getHslF(&h, &s, &l, &a);

            const int lumBin = std::clamp(int(l * kLumBins), 0, kLumBins - 1);
            const int index = (h < 0.0f || s < kGrayLimit)
                ? kHueBins * kLumBins + lumBin
                : std::clamp(int(h * kHueBins), 0, kHueBins - 1) * kLumBins + lumBin;

            // Les pixels satures pesent plus lourd : c'est la couleur qu'on
            // retient d'un logo, meme minoritaire face a du blanc.
            const double weight = 1.0 + 3.0 * s;
            Bin &bin = bins[size_t(index)];
            bin.weight += weight;
            bin.r += weight * qRed(pixel);
            bin.g += weight * qGreen(pixel);
            bin.b += weight * qBlue(pixel);
        }
    }

    if (opaque == 0)
        return {};

    const Bin &best = *std::max_element(
        bins.begin(), bins.end(),
        [](const Bin &lhs, const Bin &rhs) { return lhs.weight < rhs.weight; });
    if (best.weight <= 0.0)
        return {};

    const QColor dominant = QColor::fromRgb(
        std::clamp(int(std::lround(best.r / best.weight)), 0, 255),
        std::clamp(int(std::lround(best.g / best.weight)), 0, 255),
        std::clamp(int(std::lround(best.b / best.weight)), 0, 255));

    return backdropFromDominant(dominant, double(opaque) / double(total));
}

void LogoPalette::pumpQueue()
{
    while (m_inFlight < kMaxInFlight && !m_queue.isEmpty())
        fetch(m_queue.dequeue());
}

void LogoPalette::fetch(const QString &source)
{
    const QUrl url(source);
    const QString scheme = url.scheme();

    if (scheme.isEmpty() || scheme == QLatin1String("file")
        || scheme == QLatin1String("qrc")) {
        const QString path = url.isLocalFile() ? url.toLocalFile()
                           : (scheme == QLatin1String("qrc") ? QLatin1String(":") + url.path()
                                                             : source);
        // Differe : `fetch()` peut etre appele pendant l'evaluation d'un
        // binding QML, qui ne doit pas voir la propriete changer sous lui.
        QMetaObject::invokeMethod(this, [this, source, path]() {
            QImageReader reader(path);
            resolve(source, backdropOf(readSample(reader)), true);
        }, Qt::QueuedConnection);
        return;
    }

    ++m_inFlight;
    QNetworkRequest request(url);
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute,
                         QNetworkRequest::NoLessSafeRedirectPolicy);
    QNetworkReply *reply = m_nam->get(request);

    connect(reply, &QNetworkReply::finished, this, [this, reply, source]() {
        reply->deleteLater();
        --m_inFlight;

        const bool ok = (reply->error() == QNetworkReply::NoError);
        QColor color;
        if (ok) {
            QByteArray payload = reply->readAll();
            QBuffer buffer(&payload);
            buffer.open(QIODevice::ReadOnly);
            QImageReader reader(&buffer);
            color = backdropOf(readSample(reader));
        } else {
            qCDebug(logLogo) << "logo fetch failed" << LogUtils::scrubUrl(source)
                             << reply->errorString();
        }

        resolve(source, color, ok);
        pumpQueue();
    });
}

void LogoPalette::resolve(const QString &source, const QColor &color, bool persist)
{
    if (persist) {
        m_backdrops.insert(source, color);
        DatabaseManager::instance().setCache(
            cacheKey(source),
            color.isValid() ? color.name(QColor::HexRgb) : QString(kThemeBackdrop));
    } else {
        // Echec reseau : rien n'est memorise, le logo sera retente plus tard.
        m_requested.remove(source);
    }
    emit backdropResolved(source, color);
}

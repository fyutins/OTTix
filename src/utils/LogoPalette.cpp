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

// Analysis: near-transparent pixels (soft edges, cut-out background) say
// nothing about the logo color.
constexpr int kAlphaFloor = 96;
// Coarse histogram: 12 hue sectors x 4 lightness levels, plus one achromatic
// class per level (index kHueBins * kLumBins + level).
constexpr int kHueBins = 12;
constexpr int kLumBins = 4;
// Above this the hue counts; below it the pixel is a gray.
constexpr float kGrayLimit = 0.15f;
// Dark / light backdrop switch: the luminance at which both candidates (HSL
// lightness 0.11 and 0.91) give the same WCAG contrast ratio.
constexpr double kLuminancePivot = 0.18;
// An image this opaque fills its thumbnail: the backdrop only shows as a thin
// border, so matching it to the logo beats contrasting with it.
constexpr double kOpaqueCoverage = 0.92;
// Analysis size: beyond this, nothing more is learned about the dominant color.
constexpr int kSampleSize = 96;
// Concurrent requests: scrolling a grid can ask for hundreds of logos at once.
constexpr int kMaxInFlight = 4;

// Cache entry prefix. Bump it whenever the derivation changes, otherwise
// backdrops computed by the old formula keep being served.
const QLatin1String kCachePrefix("logo_bg1:");
// Theme default backdrop: memoized so it is not re-analyzed every session.
const QLatin1String kThemeBackdrop("-");

QString cacheKey(const QString &source)
{
    return kCachePrefix + source;
}

// WCAG relative luminance: this, and not HSL lightness, tells whether a color
// will stand out on a dark or on a light backdrop.
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

// Backdrop derived from the logo's dominant color and its share of opaque pixels.
QColor backdropFromDominant(const QColor &dominant, double coverage)
{
    float h = 0.0f, s = 0.0f, l = 0.0f, a = 0.0f;
    dominant.getHslF(&h, &s, &l, &a);
    const bool achromatic = (h < 0.0f || s < 0.10f);
    if (h < 0.0f)
        h = 0.0f;

    if (coverage > kOpaqueCoverage) {
        // Full-bleed logo: the backdrop only shows as a thin border, so a
        // matching, darker tone suits the tile better than a hard contrast.
        if (achromatic)
            return {};
        return QColor::fromHslF(h, std::min(s, 0.55f),
                                std::clamp(l * 0.5f, 0.12f, 0.42f));
    }

    // Cut-out logo: its pixels sit straight on the backdrop, so the backdrop
    // must contrast with them. The threshold is the point where both candidate
    // backdrops give the same WCAG contrast ratio.
    const bool lightLogo = relativeLuminance(dominant) > kLuminancePivot;
    // Light, hueless glyphs (the most common case): the theme's dark backdrop
    // already does the job.
    if (achromatic && lightLogo)
        return {};

    return QColor::fromHslF(h, std::min(s, lightLogo ? 0.40f : 0.28f),
                            lightLogo ? 0.11f : 0.91f);
}

// Reduced decoding: QImageReader can ask the decoder for a scaled image, which
// avoids expanding a 1024x1024 PNG for 96 useful pixels.
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

            // Saturated pixels weigh more: that is the color one remembers
            // from a logo, even when outnumbered by white.
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
        // Deferred: `fetch()` can be called while a QML binding is being
        // evaluated, and that binding must not see the property change underneath.
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
        // Network failure: nothing is memoized, the logo is retried later.
        m_requested.remove(source);
    }
    emit backdropResolved(source, color);
}

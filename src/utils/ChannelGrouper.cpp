#include "ChannelGrouper.h"

#include <algorithm>

QStringList ChannelGrouper::defaultSuffixes()
{
    return {
        QStringLiteral("2160p"),
        QStringLiteral("1080p"),
        QStringLiteral("720p"),
        QStringLiteral("576p"),
        QStringLiteral("480p"),
        QStringLiteral("360p"),
        QStringLiteral("240p"),
        QStringLiteral("FHD"),
        QStringLiteral("UHD"),
        QStringLiteral("HDR"),
        QStringLiteral("FULLHD"),
        QStringLiteral("HD"),
        QStringLiteral("SD"),
        QStringLiteral("HQ"),
        QStringLiteral("SQ"),
        QStringLiteral("LQ"),
        QStringLiteral("4K"),
        QStringLiteral("8K"),
        QStringLiteral("H.265"),
        QStringLiteral("H.264"),
        QStringLiteral("H265"),
        QStringLiteral("H264"),
        QStringLiteral("HEVC"),
        QStringLiteral("HVEC"),
        QStringLiteral("x265"),
        QStringLiteral("x264"),
        QStringLiteral("AVC"),
        QStringLiteral("VO"),
        QStringLiteral("VF"),
        QStringLiteral("VOSTFR"),
        QStringLiteral("VOST"),
        QStringLiteral("ENG"),
        QStringLiteral("FR"),
    };
}

// Nettoie une liste de suffixes : trim, doublons (insensibles a la casse) et
// tri du plus long au plus court — indispensable pour que « FULLHD » soit
// teste avant « HD » dans l'alternative de l'expression reguliere.
QStringList ChannelGrouper::normalizeSuffixes(const QStringList &suffixes)
{
    QStringList result;
    result.reserve(suffixes.size());
    for (const QString &s : suffixes) {
        const QString trimmed = s.trimmed();
        if (!trimmed.isEmpty() && !result.contains(trimmed, Qt::CaseInsensitive))
            result.append(trimmed);
    }
    std::sort(result.begin(), result.end(),
              [](const QString &a, const QString &b) { return a.length() > b.length(); });
    return result;
}

QStringList ChannelGrouper::combinedSuffixes(const QStringList &extraSuffixes)
{
    return normalizeSuffixes(defaultSuffixes() + extraSuffixes);
}

ChannelGrouper::SuffixPattern ChannelGrouper::buildPattern(const QStringList &extraSuffixes)
{
    return buildPatternFromList(combinedSuffixes(extraSuffixes));
}

// Construit le motif a partir de la liste exacte fournie : c'est ce que
// l'application utilise, pour que retirer un suffixe dans les reglages le
// retire vraiment (buildPattern y ajouterait toujours les suffixes par defaut).
ChannelGrouper::SuffixPattern ChannelGrouper::buildPatternFromList(const QStringList &list)
{
    QStringList suffixes = normalizeSuffixes(list);
    if (suffixes.isEmpty()) {
        return {};
    }

    QStringList escaped;
    escaped.reserve(suffixes.size());
    for (const QString &s : suffixes)
        escaped << QRegularExpression::escape(s);

    QString pattern = QStringLiteral(R"(^(.+?)[\s.\-–—_()\[\]]+((?:%1))[\s.\-–—_()\[\]]*$)")
                          .arg(escaped.join(u'|'));

    SuffixPattern sp;
    sp.regex = QRegularExpression(pattern, QRegularExpression::CaseInsensitiveOption);

    for (const QString &s : suffixes)
        sp.labelForCaptured[s.toLower()] = s;

    return sp;
}

ChannelGrouper::VariantInfo ChannelGrouper::analyzeWithPattern(const QString &name,
                                                                 const SuffixPattern &pattern)
{
    VariantInfo info;
    QString trimmed = name.trimmed();
    if (trimmed.isEmpty()) {
        info.baseName = trimmed;
        return info;
    }

    if (!pattern.regex.isValid()) {
        info.baseName = trimmed;
        return info;
    }

    QRegularExpressionMatch m = pattern.regex.match(trimmed);
    if (m.hasMatch()) {
        QString base = m.captured(1).trimmed();
        if (base.length() >= 2) {
            info.baseName = base;
            QString captured = m.captured(2);
            info.label = pattern.labelForCaptured.value(captured.toLower(), captured);
            return info;
        }
    }

    info.baseName = trimmed;
    return info;
}

// Legacy method kept for backward compatibility
ChannelGrouper::VariantInfo ChannelGrouper::analyze(const QString &name,
                                                      const QStringList &extraSuffixes)
{
    SuffixPattern pattern = buildPattern(extraSuffixes);
    return analyzeWithPattern(name, pattern);
}

#include "ChannelGrouper.h"

#include <QRegularExpression>

QStringList ChannelGrouper::defaultSuffixes()
{
    return {
        // Resolutions (longest first for greedy matching)
        QStringLiteral("2160p"),
        QStringLiteral("1080p"),
        QStringLiteral("720p"),
        QStringLiteral("576p"),
        QStringLiteral("480p"),
        QStringLiteral("360p"),
        QStringLiteral("240p"),
        // Visual quality
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
        // Codec
        QStringLiteral("H.265"),
        QStringLiteral("H.264"),
        QStringLiteral("HEVC"),
        QStringLiteral("HVEC"),
        QStringLiteral("x265"),
        QStringLiteral("x264"),
        QStringLiteral("AVC"),
        // Language / region variants
        QStringLiteral("VO"),
        QStringLiteral("VF"),
        QStringLiteral("VOSTFR"),
        QStringLiteral("VOST"),
        QStringLiteral("ENG"),
        QStringLiteral("FR"),
    };
}

QStringList ChannelGrouper::allSuffixes(const QStringList &extraSuffixes)
{
    QStringList result = defaultSuffixes();
    for (const QString &s : extraSuffixes) {
        QString trimmed = s.trimmed();
        if (!trimmed.isEmpty() && !result.contains(trimmed, Qt::CaseInsensitive))
            result.append(trimmed);
    }
    // Sort by length descending so longer suffixes match first
    std::sort(result.begin(), result.end(),
              [](const QString &a, const QString &b) { return a.length() > b.length(); });
    return result;
}

ChannelGrouper::VariantInfo ChannelGrouper::analyze(const QString &name,
                                                      const QStringList &extraSuffixes)
{
    VariantInfo info;
    QString trimmed = name.trimmed();
    if (trimmed.isEmpty()) {
        info.baseName = trimmed;
        return info;
    }

    QStringList suffixes = allSuffixes(extraSuffixes);

    for (const QString &suffix : suffixes) {
        // Pattern 1: with separators (space, dot, hyphen, underscore, parentheses, brackets)
        QString escaped = QRegularExpression::escape(suffix);
        QRegularExpression re(
            QStringLiteral(R"(^(.+?)[\s.\-–—_()\[\]]+(%1)[\s.\-–—_()\[\]]*$)")
                .arg(escaped),
            QRegularExpression::CaseInsensitiveOption);
        QRegularExpressionMatch m = re.match(trimmed);
        if (m.hasMatch()) {
            QString base = m.captured(1).trimmed();
            if (base.length() >= 2) {
                info.baseName = base;
                info.label = suffix;
                return info;
            }
        }
    }

    // No suffix found: the whole name is the base name
    info.baseName = trimmed;
    return info;
}

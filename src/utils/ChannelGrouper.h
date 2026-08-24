#pragma once

#include <QString>
#include <QStringList>
#include <QRegularExpression>
#include <QMap>

class ChannelGrouper
{
public:
    struct VariantInfo {
        QString baseName;
        QString label;
    };

    struct SuffixPattern {
        QRegularExpression regex;
        QMap<QString, QString> labelForCaptured;
    };

    static VariantInfo analyze(const QString &name, const QStringList &extraSuffixes = {});
    static VariantInfo analyzeWithPattern(const QString &name, const SuffixPattern &pattern);
    static SuffixPattern buildPattern(const QStringList &extraSuffixes = {});
    static SuffixPattern buildPatternFromList(const QStringList &list);
    static QStringList defaultSuffixes();
    static QStringList combinedSuffixes(const QStringList &extraSuffixes = {});
    static QStringList normalizeSuffixes(const QStringList &suffixes);

private:
    ChannelGrouper() = default;
};

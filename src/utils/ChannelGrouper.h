#pragma once

#include <QString>
#include <QStringList>

class ChannelGrouper
{
public:
    struct VariantInfo {
        QString baseName;
        QString label;
    };

    static VariantInfo analyze(const QString &name, const QStringList &extraSuffixes = {});
    static QStringList defaultSuffixes();
    static QStringList allSuffixes(const QStringList &extraSuffixes = {});

private:
    ChannelGrouper() = default;
};

#pragma once

#include <QObject>
#include <QString>
#include <QList>
#include "../database/DatabaseManager.h"

class M3UParser : public QObject
{
    Q_OBJECT

public:
    explicit M3UParser(QObject *parent = nullptr);

    QList<ChannelInfo> parse(const QString &filePath);
    QList<ChannelInfo> parseFromUrl(const QString &url);

signals:
    void parseProgress(int current, int total);
    void parseError(const QString &error);

private:
    ChannelInfo parseExtInf(const QString &extinf, const QString &url);
};

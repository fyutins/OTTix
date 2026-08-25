#pragma once

#include <QByteArray>
#include <QList>
#include <QObject>
#include <QString>
#include "../database/DatabaseManager.h"

class M3UParser : public QObject
{
    Q_OBJECT

public:
    explicit M3UParser(QObject *parent = nullptr);

    // Pure parsing, no signals and no state: callable from any thread
    // (used by PlaylistLoader through QtConcurrent).
    static QList<ChannelInfo> parseBuffer(const QByteArray &data, QString *error = nullptr);

    QList<ChannelInfo> parse(const QString &filePath);

signals:
    void parseError(const QString &error);
};

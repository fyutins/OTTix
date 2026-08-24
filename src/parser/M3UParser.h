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

    // Parsing pur, sans signaux ni etat : appelable depuis n'importe quel
    // thread (utilise par PlaylistLoader via QtConcurrent).
    static QList<ChannelInfo> parseBuffer(const QByteArray &data, QString *error = nullptr);

    QList<ChannelInfo> parse(const QString &filePath);

signals:
    void parseError(const QString &error);
};

#include "M3UParser.h"

#include <QFile>
#include <QTextStream>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QEventLoop>
#include <QRegularExpression>
#include <QUrlQuery>
#include <QDebug>

M3UParser::M3UParser(QObject *parent)
    : QObject(parent)
{
}

QList<ChannelInfo> M3UParser::parse(const QString &filePath)
{
    QList<ChannelInfo> channels;
    QFile file(filePath);

    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        emit parseError("Cannot open file: " + filePath);
        return channels;
    }

    QTextStream stream(&file);
    stream.setEncoding(QStringConverter::Utf8);

    QString line = stream.readLine().trimmed();
    if (!line.startsWith("#EXTM3U")) {
        emit parseError("Invalid M3U file: missing #EXTM3U header");
        return channels;
    }

    QString extinfLine;
    int lineNum = 0;

    while (!stream.atEnd()) {
        QString line = stream.readLine().trimmed();
        lineNum++;

        if (line.isEmpty())
            continue;

        if (line.startsWith("#EXTINF:")) {
            extinfLine = line;
        } else if (!line.startsWith("#")) {
            if (!extinfLine.isEmpty()) {
                ChannelInfo ch = parseExtInf(extinfLine, line);
                if (!ch.name.isEmpty()) {
                    channels.append(ch);
                }
                extinfLine.clear();
            }
        }

        if (lineNum % 100 == 0)
            emit parseProgress(channels.size(), 0);
    }

    file.close();
    emit parseProgress(channels.size(), channels.size());
    return channels;
}

QList<ChannelInfo> M3UParser::parseFromUrl(const QString &url)
{
    QList<ChannelInfo> channels;
    QNetworkAccessManager manager;
    QNetworkRequest request(url);
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute,
                         QNetworkRequest::NoLessSafeRedirectPolicy);

    QNetworkReply *reply = manager.get(request);
    QEventLoop loop;
    QObject::connect(reply, &QNetworkReply::finished, &loop, &QEventLoop::quit);
    loop.exec();

    if (reply->error() != QNetworkReply::NoError) {
        emit parseError("Network error: " + reply->errorString());
        reply->deleteLater();
        return channels;
    }

    QByteArray data = reply->readAll();
    reply->deleteLater();

    QTextStream stream(&data);
    stream.setEncoding(QStringConverter::Utf8);

    if (stream.readLine().trimmed() != "#EXTM3U") {
        emit parseError("Invalid M3U data: missing #EXTM3U header");
        return channels;
    }

    QString extinfLine;

    while (!stream.atEnd()) {
        QString line = stream.readLine().trimmed();

        if (line.isEmpty())
            continue;

        if (line.startsWith("#EXTINF:")) {
            extinfLine = line;
        } else if (!line.startsWith("#")) {
            if (!extinfLine.isEmpty()) {
                ChannelInfo ch = parseExtInf(extinfLine, line);
                if (!ch.name.isEmpty()) {
                    channels.append(ch);
                }
                extinfLine.clear();
            }
        }
    }

    emit parseProgress(channels.size(), channels.size());
    return channels;
}

ChannelInfo M3UParser::parseExtInf(const QString &extinf, const QString &url)
{
    ChannelInfo ch;
    ch.url = url;

    // #EXTINF:-1 tvg-id="channel.id" tvg-name="Channel Name" tvg-logo="http://logo.url" group-title="Group",Channel Name
    static QRegularExpression nameRegex(QStringLiteral(R"delim(,\s*(.+)\s*$)delim"));
    static QRegularExpression logoRegex(QStringLiteral(R"delim(tvg-logo="([^"]*)")delim"));
    static QRegularExpression groupRegex(QStringLiteral(R"delim(group-title="([^"]*)")delim"));
    static QRegularExpression tvgNameRegex(QStringLiteral(R"delim(tvg-name="([^"]*)")delim"));
    static QRegularExpression tvgIdRegex(QStringLiteral(R"delim(tvg-id="([^"]*)")delim"));

    QRegularExpressionMatch match;

    match = nameRegex.match(extinf);
    if (match.hasMatch())
        ch.name = match.captured(1).trimmed();

    match = tvgNameRegex.match(extinf);
    if (match.hasMatch())
        ch.name = match.captured(1).trimmed();

    match = logoRegex.match(extinf);
    if (match.hasMatch())
        ch.logo = match.captured(1);

    match = groupRegex.match(extinf);
    if (match.hasMatch())
        ch.group = match.captured(1);

    match = tvgIdRegex.match(extinf);
    if (match.hasMatch())
        ch.channelId = match.captured(1);

    return ch;
}

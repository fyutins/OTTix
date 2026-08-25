#include "M3UParser.h"

#include <QFile>
#include <QRegularExpression>
#include <QTextStream>

namespace {

// The channel name follows the comma that ends the attribute list. Since
// attributes may contain commas (group-title="Sport, Info"), look for the first
// comma located after the last quote.
int nameSeparatorIndex(const QString &extinf)
{
    const int lastQuote = extinf.lastIndexOf(u'"');
    const int from = lastQuote >= 0 ? lastQuote + 1 : 0;
    return extinf.indexOf(u',', from);
}

ChannelInfo parseExtInf(const QString &extinf, const QString &url)
{
    static const QRegularExpression logoRegex(QStringLiteral(R"re(tvg-logo="([^"]*)")re"));
    static const QRegularExpression groupRegex(QStringLiteral(R"re(group-title="([^"]*)")re"));
    static const QRegularExpression tvgNameRegex(QStringLiteral(R"re(tvg-name="([^"]*)")re"));
    static const QRegularExpression tvgIdRegex(QStringLiteral(R"re(tvg-id="([^"]*)")re"));

    ChannelInfo ch;
    ch.url = url;

    const int sep = nameSeparatorIndex(extinf);
    if (sep >= 0)
        ch.name = extinf.mid(sep + 1).trimmed();

    QRegularExpressionMatch match = tvgNameRegex.match(extinf);
    if (match.hasMatch() && !match.captured(1).trimmed().isEmpty())
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

} // namespace

M3UParser::M3UParser(QObject *parent)
    : QObject(parent)
{
}

QList<ChannelInfo> M3UParser::parseBuffer(const QByteArray &data, QString *error)
{
    QList<ChannelInfo> channels;

    QTextStream stream(data);
    stream.setEncoding(QStringConverter::Utf8);

    if (!stream.readLine().trimmed().startsWith("#EXTM3U")) {
        if (error)
            *error = QStringLiteral("Invalid M3U data: missing #EXTM3U header");
        return channels;
    }

    QString extinfLine;
    while (!stream.atEnd()) {
        const QString line = stream.readLine().trimmed();
        if (line.isEmpty())
            continue;

        if (line.startsWith("#EXTINF:")) {
            extinfLine = line;
        } else if (!line.startsWith("#") && !extinfLine.isEmpty()) {
            ChannelInfo ch = parseExtInf(extinfLine, line);
            if (!ch.name.isEmpty())
                channels.append(ch);
            extinfLine.clear();
        }
    }

    return channels;
}

QList<ChannelInfo> M3UParser::parse(const QString &filePath)
{
    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly)) {
        emit parseError("Cannot open file: " + filePath);
        return {};
    }

    QString error;
    QList<ChannelInfo> channels = parseBuffer(file.readAll(), &error);
    if (!error.isEmpty())
        emit parseError(error);
    return channels;
}

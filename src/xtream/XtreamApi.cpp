#include "XtreamApi.h"
#include "../utils/Logging.h"

#include <QNetworkReply>
#include <QNetworkRequest>
#include <QUrlQuery>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QRegularExpression>
#include <QDebug>

XtreamApi::XtreamApi(QObject *parent)
    : QObject(parent)
    , m_nam(new QNetworkAccessManager(this))
{
}

void XtreamApi::setCredentials(const QString &server, const QString &username, const QString &password)
{
    m_server = server;
    m_username = username;
    m_password = password;

    // Normalize server URL
    if (!m_server.endsWith('/'))
        m_server += '/';

    m_baseUrl = m_server + "player_api.php";
}

void XtreamApi::setBaseUrl(const QString &url)
{
    m_baseUrl = url;
}

bool XtreamApi::validateUrl(const QString &url)
{
    // Validate XTREAM URL format: http(s)://domain:port/
    static QRegularExpression re(R"(^https?://[^/]+(?::\d+)?/?)");
    return re.match(url).hasMatch();
}

QString XtreamApi::buildUrl(const QString &action, const QUrlQuery &extra) const
{
    QUrlQuery query;
    query.addQueryItem("username", m_username);
    query.addQueryItem("password", m_password);

    if (!action.isEmpty())
        query.addQueryItem("action", action);

    for (const auto &pair : extra.queryItems())
        query.addQueryItem(pair.first, pair.second);

    return m_baseUrl + "?" + query.toString();
}

QNetworkReply *XtreamApi::get(const QString &url)
{
    QNetworkRequest request{QUrl(url)};
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute,
                         QNetworkRequest::NoLessSafeRedirectPolicy);
    request.setHeader(QNetworkRequest::UserAgentHeader,
                      "IptvPlayer/1.0");
    return m_nam->get(request);
}

QJsonArray XtreamApi::asArray(const QJsonDocument &doc)
{
    if (doc.isArray())
        return doc.array();

    if (doc.isObject()) {
        const QJsonObject obj = doc.object();
        for (const QString &key : obj.keys()) {
            if (obj[key].isArray())
                return obj[key].toArray();
        }
    }
    return {};
}

void XtreamApi::request(const QString &action, const QUrlQuery &extra, const QString &context,
                        std::function<void(const QJsonDocument &)> onSuccess)
{
    QNetworkReply *reply = get(buildUrl(action, extra));

    connect(reply, &QNetworkReply::finished, this,
            [this, reply, context, onSuccess = std::move(onSuccess)]() {
        reply->deleteLater();

        if (reply->error() != QNetworkReply::NoError) {
            emit apiError(context + ": " + reply->errorString());
            return;
        }

        onSuccess(QJsonDocument::fromJson(reply->readAll()));
    });
}

void XtreamApi::authenticate()
{
    QString url = buildUrl(QString());
    QNetworkReply *reply = get(url);

    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();

        if (reply->error() != QNetworkReply::NoError) {
            emit authResult(false, reply->errorString(), {});
            return;
        }

        QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());

        if (!doc.isObject()) {
            emit authResult(false, "Invalid response from server", {});
            return;
        }

        QJsonObject obj = doc.object();

        if (obj.contains("user_info")) {
            QJsonValue userInfoVal = obj["user_info"];
            if (userInfoVal.isObject()) {
                QJsonObject userInfo = userInfoVal.toObject();
                if (userInfo.contains("auth") && !userInfo["auth"].toVariant().toBool()) {
                    emit authResult(false, "Invalid credentials", {});
                    return;
                }
            }
            emit authResult(true, "Authenticated", userInfoVal.toObject());
        } else if (obj.contains("auth") && !obj["auth"].toBool()) {
            emit authResult(false, "Invalid credentials", {});
        } else {
            emit authResult(true, "Authenticated", obj);
        }
    });
}

void XtreamApi::getUserInfo()
{
    authenticate();
}

void XtreamApi::getLiveCategories()
{
    request("get_live_categories", {}, "Failed to load live categories",
            [this](const QJsonDocument &doc) {
        emit liveCategoriesLoaded(parseCategories(asArray(doc)));
    });
}

void XtreamApi::getLiveStreams(const QString &categoryId)
{
    QUrlQuery extra;
    if (!categoryId.isEmpty())
        extra.addQueryItem("category_id", categoryId);

    request("get_live_streams", extra, "Failed to load live streams",
            [this](const QJsonDocument &doc) {
        const auto parsed = parseLiveStreams(asArray(doc));
        qCDebug(logXtream) << "Emitting liveStreamsLoaded with" << parsed.size() << "channels";
        emit liveStreamsLoaded(parsed);
    });
}

void XtreamApi::getVodCategories()
{
    request("get_vod_categories", {}, "Failed to load VOD categories",
            [this](const QJsonDocument &doc) {
        emit vodCategoriesLoaded(parseCategories(asArray(doc)));
    });
}

void XtreamApi::getVodStreams(const QString &categoryId)
{
    QUrlQuery extra;
    if (!categoryId.isEmpty())
        extra.addQueryItem("category_id", categoryId);

    request("get_vod_streams", extra, "Failed to load VOD streams",
            [this](const QJsonDocument &doc) {
        emit vodStreamsLoaded(parseVodStreams(asArray(doc)));
    });
}

void XtreamApi::getSeriesCategories()
{
    request("get_series_categories", {}, "Failed to load series categories",
            [this](const QJsonDocument &doc) {
        emit seriesCategoriesLoaded(parseCategories(asArray(doc)));
    });
}

void XtreamApi::getSeriesStreams(const QString &categoryId)
{
    QUrlQuery extra;
    if (!categoryId.isEmpty())
        extra.addQueryItem("category_id", categoryId);

    request("get_series", extra, "Failed to load series",
            [this](const QJsonDocument &doc) {
        emit seriesLoaded(parseLiveStreams(asArray(doc)));
    });
}

void XtreamApi::getEpg(const QString &streamId, int limit)
{
    QUrlQuery extra;
    extra.addQueryItem("stream_id", streamId);
    extra.addQueryItem("limit", QString::number(limit));

    request("get_simple_data_table", extra, "Failed to load EPG",
            [this](const QJsonDocument &doc) {
        if (doc.isArray())
            emit epgLoaded(doc.array());
        else if (doc.isObject())
            emit epgLoaded(doc.object()["epg_listings"].toArray());
        else
            emit epgLoaded(QJsonArray());
    });
}

void XtreamApi::getShortEpg()
{
    request("get_short_epg", {}, "Failed to load short EPG",
            [this](const QJsonDocument &doc) {
        emit shortEpgLoaded(doc.isObject() ? doc.object() : QJsonObject());
    });
}

QList<XtreamChannel> XtreamApi::parseVodStreams(const QJsonArray &data)
{
    QList<XtreamChannel> channels;

    for (const auto &val : data) {
        const QJsonObject s = val.toObject();
        XtreamChannel ch;
        ch.id = s["stream_id"].toVariant().toString();
        ch.name = s["name"].toString().trimmed();
        ch.streamType = "vod";
        ch.streamUrl = parseStreamUrl(ch.id, s["container_extension"].toString());
        ch.logo = s["stream_icon"].toString();
        ch.group = s["category_name"].toString();
        ch.categoryId = s["category_id"].toVariant().toString();
        ch.epgChannelId = s["epg_channel_id"].toString();

        if (ch.name.isEmpty()) {
            qCWarning(logXtream) << "Skipping VOD stream with empty name, id:" << ch.id;
            continue;
        }

        channels.append(ch);
    }

    qCDebug(logXtream) << "Parsed" << channels.size() << "VOD streams";
    return channels;
}

QList<ChannelInfo> XtreamApi::toChannelInfoList(const QList<XtreamChannel> &xtreamChannels, int playlistId)
{
    QList<ChannelInfo> result;
    for (const auto &xc : xtreamChannels) {
        ChannelInfo ci;
        ci.playlistId = playlistId;
        ci.name = xc.name;
        ci.url = xc.streamUrl;
        ci.logo = xc.logo;
        ci.group = xc.group;
        ci.channelId = xc.id;
        ci.streamType = xc.streamType;
        result.append(ci);
    }
    return result;
}

QList<ChannelInfo> XtreamApi::liveStreamsToChannels(const QJsonArray &streams)
{
    QList<XtreamChannel> parsed = parseLiveStreams(streams);
    QList<ChannelInfo> result;
    for (const auto &xc : parsed) {
        ChannelInfo ci;
        ci.name = xc.name;
        ci.url = xc.streamUrl;
        ci.logo = xc.logo;
        ci.group = xc.group;
        ci.channelId = xc.id;
        ci.streamType = "live";
        result.append(ci);
    }
    return result;
}

QList<ChannelInfo> XtreamApi::vodStreamsToChannels(const QJsonArray &streams)
{
    QList<ChannelInfo> result;
    for (const auto &val : streams) {
        QJsonObject s = val.toObject();
        ChannelInfo ci;
        ci.name = s["name"].toString();
        ci.streamType = "vod";
        ci.channelId = s["stream_id"].toVariant().toString();
        ci.url = parseStreamUrl(ci.channelId, s["container_extension"].toString());
        ci.logo = s["stream_icon"].toString();
        ci.group = s["category_name"].toString();
        result.append(ci);
    }
    return result;
}

// Private helpers

QList<XtreamCategory> XtreamApi::parseCategories(const QJsonArray &data)
{
    QList<XtreamCategory> categories;
    for (const auto &val : data) {
        QJsonObject obj = val.toObject();
        XtreamCategory cat;
        cat.categoryId = obj["category_id"].toVariant().toString();
        cat.name = obj["category_name"].toString();
        cat.parentId = obj["parent_id"].toInt();
        categories.append(cat);
    }
    return categories;
}

QList<XtreamChannel> XtreamApi::parseLiveStreams(const QJsonArray &data)
{
    QList<XtreamChannel> channels;
    channels.reserve(data.size());
    int skipped = 0;
    for (int i = 0; i < data.size(); i++) {
        QJsonObject s = data[i].toObject();
        XtreamChannel ch;
        ch.id = s["stream_id"].toVariant().toString();
        ch.name = s["name"].toString().trimmed();
        ch.streamType = "live";
        ch.streamUrl = parseStreamUrl(ch.id);
        ch.logo = s["stream_icon"].toString();
        ch.group = s["category_name"].toString();
        ch.categoryId = s["category_id"].toVariant().toString();
        ch.epgChannelId = s["epg_channel_id"].toString();

        if (i < 5 || (i % 5000 == 0)) {
            qCDebug(logXtream) << "[XAPI] Stream" << i
                     << "| name:" << ch.name
                     << "| category_name:" << ch.group
                     << "| category_id:" << ch.categoryId;
        }

        if (ch.name.isEmpty()) {
            qCWarning(logXtream) << "[XAPI] Skipping live stream with empty name, id:" << ch.id;
            skipped++;
            continue;
        }

        channels.append(ch);
    }
    qCDebug(logXtream) << "[XAPI] Parsed" << channels.size() << "live streams from" << data.size()
             << "entries (skipped" << skipped << ")";
    return channels;
}

QString XtreamApi::parseStreamUrl(const QString &streamId, const QString &extension) const
{
    // Build the stream URL: server_base/live/username/password/streamid.ext
    QString ext = extension.isEmpty() ? "ts" : extension;
    return m_server + "live/" + m_username + "/" + m_password + "/" + streamId + "." + ext;
}

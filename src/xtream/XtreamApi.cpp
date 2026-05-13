#include "XtreamApi.h"

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
    QString url = buildUrl("get_live_categories");
    QNetworkReply *reply = get(url);

    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();

        if (reply->error() != QNetworkReply::NoError) {
            emit apiError("Failed to load live categories: " + reply->errorString());
            return;
        }

        QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        QJsonArray arr;

        if (doc.isArray()) {
            arr = doc.array();
        } else if (doc.isObject()) {
            QJsonObject obj = doc.object();
            for (const auto &key : obj.keys()) {
                if (obj[key].isArray()) {
                    arr = obj[key].toArray();
                    break;
                }
            }
        }

        emit liveCategoriesLoaded(parseCategories(arr));
    });
}

void XtreamApi::getLiveStreams(const QString &categoryId)
{
    QUrlQuery extra;
    if (!categoryId.isEmpty())
        extra.addQueryItem("category_id", categoryId);

    QString url = buildUrl("get_live_streams", extra);
    QNetworkReply *reply = get(url);

    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();

        if (reply->error() != QNetworkReply::NoError) {
            emit apiError("Failed to load live streams: " + reply->errorString());
            return;
        }

        QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        QJsonArray arr;

        if (doc.isArray()) {
            arr = doc.array();
        } else if (doc.isObject()) {
            QJsonObject obj = doc.object();
            for (const auto &key : obj.keys()) {
                if (obj[key].isArray()) {
                    arr = obj[key].toArray();
                    break;
                }
            }
        }

        emit liveStreamsLoaded(parseLiveStreams(arr));
    });
}

void XtreamApi::getVodCategories()
{
    QString url = buildUrl("get_vod_categories");
    QNetworkReply *reply = get(url);

    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();

        if (reply->error() != QNetworkReply::NoError) {
            emit apiError("Failed to load VOD categories: " + reply->errorString());
            return;
        }

        QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        QJsonArray arr;

        if (doc.isArray()) {
            arr = doc.array();
        } else if (doc.isObject()) {
            QJsonObject obj = doc.object();
            for (const auto &key : obj.keys()) {
                if (obj[key].isArray()) {
                    arr = obj[key].toArray();
                    break;
                }
            }
        }

        emit vodCategoriesLoaded(parseCategories(arr));
    });
}

void XtreamApi::getVodStreams(const QString &categoryId)
{
    QUrlQuery extra;
    if (!categoryId.isEmpty())
        extra.addQueryItem("category_id", categoryId);

    QString url = buildUrl("get_vod_streams", extra);
    QNetworkReply *reply = get(url);

    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();

        if (reply->error() != QNetworkReply::NoError) {
            emit apiError("Failed to load VOD streams: " + reply->errorString());
            return;
        }

        QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        QJsonArray arr;

        if (doc.isArray()) {
            arr = doc.array();
        } else if (doc.isObject()) {
            QJsonObject obj = doc.object();
            for (const auto &key : obj.keys()) {
                if (obj[key].isArray()) {
                    arr = obj[key].toArray();
                    break;
                }
            }
        }
        QList<XtreamChannel> channels;

        for (const auto &val : arr) {
            QJsonObject s = val.toObject();
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
                qWarning() << "Skipping VOD stream with empty name, id:" << ch.id;
                continue;
            }

            channels.append(ch);
        }

        qDebug() << "Parsed" << channels.size() << "VOD streams";
        emit vodStreamsLoaded(channels);
    });
}

void XtreamApi::getSeriesCategories()
{
    QString url = buildUrl("get_series_categories");
    QNetworkReply *reply = get(url);

    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();

        if (reply->error() != QNetworkReply::NoError) {
            emit apiError("Failed to load series categories: " + reply->errorString());
            return;
        }

        QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        QJsonArray arr;

        if (doc.isArray()) {
            arr = doc.array();
        } else if (doc.isObject()) {
            QJsonObject obj = doc.object();
            for (const auto &key : obj.keys()) {
                if (obj[key].isArray()) {
                    arr = obj[key].toArray();
                    break;
                }
            }
        }

        emit liveCategoriesLoaded(parseCategories(arr));
    });
}

void XtreamApi::getSeriesStreams(const QString &categoryId)
{
    QUrlQuery extra;
    if (!categoryId.isEmpty())
        extra.addQueryItem("category_id", categoryId);

    QString url = buildUrl("get_series", extra);
    QNetworkReply *reply = get(url);

    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();

        if (reply->error() != QNetworkReply::NoError) {
            emit apiError("Failed to load series: " + reply->errorString());
            return;
        }

        QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        QJsonArray arr;

        if (doc.isArray()) {
            arr = doc.array();
        } else if (doc.isObject()) {
            QJsonObject obj = doc.object();
            for (const auto &key : obj.keys()) {
                if (obj[key].isArray()) {
                    arr = obj[key].toArray();
                    break;
                }
            }
        }

        emit liveStreamsLoaded(parseLiveStreams(arr));
    });
}

void XtreamApi::getEpg(const QString &streamId, int limit)
{
    QUrlQuery extra;
    extra.addQueryItem("stream_id", streamId);
    extra.addQueryItem("limit", QString::number(limit));

    QString url = buildUrl("get_simple_data_table", extra);
    QNetworkReply *reply = get(url);

    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();

        if (reply->error() != QNetworkReply::NoError) {
            emit apiError("Failed to load EPG: " + reply->errorString());
            return;
        }

        QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());

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
    QString url = buildUrl("get_short_epg");
    QNetworkReply *reply = get(url);

    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();

        if (reply->error() != QNetworkReply::NoError) {
            emit apiError("Failed to load short EPG: " + reply->errorString());
            return;
        }

        QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());

        if (doc.isObject())
            emit shortEpgLoaded(doc.object());
        else
            emit shortEpgLoaded(QJsonObject());
    });
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

        if (i < 5) {
            qDebug() << "Stream" << i
                     << "| name:" << ch.name
                     << "| category_name:" << ch.group
                     << "| category_id:" << ch.categoryId
                     << "| raw category_id type:" << s["category_id"].type();
        }

        if (ch.name.isEmpty()) {
            qWarning() << "Skipping live stream with empty name, id:" << ch.id;
            continue;
        }

        channels.append(ch);
    }
    qDebug() << "Parsed" << channels.size() << "live streams from" << data.size() << "entries";
    return channels;
}

QString XtreamApi::parseStreamUrl(const QString &streamId, const QString &extension) const
{
    // Build the stream URL: server_base/live/username/password/streamid.ext
    QString ext = extension.isEmpty() ? "ts" : extension;
    return m_server + "live/" + m_username + "/" + m_password + "/" + streamId + "." + ext;
}

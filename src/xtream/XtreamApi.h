#pragma once

#include <QObject>
#include <QString>
#include <QUrlQuery>
#include <QJsonObject>
#include <QJsonArray>
#include <QNetworkAccessManager>
#include <QJsonDocument>
#include <QList>
#include <functional>
#include "../database/DatabaseManager.h"

struct XtreamCategory {
    QString categoryId;
    QString name;
    int parentId = 0;
};

struct XtreamChannel {
    QString id;
    QString name;
    QString streamType;
    QString streamUrl;
    QString logo;
    QString group;
    QString categoryId;
    QString epgChannelId;
};

class XtreamApi : public QObject
{
    Q_OBJECT

public:
    explicit XtreamApi(QObject *parent = nullptr);

    void setCredentials(const QString &server, const QString &username, const QString &password);
    void setBaseUrl(const QString &url);

    QString baseUrl() const { return m_baseUrl; }
    QString username() const { return m_username; }
    QString password() const { return m_password; }

    bool validateUrl(const QString &url);

    // Auth & Info
    void authenticate();
    void getUserInfo();

    // Live TV
    void getLiveCategories();
    void getLiveStreams(const QString &categoryId = QString());

    // VOD
    void getVodCategories();
    void getVodStreams(const QString &categoryId = QString());

    // Series
    void getSeriesCategories();
    void getSeriesStreams(const QString &categoryId = QString());

    // EPG
    void getEpg(const QString &streamId, int limit = 5);

    // Short EPG (all channels)
    void getShortEpg();

    // Convert to ChannelInfo list
    QList<ChannelInfo> toChannelInfoList(const QList<XtreamChannel> &xtreamChannels, int playlistId);
    QList<ChannelInfo> liveStreamsToChannels(const QJsonArray &streams);
    QList<ChannelInfo> vodStreamsToChannels(const QJsonArray &streams);

signals:
    void authResult(bool success, const QString &message, const QJsonObject &userInfo);
    void liveCategoriesLoaded(const QList<XtreamCategory> &categories);
    void liveStreamsLoaded(const QList<XtreamChannel> &channels);
    void vodCategoriesLoaded(const QList<XtreamCategory> &categories);
    void vodStreamsLoaded(const QList<XtreamChannel> &channels);
    void seriesCategoriesLoaded(const QList<XtreamCategory> &categories);
    void seriesLoaded(const QList<XtreamChannel> &series);
    void epgLoaded(const QJsonArray &epgData);
    void shortEpgLoaded(const QJsonObject &epgData);
    void apiError(const QString &error);

private:
    QString buildUrl(const QString &action, const QUrlQuery &extra = QUrlQuery()) const;
    QNetworkReply *get(const QString &url);

    // Envoie une requete player_api et remet le JSON au callback ; toute erreur
    // reseau est convertie en apiError("<context>: ...").
    void request(const QString &action, const QUrlQuery &extra, const QString &context,
                 std::function<void(const QJsonDocument &)> onSuccess);

    // Un serveur Xtream repond tantot par un tableau, tantot par un objet qui
    // contient le tableau.
    static QJsonArray asArray(const QJsonDocument &doc);

    QList<XtreamChannel> parseVodStreams(const QJsonArray &data);
    QList<XtreamCategory> parseCategories(const QJsonArray &data);
    QList<XtreamChannel> parseLiveStreams(const QJsonArray &data);
    QString parseStreamUrl(const QString &streamId, const QString &extension = QString()) const;

    QNetworkAccessManager *m_nam;
    QString m_server;
    QString m_username;
    QString m_password;
    QString m_baseUrl;
};

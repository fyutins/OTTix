#pragma once

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include "../parser/M3UParser.h"
#include "../xtream/XtreamApi.h"
#include "../database/DatabaseManager.h"

class PlaylistLoader : public QObject
{
    Q_OBJECT

public:
    explicit PlaylistLoader(QObject *parent = nullptr);

    Q_INVOKABLE void loadM3U(int playlistId, const QString &url);
    Q_INVOKABLE void loadXtream(int playlistId, const QString &url,
                                 const QString &username, const QString &password);
    Q_INVOKABLE void cancel();

signals:
    void loadStarted(int playlistId);
    void loadProgress(int playlistId, int current, int total);
    void loadComplete(int playlistId, int channelCount);
    void loadError(int playlistId, const QString &error);

private slots:
    void onM3UDownloaded();
    void onXtreamAuthResult(bool success, const QString &message, const QJsonObject &userInfo);
    void onXtreamCategoriesLoaded(const QList<XtreamCategory> &categories);
    void onXtreamStreamsLoaded(const QList<XtreamChannel> &channels);

private:
    void storeChannels(int playlistId, const QList<ChannelInfo> &channels);

    QNetworkAccessManager *m_nam;
    M3UParser *m_m3uParser;
    XtreamApi *m_xtreamApi;
    QNetworkReply *m_currentReply = nullptr;

    int m_currentPlaylistId = -1;
    QString m_currentType;

    // XTREAM state
    QList<XtreamCategory> m_xtreamCategories;
    QList<ChannelInfo> m_xtreamChannels;
};

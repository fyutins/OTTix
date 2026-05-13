#pragma once

#include <QObject>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlRecord>
#include <QSqlError>
#include <QJsonObject>
#include <QJsonArray>
#include <QJsonDocument>
#include <QString>
#include <QStringList>
#include <QVariantList>
#include <QVariantMap>
#include <QDateTime>

struct ChannelInfo {
    int id = -1;
    int playlistId = -1;
    QString name;
    QString url;
    QString logo;
    QString group;
    QString channelId;
    QString streamType;
    bool isFavorite = false;

    QJsonObject toJson() const {
        return {
            {"id", id},
            {"playlistId", playlistId},
            {"name", name},
            {"url", url},
            {"logo", logo},
            {"group", group},
            {"channelId", channelId},
            {"streamType", streamType}
        };
    }

    static ChannelInfo fromJson(const QJsonObject &obj) {
        return {
            obj["id"].toInt(),
            obj["playlistId"].toInt(),
            obj["name"].toString(),
            obj["url"].toString(),
            obj["logo"].toString(),
            obj["group"].toString(),
            obj["channelId"].toString(),
            obj["streamType"].toString()
        };
    }
};

struct PlaylistInfo {
    int id = -1;
    QString name;
    QString url;
    QString type; // "m3u" or "xtream"
    QString username;
    QString password;
    QDateTime createdAt;
    int channelCount = 0;

    QJsonObject toJson() const {
        return {
            {"id", id},
            {"name", name},
            {"url", url},
            {"type", type},
            {"username", username},
            {"password", password}
        };
    }

    static PlaylistInfo fromJson(const QJsonObject &obj) {
        PlaylistInfo p;
        p.id = obj["id"].toInt();
        p.name = obj["name"].toString();
        p.url = obj["url"].toString();
        p.type = obj["type"].toString("m3u");
        p.username = obj["username"].toString();
        p.password = obj["password"].toString();
        return p;
    }
};

class DatabaseManager : public QObject
{
    Q_OBJECT

public:
    static DatabaseManager &instance();

    bool initialize(const QString &path = QString());

    // Playlist CRUD
    int addPlaylist(const PlaylistInfo &playlist);
    bool removePlaylist(int id);
    bool updatePlaylist(const PlaylistInfo &playlist);
    QList<PlaylistInfo> getPlaylists();
    PlaylistInfo getPlaylist(int id);

    // Channel CRUD
    int addChannel(const ChannelInfo &channel);
    bool addChannels(const QList<ChannelInfo> &channels);
    bool removeChannelsByPlaylist(int playlistId);
    QList<ChannelInfo> getChannels(int playlistId);
    QList<ChannelInfo> searchChannels(const QString &query);
    ChannelInfo getChannel(int id);
    int channelCount(int playlistId);

    // Favorites
    Q_INVOKABLE bool addFavorite(int channelId);
    Q_INVOKABLE bool removeFavorite(int channelId);
    bool isFavorite(int channelId);
    QList<ChannelInfo> getFavorites();
    QList<int> getFavoriteIds();
    Q_INVOKABLE QVariantList getFavoritesVariant();

signals:
    void favoritesChanged();

public:
    // Cache
    void setCache(const QString &key, const QString &data);
    QString getCache(const QString &key);
    void clearCache(int olderThanDays = 7);

private:
    DatabaseManager();
    ~DatabaseManager();
    DatabaseManager(const DatabaseManager &) = delete;
    DatabaseManager &operator=(const DatabaseManager &) = delete;

    void createTables();
    QSqlDatabase m_db;
};

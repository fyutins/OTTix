#include "DatabaseManager.h"
#include "../utils/Logging.h"

#include <QJSEngine>

#include <QCoreApplication>
#include <QDir>
#include <QDebug>
#include <QSet>
#include <QStandardPaths>

DatabaseManager &DatabaseManager::instance()
{
    static DatabaseManager inst;
    return inst;
}

DatabaseManager *DatabaseManager::create(QQmlEngine *, QJSEngine *)
{
    DatabaseManager *inst = &instance();
    QJSEngine::setObjectOwnership(inst, QJSEngine::CppOwnership);
    return inst;
}

DatabaseManager::DatabaseManager() {}

DatabaseManager::~DatabaseManager()
{
    if (m_db.isOpen())
        m_db.close();
}

bool DatabaseManager::initialize(const QString &path)
{
    QString dbPath = path;
    if (dbPath.isEmpty()) {
        QString dataDir = QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation);
        QDir().mkpath(dataDir);
        dbPath = dataDir + "/iptv_player.db";
    }

    m_db = QSqlDatabase::addDatabase("QSQLITE");
    m_db.setDatabaseName(dbPath);

    if (!m_db.open()) {
        qCWarning(logDb) << "Failed to open database:" << m_db.lastError().text();
        return false;
    }

    qCInfo(logDb) << "Database opened at:" << dbPath;
    createTables();
    migrateSettingsFromCache();
    return true;
}

void DatabaseManager::createTables()
{
    QSqlQuery q(m_db);

    q.exec(R"(
        CREATE TABLE IF NOT EXISTS playlists (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            url TEXT NOT NULL,
            type TEXT NOT NULL DEFAULT 'm3u',
            username TEXT,
            password TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    )");

    q.exec(R"(
        CREATE TABLE IF NOT EXISTS channels (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            playlist_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            url TEXT NOT NULL,
            logo TEXT,
            group_name TEXT,
            channel_id TEXT,
            stream_type TEXT,
            FOREIGN KEY (playlist_id) REFERENCES playlists(id) ON DELETE CASCADE
        )
    )");

    q.exec(R"(
        CREATE TABLE IF NOT EXISTS favorites (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            channel_id INTEGER NOT NULL UNIQUE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (channel_id) REFERENCES channels(id) ON DELETE CASCADE
        )
    )");

    q.exec(R"(
        CREATE TABLE IF NOT EXISTS cache (
            key TEXT PRIMARY KEY,
            data TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    )");

    q.exec(R"(
        CREATE TABLE IF NOT EXISTS watch_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            url TEXT NOT NULL UNIQUE,
            logo TEXT,
            group_name TEXT,
            watched_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    )");

    q.exec(R"(
        CREATE TABLE IF NOT EXISTS settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
        )
    )");

    q.exec("CREATE INDEX IF NOT EXISTS idx_channels_playlist ON channels(playlist_id)");
    q.exec("CREATE INDEX IF NOT EXISTS idx_channels_name ON channels(name)");
    q.exec("CREATE INDEX IF NOT EXISTS idx_watch_history_watched ON watch_history(watched_at)");

    q.exec("PRAGMA foreign_keys = ON");
}

int DatabaseManager::addPlaylist(const PlaylistInfo &playlist)
{
    QSqlQuery q(m_db);
    q.prepare(R"(INSERT INTO playlists (name, url, type, username, password)
                  VALUES (:name, :url, :type, :username, :password))");
    q.bindValue(":name", playlist.name);
    q.bindValue(":url", playlist.url);
    q.bindValue(":type", playlist.type);
    q.bindValue(":username", playlist.username);
    q.bindValue(":password", playlist.password);

    if (!q.exec()) {
        qCWarning(logDb) << "Failed to add playlist:" << q.lastError().text();
        return -1;
    }
    return q.lastInsertId().toInt();
}

bool DatabaseManager::removePlaylist(int id)
{
    QSqlQuery q(m_db);
    q.prepare("DELETE FROM playlists WHERE id = :id");
    q.bindValue(":id", id);
    return q.exec();
}

bool DatabaseManager::updatePlaylist(const PlaylistInfo &playlist)
{
    QSqlQuery q(m_db);
    q.prepare(R"(UPDATE playlists SET name = :name, url = :url, type = :type,
                  username = :username, password = :password WHERE id = :id)");
    q.bindValue(":name", playlist.name);
    q.bindValue(":url", playlist.url);
    q.bindValue(":type", playlist.type);
    q.bindValue(":username", playlist.username);
    q.bindValue(":password", playlist.password);
    q.bindValue(":id", playlist.id);
    return q.exec();
}

QList<PlaylistInfo> DatabaseManager::getPlaylists()
{
    QList<PlaylistInfo> result;
    QSqlQuery q(m_db);

    if (!q.exec("SELECT p.*, (SELECT COUNT(*) FROM channels c WHERE c.playlist_id = p.id) AS channel_count FROM playlists p ORDER BY p.created_at DESC")) {
        qCWarning(logDb) << "Failed to get playlists:" << q.lastError().text();
        return result;
    }

    while (q.next()) {
        PlaylistInfo p;
        p.id = q.value("id").toInt();
        p.name = q.value("name").toString();
        p.url = q.value("url").toString();
        p.type = q.value("type").toString();
        p.username = q.value("username").toString();
        p.password = q.value("password").toString();
        p.createdAt = q.value("created_at").toDateTime();
        p.channelCount = q.value("channel_count").toInt();
        result.append(p);
    }

    return result;
}

PlaylistInfo DatabaseManager::getPlaylist(int id)
{
    PlaylistInfo p;
    QSqlQuery q(m_db);
    q.prepare("SELECT * FROM playlists WHERE id = :id");
    q.bindValue(":id", id);

    if (!q.exec() || !q.next())
        return p;

    p.id = q.value("id").toInt();
    p.name = q.value("name").toString();
    p.url = q.value("url").toString();
    p.type = q.value("type").toString();
    p.username = q.value("username").toString();
    p.password = q.value("password").toString();
    p.createdAt = q.value("created_at").toDateTime();
    return p;
}

int DatabaseManager::addChannel(const ChannelInfo &channel)
{
    QSqlQuery q(m_db);
    q.prepare(R"(INSERT INTO channels (playlist_id, name, url, logo, group_name, channel_id, stream_type)
                  VALUES (:playlist_id, :name, :url, :logo, :group_name, :channel_id, :stream_type))");
    q.bindValue(":playlist_id", channel.playlistId);
    q.bindValue(":name", channel.name);
    q.bindValue(":url", channel.url);
    q.bindValue(":logo", channel.logo);
    q.bindValue(":group_name", channel.group);
    q.bindValue(":channel_id", channel.channelId);
    q.bindValue(":stream_type", channel.streamType);

    if (!q.exec()) {
        qCWarning(logDb) << "Failed to add channel:" << q.lastError().text();
        return -1;
    }
    return q.lastInsertId().toInt();
}

bool DatabaseManager::addChannels(const QList<ChannelInfo> &channels)
{
    m_db.transaction();
    QSqlQuery q(m_db);
    q.prepare(R"(INSERT INTO channels (playlist_id, name, url, logo, group_name, channel_id, stream_type)
                  VALUES (:playlist_id, :name, :url, :logo, :group_name, :channel_id, :stream_type))");

    for (const auto &ch : channels) {
        q.bindValue(":playlist_id", ch.playlistId);
        q.bindValue(":name", ch.name);
        q.bindValue(":url", ch.url);
        q.bindValue(":logo", ch.logo);
        q.bindValue(":group_name", ch.group);
        q.bindValue(":channel_id", ch.channelId);
        q.bindValue(":stream_type", ch.streamType);
        if (!q.exec()) {
            qCWarning(logDb) << "Failed to add channel:" << q.lastError().text();
            m_db.rollback();
            return false;
        }
    }

    return m_db.commit();
}

bool DatabaseManager::removeChannelsByPlaylist(int playlistId)
{
    QSqlQuery q(m_db);
    q.prepare("DELETE FROM channels WHERE playlist_id = :id");
    q.bindValue(":id", playlistId);
    return q.exec();
}

bool DatabaseManager::replaceChannels(int playlistId, const QList<ChannelInfo> &channels)
{
    m_db.transaction();
    QSqlQuery q(m_db);

    QSet<QString> favChannelIds;
    q.prepare("SELECT c.channel_id FROM channels c INNER JOIN favorites f ON c.id = f.channel_id WHERE c.playlist_id = :id");
    q.bindValue(":id", playlistId);
    if (q.exec()) {
        while (q.next())
            favChannelIds.insert(q.value(0).toString());
    }

    q.prepare("DELETE FROM channels WHERE playlist_id = :id");
    q.bindValue(":id", playlistId);
    if (!q.exec()) {
        qCWarning(logDb) << "Failed to remove old channels:" << q.lastError().text();
        m_db.rollback();
        return false;
    }

    q.prepare(R"(INSERT INTO channels (playlist_id, name, url, logo, group_name, channel_id, stream_type)
                  VALUES (:playlist_id, :name, :url, :logo, :group_name, :channel_id, :stream_type))");

    QList<int> newIds;
    newIds.reserve(channels.size());

    for (const auto &ch : channels) {
        q.bindValue(":playlist_id", ch.playlistId);
        q.bindValue(":name", ch.name);
        q.bindValue(":url", ch.url);
        q.bindValue(":logo", ch.logo);
        q.bindValue(":group_name", ch.group);
        q.bindValue(":channel_id", ch.channelId);
        q.bindValue(":stream_type", ch.streamType);
        if (!q.exec()) {
            qCWarning(logDb) << "Failed to add channel:" << q.lastError().text();
            m_db.rollback();
            return false;
        }
        newIds.append(q.lastInsertId().toInt());
    }

    q.prepare("INSERT OR IGNORE INTO favorites (channel_id) VALUES (:id)");
    for (int i = 0; i < channels.size(); ++i) {
        if (favChannelIds.contains(channels[i].channelId)) {
            q.bindValue(":id", newIds[i]);
            if (!q.exec()) {
                qCWarning(logDb) << "Failed to restore favorite:" << q.lastError().text();
                m_db.rollback();
                return false;
            }
        }
    }

    return m_db.commit();
}

QList<ChannelInfo> DatabaseManager::getChannels(int playlistId)
{
    QList<ChannelInfo> result;

    const QList<int> favIdsList = getFavoriteIds();
    const QSet<int> favIds(favIdsList.begin(), favIdsList.end());

    QSqlQuery q(m_db);
    q.prepare("SELECT c.*, CASE WHEN f.id IS NOT NULL THEN 1 ELSE 0 END AS is_fav "
              "FROM channels c LEFT JOIN favorites f ON c.id = f.channel_id "
              "WHERE c.playlist_id = :id ORDER BY c.name");
    q.bindValue(":id", playlistId);

    if (!q.exec()) {
        qCWarning(logDb) << "getChannels failed:" << q.lastError().text();
        return result;
    }

    while (q.next()) {
        ChannelInfo ch;
        ch.id = q.value("id").toInt();
        ch.playlistId = q.value("playlist_id").toInt();
        ch.name = q.value("name").toString();
        ch.url = q.value("url").toString();
        ch.logo = q.value("logo").toString();
        ch.group = q.value("group_name").toString();
        ch.channelId = q.value("channel_id").toString();
        ch.streamType = q.value("stream_type").toString();
        ch.isFavorite = favIds.contains(ch.id);
        result.append(ch);
    }

    qCDebug(logDb) << "getChannels: playlist" << playlistId << "->" << result.size() << "channels";
    return result;
}

QList<ChannelInfo> DatabaseManager::searchChannels(const QString &query)
{
    QList<ChannelInfo> result;

    QList<int> favIdsList = getFavoriteIds();
    QSet<int> favIds(favIdsList.begin(), favIdsList.end());

    QSqlQuery q(m_db);
    q.prepare("SELECT c.*, CASE WHEN f.id IS NOT NULL THEN 1 ELSE 0 END AS is_fav "
              "FROM channels c LEFT JOIN favorites f ON c.id = f.channel_id "
               "WHERE c.name LIKE :q ORDER BY c.name");
    q.bindValue(":q", "%" + query + "%");

    if (!q.exec()) {
        qCWarning(logDb) << "Failed to search channels:" << q.lastError().text();
        return result;
    }

    while (q.next()) {
        ChannelInfo ch;
        ch.id = q.value("id").toInt();
        ch.playlistId = q.value("playlist_id").toInt();
        ch.name = q.value("name").toString();
        ch.url = q.value("url").toString();
        ch.logo = q.value("logo").toString();
        ch.group = q.value("group_name").toString();
        ch.channelId = q.value("channel_id").toString();
        ch.streamType = q.value("stream_type").toString();
        ch.isFavorite = favIds.contains(ch.id);
        result.append(ch);
    }

    return result;
}

ChannelInfo DatabaseManager::getChannel(int id)
{
    ChannelInfo ch;
    QSqlQuery q(m_db);
    q.prepare("SELECT c.*, CASE WHEN f.id IS NOT NULL THEN 1 ELSE 0 END AS is_fav "
              "FROM channels c LEFT JOIN favorites f ON c.id = f.channel_id "
              "WHERE c.id = :id");
    q.bindValue(":id", id);

    if (!q.exec() || !q.next())
        return ch;

    ch.id = q.value("id").toInt();
    ch.playlistId = q.value("playlist_id").toInt();
    ch.name = q.value("name").toString();
    ch.url = q.value("url").toString();
    ch.logo = q.value("logo").toString();
    ch.group = q.value("group_name").toString();
    ch.channelId = q.value("channel_id").toString();
    ch.streamType = q.value("stream_type").toString();
    ch.isFavorite = q.value("is_fav").toInt() == 1;
    return ch;
}

int DatabaseManager::channelCount(int playlistId)
{
    QSqlQuery q(m_db);
    q.prepare("SELECT COUNT(*) FROM channels WHERE playlist_id = :id");
    q.bindValue(":id", playlistId);
    if (q.exec() && q.next())
        return q.value(0).toInt();
    return 0;
}

// -- Playlist synchronization --

static QString syncKey(int playlistId)
{
    return QStringLiteral("playlist_%1_last_sync").arg(playlistId);
}

void DatabaseManager::markPlaylistSynced(int playlistId)
{
    setSetting(syncKey(playlistId), QDateTime::currentDateTimeUtc().toString(Qt::ISODate));
}

QString DatabaseManager::lastSync(int playlistId)
{
    return getSetting(syncKey(playlistId));
}

// A playlist must be re-downloaded when it has no channel in the database
// or when its last synchronization is older than maxAgeHours.
bool DatabaseManager::needsRefresh(int playlistId, int maxAgeHours)
{
    if (channelCount(playlistId) == 0)
        return true;

    const QDateTime synced = QDateTime::fromString(lastSync(playlistId), Qt::ISODate);
    if (!synced.isValid())
        return true;

    return synced.secsTo(QDateTime::currentDateTimeUtc()) > qint64(maxAgeHours) * 3600;
}

bool DatabaseManager::addFavorite(int channelId)
{
    QSqlQuery q(m_db);
    q.prepare("INSERT OR IGNORE INTO favorites (channel_id) VALUES (:id)");
    q.bindValue(":id", channelId);
    bool ok = q.exec();
    if (ok)
        emit favoritesChanged();
    return ok;
}

bool DatabaseManager::removeFavorite(int channelId)
{
    QSqlQuery q(m_db);
    q.prepare("DELETE FROM favorites WHERE channel_id = :id");
    q.bindValue(":id", channelId);
    bool ok = q.exec();
    if (ok)
        emit favoritesChanged();
    return ok;
}

bool DatabaseManager::isFavorite(int channelId)
{
    QSqlQuery q(m_db);
    q.prepare("SELECT COUNT(*) FROM favorites WHERE channel_id = :id");
    q.bindValue(":id", channelId);
    if (q.exec() && q.next())
        return q.value(0).toInt() > 0;
    return false;
}

QList<ChannelInfo> DatabaseManager::getFavorites()
{
    QList<ChannelInfo> result;
    QSqlQuery q(m_db);
    q.prepare("SELECT c.*, 1 AS is_fav "
              "FROM channels c INNER JOIN favorites f ON c.id = f.channel_id "
              "ORDER BY f.created_at DESC");

    if (!q.exec()) {
        qCWarning(logDb) << "Failed to get favorites:" << q.lastError().text();
        return result;
    }

    while (q.next()) {
        ChannelInfo ch;
        ch.id = q.value("id").toInt();
        ch.playlistId = q.value("playlist_id").toInt();
        ch.name = q.value("name").toString();
        ch.url = q.value("url").toString();
        ch.logo = q.value("logo").toString();
        ch.group = q.value("group_name").toString();
        ch.channelId = q.value("channel_id").toString();
        ch.streamType = q.value("stream_type").toString();
        ch.isFavorite = true;
        result.append(ch);
    }

    return result;
}

QVariantList DatabaseManager::getFavoritesVariant()
{
    QVariantList result;
    auto channels = getFavorites();
    for (const auto &ch : channels) {
        result.append(QVariantMap{
            {"id", ch.id},
            {"playlistId", ch.playlistId},
            {"name", ch.name},
            {"url", ch.url},
            {"logo", ch.logo},
            {"group", ch.group},
            {"channelId", ch.channelId},
            {"streamType", ch.streamType}
        });
    }
    return result;
}

QList<int> DatabaseManager::getFavoriteIds()
{
    QList<int> result;
    QSqlQuery q(m_db);

    if (!q.exec("SELECT channel_id FROM favorites")) {
        qCWarning(logDb) << "getFavoriteIds failed:" << q.lastError().text();
        return result;
    }

    while (q.next())
        result.append(q.value(0).toInt());

    return result;
}

void DatabaseManager::setCache(const QString &key, const QString &data)
{
    QSqlQuery q(m_db);
    q.prepare(R"(INSERT OR REPLACE INTO cache (key, data, created_at)
                  VALUES (:key, :data, CURRENT_TIMESTAMP))");
    q.bindValue(":key", key);
    q.bindValue(":data", data);
    if (!q.exec())
        qCWarning(logDb) << "Failed to set cache:" << q.lastError().text();
}

QString DatabaseManager::getCache(const QString &key)
{
    QSqlQuery q(m_db);
    q.prepare("SELECT data FROM cache WHERE key = :key");
    q.bindValue(":key", key);
    if (q.exec() && q.next())
        return q.value("data").toString();
    return {};
}

void DatabaseManager::clearCache(int olderThanDays)
{
    QSqlQuery q(m_db);
    q.prepare("DELETE FROM cache WHERE created_at < datetime('now', :days)");
    q.bindValue(":days", QString("-%1 days").arg(olderThanDays));
    q.exec();
}

// -- Settings --

void DatabaseManager::setSetting(const QString &key, const QString &value)
{
    QSqlQuery q(m_db);
    q.prepare("INSERT OR REPLACE INTO settings (key, value) VALUES (:key, :value)");
    q.bindValue(":key", key);
    q.bindValue(":value", value);
    if (!q.exec())
        qCWarning(logDb) << "Failed to set setting" << key << ":" << q.lastError().text();
}

QString DatabaseManager::getSetting(const QString &key, const QString &defaultValue)
{
    QSqlQuery q(m_db);
    q.prepare("SELECT value FROM settings WHERE key = :key");
    q.bindValue(":key", key);
    if (q.exec() && q.next())
        return q.value(0).toString();
    return defaultValue;
}

// User settings used to live in the `cache` table, which clearCache() purges.
// One-time migration to `settings` for existing databases.
void DatabaseManager::migrateSettingsFromCache()
{
    static const QStringList keys = {QStringLiteral("custom_suffixes")};

    for (const QString &key : keys) {
        QSqlQuery q(m_db);
        q.prepare("SELECT data FROM cache WHERE key = :key");
        q.bindValue(":key", key);
        if (!q.exec() || !q.next())
            continue;

        const QString value = q.value(0).toString();
        if (!value.isEmpty() && getSetting(key).isEmpty()) {
            qCInfo(logDb) << "Migrating setting" << key << "from cache to settings";
            setSetting(key, value);
        }

        q.prepare("DELETE FROM cache WHERE key = :key");
        q.bindValue(":key", key);
        q.exec();
    }
}

// -- Watch History --

void DatabaseManager::addHistoryEntry(const QString &name, const QString &url,
                                      const QString &logo, const QString &group)
{
    QSqlQuery q(m_db);
    q.prepare(R"(
        INSERT OR REPLACE INTO watch_history (name, url, logo, group_name, watched_at)
        VALUES (:name, :url, :logo, :group_name, CURRENT_TIMESTAMP)
    )");
    q.bindValue(":name", name);
    q.bindValue(":url", url);
    q.bindValue(":logo", logo);
    q.bindValue(":group_name", group);
    if (!q.exec()) {
        qCWarning(logDb) << "Failed to add history entry:" << q.lastError().text();
        return;
    }

    // History is never purged otherwise: keep the last 500 entries.
    q.exec("DELETE FROM watch_history WHERE id NOT IN ("
           "SELECT id FROM watch_history ORDER BY watched_at DESC LIMIT 500)");

    emit historyChanged();
}

QVariantList DatabaseManager::getHistoryVariant(int limit)
{
    QVariantList result;
    QSqlQuery q(m_db);
    q.prepare("SELECT id, name, url, logo, group_name FROM watch_history "
              "ORDER BY watched_at DESC LIMIT :limit");
    q.bindValue(":limit", limit);

    if (!q.exec()) {
        qCWarning(logDb) << "Failed to get history:" << q.lastError().text();
        return result;
    }

    while (q.next()) {
        result.append(QVariantMap{
            {"id", q.value("id").toInt()},
            {"name", q.value("name").toString()},
            {"url", q.value("url").toString()},
            {"logo", q.value("logo").toString()},
            {"group", q.value("group_name").toString()},
        });
    }
    return result;
}

void DatabaseManager::clearHistory()
{
    QSqlQuery q(m_db);
    if (!q.exec("DELETE FROM watch_history"))
        qCWarning(logDb) << "Failed to clear history:" << q.lastError().text();
    else
        emit historyChanged();
}

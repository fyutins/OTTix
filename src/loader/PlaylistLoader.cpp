#include "PlaylistLoader.h"
#include "../utils/Logging.h"
#include "../utils/LogUtils.h"
#include <QUrl>
#include <QDebug>
#include <QtConcurrent/QtConcurrentRun>

PlaylistLoader::PlaylistLoader(QObject *parent)
    : QObject(parent)
    , m_nam(new QNetworkAccessManager(this))
    , m_m3uParser(new M3UParser(this))
    , m_xtreamApi(new XtreamApi(this))
{
    connect(m_xtreamApi, &XtreamApi::authResult,
            this, &PlaylistLoader::onXtreamAuthResult);
    connect(m_xtreamApi, &XtreamApi::liveCategoriesLoaded,
            this, &PlaylistLoader::onXtreamCategoriesLoaded);
    connect(m_xtreamApi, &XtreamApi::liveStreamsLoaded,
            this, &PlaylistLoader::onXtreamStreamsLoaded);
    connect(m_xtreamApi, &XtreamApi::apiError,
            this, [this](const QString &error) {
        emit loadError(m_currentPlaylistId, error);
    });
}

void PlaylistLoader::loadM3U(int playlistId, const QString &url)
{
    cancel();
    m_currentPlaylistId = playlistId;
    m_currentType = "m3u";

    emit loadStarted(playlistId);

    QNetworkRequest request{QUrl(url)};
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute,
                         QNetworkRequest::NoLessSafeRedirectPolicy);
    request.setHeader(QNetworkRequest::UserAgentHeader, "OTTix/1.0");

    m_currentReply = m_nam->get(request);
    connect(m_currentReply, &QNetworkReply::finished,
            this, &PlaylistLoader::onM3UDownloaded);
}

void PlaylistLoader::loadXtream(int playlistId, const QString &url,
                                 const QString &username, const QString &password)
{
    cancel();
    m_currentPlaylistId = playlistId;
    m_currentType = "xtream";

    emit loadStarted(playlistId);

    m_xtreamApi->setCredentials(url, username, password);
    m_xtreamApi->authenticate();
}

void PlaylistLoader::cancel()
{
    if (m_parseWatcher) {
        m_parseWatcher->disconnect(this);
        m_parseWatcher = nullptr;
    }
    if (m_currentReply) {
        m_currentReply->disconnect();
        m_currentReply->abort();
        m_currentReply->deleteLater();
        m_currentReply = nullptr;
    }
    m_xtreamCategories.clear();
    m_xtreamChannels.clear();
    m_currentPlaylistId = -1;
}

void PlaylistLoader::onM3UDownloaded()
{
    auto reply = m_currentReply;
    m_currentReply = nullptr;

    if (!reply) {
        emit loadError(m_currentPlaylistId, "Network error: request vanished");
        return;
    }

    if (reply->error() != QNetworkReply::NoError) {
        emit loadError(m_currentPlaylistId, "Network error: " + reply->errorString());
        reply->deleteLater();
        return;
    }

    QByteArray data = reply->readAll();
    reply->deleteLater();

    // Parsing a large playlist (100k+ lines) would block the GUI thread: run it
    // off-thread, then come back to the main thread for the database write
    // (QSqlDatabase is not shareable between threads).
    const int playlistId = m_currentPlaylistId;
    auto *watcher = new QFutureWatcher<QList<ChannelInfo>>(this);
    m_parseWatcher = watcher;

    connect(watcher, &QFutureWatcher<QList<ChannelInfo>>::finished, this,
            [this, watcher, playlistId]() {
        watcher->deleteLater();
        if (m_parseWatcher == watcher)
            m_parseWatcher = nullptr;

        const QList<ChannelInfo> channels = watcher->result();
        if (channels.isEmpty()) {
            emit loadError(playlistId, "No channels found in playlist");
            return;
        }

        emit loadProgress(playlistId, channels.size(), channels.size());
        storeChannels(playlistId, channels);
    });

    watcher->setFuture(QtConcurrent::run([data]() {
        return M3UParser::parseBuffer(data);
    }));
}

void PlaylistLoader::onXtreamAuthResult(bool success, const QString &message, const QJsonObject &userInfo)
{
    Q_UNUSED(message)
    Q_UNUSED(userInfo)

    if (!success) {
        emit loadError(m_currentPlaylistId, "XTREAM auth failed: " + message);
        return;
    }

    qCDebug(logLoader) << "XTREAM auth success, loading live categories...";
    m_xtreamChannels.clear();
    m_xtreamApi->getLiveCategories();
}

void PlaylistLoader::onXtreamCategoriesLoaded(const QList<XtreamCategory> &categories)
{
    qCDebug(logLoader) << "Loaded" << categories.size() << "live categories";
    for (int i = 0; i < qMin(5, categories.size()); i++)
        qCDebug(logLoader) << "  Category" << i << "| id:" << categories[i].categoryId << "| name:" << categories[i].name;
    m_xtreamCategories = categories;
    m_xtreamApi->getLiveStreams();
}

void PlaylistLoader::onXtreamStreamsLoaded(const QList<XtreamChannel> &channels)
{
    qCDebug(logLoader) << "[LOADER] Received" << channels.size() << "live streams";

    m_xtreamChannels.reserve(channels.size());
    int mappedGroup = 0;
    for (const auto &ch : channels) {
        ChannelInfo ci;
        ci.name = ch.name;
        ci.url = ch.streamUrl;
        ci.logo = ch.logo;

        // Map category_id to category name from cached categories
        ci.group = ch.group;
        if (ci.group.isEmpty() && !ch.categoryId.isEmpty()) {
            for (const auto &cat : m_xtreamCategories) {
                if (cat.categoryId == ch.categoryId) {
                    ci.group = cat.name;
                    mappedGroup++;
                    break;
                }
            }
        }

        ci.channelId = ch.id;
        ci.streamType = "live";
        m_xtreamChannels.append(ci);
    }

    qCDebug(logLoader) << "[LOADER] Mapped" << mappedGroup << "groups from category_id";
    qCDebug(logLoader) << "[LOADER] Total channels with group:"
             << std::count_if(m_xtreamChannels.begin(), m_xtreamChannels.end(),
                              [](const ChannelInfo &c) { return !c.group.isEmpty(); });

    emit loadProgress(m_currentPlaylistId, 1, 1);
    storeChannels(m_currentPlaylistId, m_xtreamChannels);
}

void PlaylistLoader::storeChannels(int playlistId, const QList<ChannelInfo> &channels)
{
    qCDebug(logLoader) << "[LOADER] storeChannels: playlistId=" << playlistId << "| input count=" << channels.size();

    // Assign playlist ID and filter out channels with empty names
    QList<ChannelInfo> finalChannels;
    finalChannels.reserve(channels.size());
    int skipped = 0;
    for (auto ch : channels) {
        ch.playlistId = playlistId;
        if (ch.name.isEmpty()) {
            qCWarning(logLoader) << "[LOADER] Skipping channel with empty name, url:"
                       << LogUtils::scrubUrl(ch.url);
            skipped++;
            continue;
        }
        finalChannels.append(ch);
    }

    qCDebug(logLoader) << "[LOADER] Storing" << finalChannels.size() << "channels for playlist" << playlistId
             << "(filtered from" << channels.size() << ", skipped=" << skipped << ")";

    // Atomically replace channels (delete old + insert new in one transaction)
    bool ok = DatabaseManager::instance().replaceChannels(playlistId, finalChannels);
    if (!ok) {
        qCWarning(logLoader) << "[LOADER] replaceChannels failed, emitting loadError";
        emit loadError(playlistId, "Failed to store channels in database");
        return;
    }

    DatabaseManager::instance().markPlaylistSynced(playlistId);

    int count = DatabaseManager::instance().channelCount(playlistId);
    qCDebug(logLoader) << "[LOADER] Playlist" << playlistId << "loaded with" << count << "channels";

    finalChannels.clear(); // free memory before emitting signal
    m_xtreamChannels.clear();

    emit loadComplete(playlistId, count);
}

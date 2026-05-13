#include "PlaylistLoader.h"
#include <QUrl>
#include <QDir>
#include <QFile>
#include <QDebug>

PlaylistLoader::PlaylistLoader(QObject *parent)
    : QObject(parent)
    , m_nam(new QNetworkAccessManager(this))
    , m_m3uParser(new M3UParser(this))
    , m_xtreamApi(new XtreamApi(this))
{
    connect(m_m3uParser, &M3UParser::parseProgress,
            this, [this](int current, int total) {
        emit loadProgress(m_currentPlaylistId, current, total);
    });

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
    request.setHeader(QNetworkRequest::UserAgentHeader, "IptvPlayer/1.0");

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
    if (m_currentReply) {
        m_currentReply->disconnect();
        m_currentReply->abort();
        m_currentReply->deleteLater();
        m_currentReply = nullptr;
    }
    m_xtreamCategories.clear();
    m_xtreamCategoryIndex = 0;
    m_xtreamChannels.clear();
    m_currentPlaylistId = -1;
}

void PlaylistLoader::onM3UDownloaded()
{
    auto reply = m_currentReply;
    m_currentReply = nullptr;

    if (!reply || reply->error() != QNetworkReply::NoError) {
        QString err = reply ? reply->errorString() : "Unknown error";
        emit loadError(m_currentPlaylistId, "Network error: " + err);
        reply->deleteLater();
        return;
    }

    QByteArray data = reply->readAll();
    reply->deleteLater();

    // Save raw data to a temp file and parse with M3UParser
    QString tmpPath = QDir::temp().filePath("iptv_m3u_" + QString::number(m_currentPlaylistId) + ".m3u");
    QFile tmpFile(tmpPath);
    if (!tmpFile.open(QIODevice::WriteOnly)) {
        emit loadError(m_currentPlaylistId, "Cannot write temp file");
        return;
    }
    tmpFile.write(data);
    tmpFile.close();

    QList<ChannelInfo> channels = m_m3uParser->parse(tmpPath);
    QFile::remove(tmpPath);

    if (channels.isEmpty()) {
        emit loadError(m_currentPlaylistId, "No channels found in playlist");
        return;
    }

    storeChannels(m_currentPlaylistId, channels);
}

void PlaylistLoader::onXtreamAuthResult(bool success, const QString &message, const QJsonObject &userInfo)
{
    Q_UNUSED(message)
    Q_UNUSED(userInfo)

    if (!success) {
        emit loadError(m_currentPlaylistId, "XTREAM auth failed: " + message);
        return;
    }

    m_xtreamCategoryIndex = 0;
    m_xtreamChannels.clear();
    m_xtreamApi->getLiveCategories();
}

void PlaylistLoader::onXtreamCategoriesLoaded(const QList<XtreamCategory> &categories)
{
    m_xtreamCategories = categories;

    if (categories.isEmpty()) {
        // No categories - fetch all streams directly
        m_xtreamApi->getLiveStreams();
        return;
    }

    m_xtreamCategoryIndex = 0;
    fetchAllXtreamStreams(m_currentPlaylistId, 0);
}

void PlaylistLoader::onXtreamStreamsLoaded(const QList<XtreamChannel> &channels)
{
    for (const auto &ch : channels) {
        ChannelInfo ci;
        ci.name = ch.name;
        ci.url = ch.streamUrl;
        ci.logo = ch.logo;
        ci.group = ch.group;
        ci.channelId = ch.id;
        ci.streamType = "live";
        m_xtreamChannels.append(ci);
    }

    m_xtreamCategoryIndex++;
    if (m_xtreamCategoryIndex < m_xtreamCategories.size()) {
        emit loadProgress(m_currentPlaylistId, m_xtreamCategoryIndex, m_xtreamCategories.size());
        fetchAllXtreamStreams(m_currentPlaylistId, m_xtreamCategoryIndex);
    } else {
        emit loadProgress(m_currentPlaylistId, m_xtreamCategories.size(), m_xtreamCategories.size());
        storeChannels(m_currentPlaylistId, m_xtreamChannels);
    }
}

void PlaylistLoader::fetchAllXtreamStreams(int playlistId, int categoryIndex)
{
    Q_UNUSED(playlistId)
    QString catId = m_xtreamCategories[categoryIndex].categoryId;
    m_xtreamApi->getLiveStreams(catId);
}

void PlaylistLoader::storeChannels(int playlistId, const QList<ChannelInfo> &channels)
{
    // Assign playlist ID
    QList<ChannelInfo> finalChannels = channels;
    for (auto &ch : finalChannels)
        ch.playlistId = playlistId;

    // Remove old channels for this playlist and add new ones
    DatabaseManager::instance().removeChannelsByPlaylist(playlistId);
    bool ok = DatabaseManager::instance().addChannels(finalChannels);

    if (!ok) {
        emit loadError(playlistId, "Failed to store channels in database");
        return;
    }

    int count = DatabaseManager::instance().channelCount(playlistId);
    emit loadComplete(playlistId, count);
}

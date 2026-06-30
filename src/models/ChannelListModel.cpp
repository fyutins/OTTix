#include "ChannelListModel.h"
#include "../utils/ChannelGrouper.h"

ChannelListModel::ChannelListModel(QObject *parent)
    : QAbstractListModel(parent)
{
    QString customData = DatabaseManager::instance().getCache("custom_suffixes");
    if (!customData.isEmpty())
        m_customSuffixes = customData.split(",", Qt::SkipEmptyParts);
}

int ChannelListModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return m_filtered.size();
}

QVariant ChannelListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_filtered.size())
        return {};

    const auto &ch = m_filtered[index.row()];

    switch (role) {
    case IdRole: return ch.id;
    case NameRole: return ch.name;
    case UrlRole: return ch.url;
    case LogoRole: return ch.logo;
    case GroupRole: return ch.group;
    case PlaylistIdRole: return ch.playlistId;
    case IsFavoriteRole: return ch.isFavorite;
    case ChannelIdRole: return ch.channelId;
    default: return {};
    }
}

QHash<int, QByteArray> ChannelListModel::roleNames() const
{
    return {
        {IdRole, "channelId"},
        {NameRole, "name"},
        {UrlRole, "url"},
        {LogoRole, "logo"},
        {GroupRole, "groupName"},
        {PlaylistIdRole, "playlistId"},
        {IsFavoriteRole, "isFavorite"},
        {ChannelIdRole, "xtreamId"}
    };
}

QVariantMap ChannelListModel::get(int index) const
{
    QVariantMap map;
    if (index < 0 || index >= m_filtered.size())
        return map;

    const auto &ch = m_filtered[index];
    map["id"] = ch.id;
    map["name"] = ch.name;
    map["url"] = ch.url;
    map["logo"] = ch.logo;
    map["group"] = ch.group;
    map["playlistId"] = ch.playlistId;
    map["isFavorite"] = ch.isFavorite;
    map["channelId"] = ch.channelId;
    return map;
}

void ChannelListModel::refresh()
{
    applyFilter();
}

void ChannelListModel::setChannels(int playlistId)
{
    qDebug() << "[MODEL] setChannels(playlistId=" << playlistId << ")";
    qDebug() << "[MODEL] Calling DatabaseManager::getChannels...";
    auto channels = DatabaseManager::instance().getChannels(playlistId);
    qDebug() << "[MODEL] DatabaseManager::getChannels returned" << channels.size() << "channels";
    setChannels(channels);
}

void ChannelListModel::setChannels(const QList<ChannelInfo> &channels)
{
    qDebug() << "[MODEL] setChannels(const) — channels.size=" << channels.size();

    m_channels = channels;
    qDebug() << "[MODEL] m_channels assigned, size=" << m_channels.size()
             << "capacity=" << m_channels.capacity();

    rebuildGroups();

    qDebug() << "[MODEL] Building groups set...";
    QSet<QString> groupSet;
    for (const auto &ch : m_channels) {
        if (!ch.group.isEmpty())
            groupSet.insert(ch.group);
    }
    m_groups = groupSet.values();
    m_groups.sort();
    m_groups.prepend("");
    qDebug() << "[MODEL] Groups built:" << m_groups.size() << "unique groups (including empty)";

    emit groupsChanged();
    qDebug() << "[MODEL] groupsChanged emitted";

    qDebug() << "[MODEL] beginResetModel...";
    beginResetModel();
    m_filtered.clear();
    m_filtered.reserve(m_channels.size());
    int filteredCount = 0;
    for (const auto &ch : m_channels) {
        bool matchGroup = m_filterGroup.isEmpty() || ch.group == m_filterGroup;
        bool matchText = m_filterText.isEmpty();
        if (!matchText) {
            const QStringList tokens = m_filterText.split(' ', Qt::SkipEmptyParts);
            matchText = true;
            for (const auto &token : tokens)
                matchText &= ch.name.contains(token, Qt::CaseInsensitive);
        }
        if (matchGroup && matchText) {
            m_filtered.append(ch);
            filteredCount++;
        }
    }
    qDebug() << "[MODEL] Filtered:" << filteredCount << "out of" << m_channels.size();
    qDebug() << "[MODEL] endResetModel...";
    endResetModel();
    emit countChanged();
    qDebug() << "[MODEL] countChanged emitted, rowCount=" << rowCount();
}

void ChannelListModel::setFavorites()
{
    auto favorites = DatabaseManager::instance().getFavorites();
    setChannels(favorites);
}

void ChannelListModel::toggleFavorite(int channelDbId)
{
    auto &db = DatabaseManager::instance();

    // Find in filtered list
    int row = -1;
    for (int i = 0; i < m_filtered.size(); ++i) {
        if (m_filtered[i].id == channelDbId) {
            row = i;
            break;
        }
    }
    if (row < 0)
        return;

    ChannelInfo &ch = m_filtered[row];
    if (ch.isFavorite) {
        db.removeFavorite(channelDbId);
        ch.isFavorite = false;
    } else {
        db.addFavorite(channelDbId);
        ch.isFavorite = true;
    }

    // Sync with m_channels
    for (auto &c : m_channels) {
        if (c.id == channelDbId) {
            c.isFavorite = ch.isFavorite;
            break;
        }
    }

    QModelIndex idx = index(row, 0);
    emit dataChanged(idx, idx, {IsFavoriteRole});
}

void ChannelListModel::setFilterGroup(const QString &group)
{
    if (m_filterGroup == group)
        return;
    m_filterGroup = group;
    emit filterChanged();
    applyFilter();
}

void ChannelListModel::setFilterText(const QString &text)
{
    if (m_filterText == text)
        return;
    m_filterText = text;
    emit filterChanged();
    applyFilter();
}

void ChannelListModel::applyFilter()
{
    beginResetModel();
    m_filtered.clear();

    for (const auto &ch : m_channels) {
        bool matchGroup = m_filterGroup.isEmpty() || ch.group == m_filterGroup;
        bool matchText = m_filterText.isEmpty();
        if (!matchText) {
            const QStringList tokens = m_filterText.split(' ', Qt::SkipEmptyParts);
            matchText = true;
            for (const auto &token : tokens)
                matchText &= ch.name.contains(token, Qt::CaseInsensitive);
        }

        if (matchGroup && matchText)
            m_filtered.append(ch);
    }

    endResetModel();
    emit countChanged();
}

// ── Variant grouping ──

void ChannelListModel::rebuildGroups()
{
    m_baseNameToChannels.clear();
    m_channelBaseName.clear();
    m_channelVariantLabel.clear();
    m_multiVariantBaseNames.clear();

    for (int i = 0; i < m_channels.size(); ++i) {
        const auto &ch = m_channels[i];
        auto info = ChannelGrouper::analyze(ch.name, m_customSuffixes);
        m_channelBaseName[i] = info.baseName;
        m_channelVariantLabel[i] = info.label;
        m_baseNameToChannels[info.baseName].append(i);
    }

    for (auto it = m_baseNameToChannels.begin(); it != m_baseNameToChannels.end(); ++it) {
        if (it.value().size() >= 2)
            m_multiVariantBaseNames.insert(it.key());
    }
}

QVariantList ChannelListModel::getVariantsForUrl(const QString &url) const
{
    int channelIdx = -1;
    for (int i = 0; i < m_channels.size(); ++i) {
        if (m_channels[i].url == url) {
            channelIdx = i;
            break;
        }
    }
    if (channelIdx < 0)
        return {};

    QString baseName = m_channelBaseName.value(channelIdx);
    if (baseName.isEmpty() || !m_multiVariantBaseNames.contains(baseName))
        return {};

    QVariantList variants;
    const auto &indices = m_baseNameToChannels[baseName];
    for (int idx : indices) {
        const auto &ch = m_channels[idx];
        QVariantMap vm;
        vm["id"] = ch.id;
        vm["name"] = ch.name;
        vm["url"] = ch.url;
        vm["logo"] = ch.logo;
        vm["group"] = ch.group;
        vm["label"] = m_channelVariantLabel.value(idx, "");
        variants.append(vm);
    }
    return variants;
}

QString ChannelListModel::getVariantLabelForUrl(const QString &url) const
{
    for (int i = 0; i < m_channels.size(); ++i) {
        if (m_channels[i].url == url)
            return m_channelVariantLabel.value(i, "");
    }
    return "";
}

bool ChannelListModel::channelHasVariants(const QString &url) const
{
    for (int i = 0; i < m_channels.size(); ++i) {
        if (m_channels[i].url == url) {
            QString baseName = m_channelBaseName.value(i);
            return !baseName.isEmpty() && m_multiVariantBaseNames.contains(baseName);
        }
    }
    return false;
}

void ChannelListModel::setCustomSuffixes(const QStringList &suffixes)
{
    if (m_customSuffixes == suffixes)
        return;
    m_customSuffixes = suffixes;
    DatabaseManager::instance().setCache("custom_suffixes", suffixes.join(","));
    rebuildGroups();
    emit customSuffixesChanged();
}

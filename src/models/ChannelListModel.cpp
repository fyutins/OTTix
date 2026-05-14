#include "ChannelListModel.h"

ChannelListModel::ChannelListModel(QObject *parent)
    : QAbstractListModel(parent)
{
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
    auto channels = DatabaseManager::instance().getChannels(playlistId);
    setChannels(channels);
}

void ChannelListModel::setChannels(const QList<ChannelInfo> &channels)
{
    m_channels = channels;

    QSet<QString> groupSet;
    for (const auto &ch : m_channels) {
        if (!ch.group.isEmpty())
            groupSet.insert(ch.group);
    }
    m_groups = groupSet.values();
    m_groups.sort();
    m_groups.prepend("");

    emit groupsChanged();

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

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
        bool matchText = m_filterText.isEmpty() ||
                         ch.name.contains(m_filterText, Qt::CaseInsensitive);
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
        bool matchText = m_filterText.isEmpty() ||
                         ch.name.contains(m_filterText, Qt::CaseInsensitive);

        if (matchGroup && matchText)
            m_filtered.append(ch);
    }

    endResetModel();
    emit countChanged();
}

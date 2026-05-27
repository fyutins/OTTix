#include "PlaylistModel.h"

PlaylistModel::PlaylistModel(QObject *parent)
    : QAbstractListModel(parent)
{
    refresh();
}

int PlaylistModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return m_playlists.size();
}

QVariant PlaylistModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_playlists.size())
        return {};

    const auto &pl = m_playlists[index.row()];

    switch (role) {
    case IdRole: return pl.id;
    case NameRole: return pl.name;
    case UrlRole: return pl.url;
    case TypeRole: return pl.type;
    case UsernameRole: return pl.username;
    case PasswordRole: return pl.password;
    case ChannelCountRole: return pl.channelCount;
    default: return {};
    }
}

QHash<int, QByteArray> PlaylistModel::roleNames() const
{
    return {
        {IdRole, "playlistId"},
        {NameRole, "name"},
        {UrlRole, "url"},
        {TypeRole, "type"},
        {UsernameRole, "username"},
        {PasswordRole, "password"},
        {ChannelCountRole, "channelCount"}
    };
}

QVariantMap PlaylistModel::get(int index) const
{
    QVariantMap map;
    if (index < 0 || index >= m_playlists.size())
        return map;

    const auto &pl = m_playlists[index];
    map["id"] = pl.id;
    map["name"] = pl.name;
    map["url"] = pl.url;
    map["type"] = pl.type;
    map["username"] = pl.username;
    map["password"] = pl.password;
    map["channelCount"] = pl.channelCount;
    return map;
}

void PlaylistModel::refresh()
{
    beginResetModel();
    m_playlists = DatabaseManager::instance().getPlaylists();
    endResetModel();
    emit countChanged();
}

bool PlaylistModel::addPlaylist(const QString &name, const QString &url,
                                 const QString &type, const QString &username,
                                 const QString &password)
{
    PlaylistInfo pl;
    pl.name = name;
    pl.url = url;
    pl.type = type;
    pl.username = username;
    pl.password = password;

    int id = DatabaseManager::instance().addPlaylist(pl);
    if (id < 0)
        return false;

    refresh();
    return true;
}

bool PlaylistModel::updatePlaylist(int id, const QString &name, const QString &url,
                                    const QString &type, const QString &username,
                                    const QString &password)
{
    PlaylistInfo pl;
    pl.id = id;
    pl.name = name;
    pl.url = url;
    pl.type = type;
    pl.username = username;
    pl.password = password;

    bool ok = DatabaseManager::instance().updatePlaylist(pl);
    if (ok)
        refresh();
    return ok;
}

bool PlaylistModel::removePlaylist(int id)
{
    bool ok = DatabaseManager::instance().removePlaylist(id);
    if (ok)
        refresh();
    return ok;
}

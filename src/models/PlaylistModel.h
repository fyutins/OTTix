#pragma once

#include <QAbstractListModel>
#include "../database/DatabaseManager.h"

class PlaylistModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)

public:
    enum Roles {
        IdRole = Qt::UserRole + 1,
        NameRole,
        UrlRole,
        TypeRole,
        UsernameRole,
        PasswordRole,
        ChannelCountRole
    };

    explicit PlaylistModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE QVariantMap get(int index) const;
    Q_INVOKABLE void refresh();
    Q_INVOKABLE bool addPlaylist(const QString &name, const QString &url,
                                  const QString &type, const QString &username,
                                  const QString &password);
    Q_INVOKABLE bool updatePlaylist(int id, const QString &name, const QString &url,
                                     const QString &type, const QString &username,
                                     const QString &password);
    Q_INVOKABLE bool removePlaylist(int id);

signals:
    void countChanged();

private:
    QList<PlaylistInfo> m_playlists;
};

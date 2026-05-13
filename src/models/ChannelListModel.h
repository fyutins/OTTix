#pragma once

#include <QAbstractListModel>
#include <QStringList>
#include "../database/DatabaseManager.h"

class ChannelListModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)
    Q_PROPERTY(QString filterGroup READ filterGroup WRITE setFilterGroup NOTIFY filterChanged)
    Q_PROPERTY(QString filterText READ filterText WRITE setFilterText NOTIFY filterChanged)

public:
    enum Roles {
        IdRole = Qt::UserRole + 1,
        NameRole,
        UrlRole,
        LogoRole,
        GroupRole,
        PlaylistIdRole,
        IsFavoriteRole,
        ChannelIdRole
    };

    explicit ChannelListModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE QVariantMap get(int index) const;
    Q_INVOKABLE void refresh();
    Q_INVOKABLE void setChannels(int playlistId);
    Q_INVOKABLE void setFavorites();

    QStringList groups() const { return m_groups; }
    QString filterGroup() const { return m_filterGroup; }
    void setFilterGroup(const QString &group);
    QString filterText() const { return m_filterText; }
    void setFilterText(const QString &text);

    QList<ChannelInfo> channels() const { return m_channels; }

signals:
    void countChanged();
    void filterChanged();
    void groupsChanged();

private:
    void setChannels(const QList<ChannelInfo> &channels);
    void applyFilter();

    QList<ChannelInfo> m_channels;
    QList<ChannelInfo> m_filtered;
    QStringList m_groups;
    QString m_filterGroup;
    QString m_filterText;
};

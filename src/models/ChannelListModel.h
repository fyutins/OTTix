#pragma once

#include <QAbstractListModel>
#include <QtQml/qqmlregistration.h>
#include <QStringList>
#include <QHash>
#include <QMap>
#include <QSet>
#include "../database/DatabaseManager.h"

class ChannelListModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)
    Q_PROPERTY(QStringList groups READ groups NOTIFY groupsChanged)
    Q_PROPERTY(QString filterGroup READ filterGroup WRITE setFilterGroup NOTIFY filterChanged)
    Q_PROPERTY(QString filterText READ filterText WRITE setFilterText NOTIFY filterChanged)
    Q_PROPERTY(QStringList qualitySuffixes READ qualitySuffixes WRITE setQualitySuffixes NOTIFY qualitySuffixesChanged)

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

    // Text filter shared by the model and the lists built in QML (favorites,
    // groups): a single multi-token search semantics.
    Q_INVOKABLE bool matchesFilter(const QString &name, const QString &filter) const;

    Q_INVOKABLE QVariantMap get(int index) const;

    // Next (direction > 0) or previous channel in the filtered list, wrapping
    // around. Empty map when the list is empty.
    Q_INVOKABLE QVariantMap channelAfter(const QString &url, int direction) const;
    Q_INVOKABLE void refresh();
    Q_INVOKABLE void setChannels(int playlistId);
    Q_INVOKABLE void setFavorites();
    Q_INVOKABLE void toggleFavorite(int channelDbId);

    Q_INVOKABLE QVariantList getVariantsForUrl(const QString &url) const;
    Q_INVOKABLE bool channelHasVariants(const QString &url) const;
    Q_INVOKABLE QString getVariantLabelForUrl(const QString &url) const;

    QStringList groups() const { return m_groups; }
    QString filterGroup() const { return m_filterGroup; }
    void setFilterGroup(const QString &group);
    QString filterText() const { return m_filterText; }
    void setFilterText(const QString &text);

    QStringList qualitySuffixes() const { return m_qualitySuffixes; }
    void setQualitySuffixes(const QStringList &suffixes);
    Q_INVOKABLE QStringList defaultQualitySuffixes() const;
    Q_INVOKABLE void resetQualitySuffixes();

    QList<ChannelInfo> channels() const { return m_channels; }

    struct GroupingResult {
        QMap<QString, QList<int>> baseNameToChannels;
        QMap<int, QString> channelBaseName;
        QMap<int, QString> channelVariantLabel;
        QSet<QString> multiVariantBaseNames;
        QStringList groups;
    };

signals:
    void countChanged();
    void filterChanged();
    void groupsChanged();
    void qualitySuffixesChanged();

private:
    void setChannels(const QList<ChannelInfo> &channels);
    void applyFilter();
    void rebuildGroups();
    void applyGrouping(const GroupingResult &result);

    QList<ChannelInfo> m_channels;
    QList<ChannelInfo> m_filtered;
    QHash<QString, int> m_urlToChannel;   // url -> index into m_channels
    QHash<QString, int> m_urlToFiltered;  // url -> index into m_filtered
    QStringList m_groups;
    QString m_filterGroup;
    QString m_filterText;
    QStringList m_qualitySuffixes;

    // Grouping data
    QMap<QString, QList<int>> m_baseNameToChannels;
    QMap<int, QString> m_channelBaseName;
    QMap<int, QString> m_channelVariantLabel;
    QSet<QString> m_multiVariantBaseNames;

    // Async loading
    int m_loadGeneration = 0;
};

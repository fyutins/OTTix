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
    Q_PROPERTY(QStringList customSuffixes READ customSuffixes WRITE setCustomSuffixes NOTIFY customSuffixesChanged)

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

    // Filtre texte partage par le modele et les listes construites en QML
    // (favoris, groupes) : une seule semantique de recherche multi-tokens.
    Q_INVOKABLE bool matchesFilter(const QString &name, const QString &filter) const;

    Q_INVOKABLE QVariantMap get(int index) const;

    // Chaine suivante (direction > 0) ou precedente dans la liste filtree,
    // avec bouclage. Map vide si la liste est vide.
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

    QStringList customSuffixes() const { return m_customSuffixes; }
    void setCustomSuffixes(const QStringList &suffixes);

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
    void customSuffixesChanged();

private:
    void setChannels(const QList<ChannelInfo> &channels);
    void applyFilter();
    void rebuildGroups();
    void applyGrouping(const GroupingResult &result);

    QList<ChannelInfo> m_channels;
    QList<ChannelInfo> m_filtered;
    QHash<QString, int> m_urlToChannel;   // url -> index dans m_channels
    QHash<QString, int> m_urlToFiltered;  // url -> index dans m_filtered
    QStringList m_groups;
    QString m_filterGroup;
    QString m_filterText;
    QStringList m_customSuffixes;

    // Grouping data
    QMap<QString, QList<int>> m_baseNameToChannels;
    QMap<int, QString> m_channelBaseName;
    QMap<int, QString> m_channelVariantLabel;
    QSet<QString> m_multiVariantBaseNames;

    // Async loading
    int m_loadGeneration = 0;
};

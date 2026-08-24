#include "ChannelListModel.h"
#include "../utils/Logging.h"
#include "../utils/ChannelGrouper.h"

#include <QtConcurrent/QtConcurrentRun>
#include <QFutureWatcher>
#include <QElapsedTimer>

ChannelListModel::ChannelListModel(QObject *parent)
    : QAbstractListModel(parent)
{
    // La liste complete des suffixes est editable par l'utilisateur. Au premier
    // demarrage on la seme avec les suffixes par defaut, en y reprenant les
    // suffixes personnalises de l'ancien reglage `custom_suffixes`.
    const QString stored = DatabaseManager::instance().getSetting("quality_suffixes");
    if (!stored.isEmpty()) {
        m_qualitySuffixes = ChannelGrouper::normalizeSuffixes(
            stored.split(",", Qt::SkipEmptyParts));
    } else {
        const QString legacy = DatabaseManager::instance().getSetting("custom_suffixes");
        m_qualitySuffixes = ChannelGrouper::combinedSuffixes(
            legacy.isEmpty() ? QStringList() : legacy.split(",", Qt::SkipEmptyParts));
        DatabaseManager::instance().setSetting("quality_suffixes", m_qualitySuffixes.join(","));
    }
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

bool ChannelListModel::matchesFilter(const QString &name, const QString &filter) const
{
    if (filter.isEmpty())
        return true;

    const QStringList tokens = filter.split(u' ', Qt::SkipEmptyParts);
    for (const QString &token : tokens) {
        if (!name.contains(token, Qt::CaseInsensitive))
            return false;
    }
    return true;
}

static QVariantMap channelToMap(const ChannelInfo &ch)
{
    return {
        {"id", ch.id},
        {"name", ch.name},
        {"url", ch.url},
        {"logo", ch.logo},
        {"group", ch.group},
        {"playlistId", ch.playlistId},
        {"isFavorite", ch.isFavorite},
        {"channelId", ch.channelId}
    };
}

QVariantMap ChannelListModel::get(int index) const
{
    if (index < 0 || index >= m_filtered.size())
        return {};
    return channelToMap(m_filtered[index]);
}

QVariantMap ChannelListModel::channelAfter(const QString &url, int direction) const
{
    const int count = m_filtered.size();
    if (count == 0 || direction == 0)
        return {};

    const int currentIdx = m_urlToFiltered.value(url, -1);
    const int targetIdx = currentIdx < 0
        ? (direction > 0 ? 0 : count - 1)
        : ((currentIdx + direction) % count + count) % count;

    return channelToMap(m_filtered[targetIdx]);
}

void ChannelListModel::refresh()
{
    applyFilter();
}

// ── Worker function (runs in background thread) ──

static ChannelListModel::GroupingResult buildGroupingResult(
    const QList<ChannelInfo> &channels,
    const QStringList &qualitySuffixes)
{
    QElapsedTimer timer;
    timer.start();

    ChannelListModel::GroupingResult result;

    auto pattern = ChannelGrouper::buildPatternFromList(qualitySuffixes);

    QSet<QString> groupSet;
    for (int i = 0; i < channels.size(); ++i) {
        const auto &ch = channels[i];
        if (!ch.group.isEmpty())
            groupSet.insert(ch.group);

        auto info = ChannelGrouper::analyzeWithPattern(ch.name, pattern);
        // Clef repliee : "TF1 HD" et "tf1 FHD" appartiennent au meme groupe.
        const QString key = info.baseName.toCaseFolded();
        result.channelBaseName[i] = key;
        result.channelVariantLabel[i] = info.label;
        result.baseNameToChannels[key].append(i);
    }

    for (auto it = result.baseNameToChannels.begin();
         it != result.baseNameToChannels.end(); ++it) {
        if (it.value().size() >= 2)
            result.multiVariantBaseNames.insert(it.key());
    }

    qCDebug(logPerf) << "[PERF] Grouping:" << timer.elapsed() << "ms for" << channels.size() << "channels"
             << "-" << result.multiVariantBaseNames.size() << "multi-variant groups";

    result.groups = groupSet.values();
    result.groups.sort();
    result.groups.prepend("");

    return result;
}

void ChannelListModel::setChannels(int playlistId)
{
    qCDebug(logModel) << "[MODEL] setChannels(playlistId=" << playlistId << ") — querying DB";
    QElapsedTimer dbTimer;
    dbTimer.start();
    auto channels = DatabaseManager::instance().getChannels(playlistId);
    qCDebug(logPerf) << "[PERF] DB query:" << dbTimer.elapsed() << "ms for" << channels.size() << "channels";
    qCDebug(logModel) << "[MODEL] DB returned" << channels.size() << "channels";
    setChannels(channels);
}

void ChannelListModel::setChannels(const QList<ChannelInfo> &channels)
{
    m_channels = channels;
    int gen = ++m_loadGeneration;

    m_urlToChannel.clear();
    m_urlToChannel.reserve(m_channels.size());
    for (int i = 0; i < m_channels.size(); ++i)
        m_urlToChannel.insert(m_channels[i].url, i);

    // Populate view immediately (filter doesn't depend on grouping)
    applyFilter();

    auto *watcher = new QFutureWatcher<GroupingResult>(this);
    connect(watcher, &QFutureWatcher<GroupingResult>::finished, this, [this, watcher, gen]() {
        QElapsedTimer applyTimer;
        applyTimer.start();

        GroupingResult result = watcher->result();
        watcher->deleteLater();

        if (gen != m_loadGeneration) {
            qCDebug(logModel) << "[MODEL] ignoring stale load (gen" << gen << "!= current" << m_loadGeneration << ")";
            return;
        }

        applyGrouping(result);
        qCDebug(logPerf) << "[PERF] Apply grouping to model:" << applyTimer.elapsed() << "ms";
    });

    QList<ChannelInfo> channelsCopy = m_channels;
    QStringList suffixesCopy = m_qualitySuffixes;

    watcher->setFuture(QtConcurrent::run([channelsCopy, suffixesCopy]() {
        return buildGroupingResult(channelsCopy, suffixesCopy);
    }));
}

void ChannelListModel::applyGrouping(const GroupingResult &result)
{
    m_baseNameToChannels = result.baseNameToChannels;
    m_channelBaseName = result.channelBaseName;
    m_channelVariantLabel = result.channelVariantLabel;
    m_multiVariantBaseNames = result.multiVariantBaseNames;
    m_groups = result.groups;

    emit groupsChanged();
}

void ChannelListModel::setFavorites()
{
    auto favorites = DatabaseManager::instance().getFavorites();
    setChannels(favorites);
}

void ChannelListModel::toggleFavorite(int channelDbId)
{
    auto &db = DatabaseManager::instance();

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
    m_urlToFiltered.clear();

    for (const auto &ch : m_channels) {
        const bool matchGroup = m_filterGroup.isEmpty() || ch.group == m_filterGroup;

        if (matchGroup && matchesFilter(ch.name, m_filterText)) {
            m_urlToFiltered.insert(ch.url, m_filtered.size());
            m_filtered.append(ch);
        }
    }

    endResetModel();
    emit countChanged();
}

// ── Variant grouping ──

void ChannelListModel::rebuildGroups()
{
    auto result = buildGroupingResult(m_channels, m_qualitySuffixes);
    applyGrouping(result);
}

QVariantList ChannelListModel::getVariantsForUrl(const QString &url) const
{
    const int channelIdx = m_urlToChannel.value(url, -1);
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
    const int idx = m_urlToChannel.value(url, -1);
    return idx < 0 ? QString() : m_channelVariantLabel.value(idx, QString());
}

bool ChannelListModel::channelHasVariants(const QString &url) const
{
    const int idx = m_urlToChannel.value(url, -1);
    if (idx < 0)
        return false;

    const QString baseName = m_channelBaseName.value(idx);
    return !baseName.isEmpty() && m_multiVariantBaseNames.contains(baseName);
}

void ChannelListModel::setQualitySuffixes(const QStringList &suffixes)
{
    const QStringList cleaned = ChannelGrouper::normalizeSuffixes(suffixes);
    if (m_qualitySuffixes == cleaned)
        return;
    m_qualitySuffixes = cleaned;
    DatabaseManager::instance().setSetting("quality_suffixes", cleaned.join(","));
    rebuildGroups();
    emit qualitySuffixesChanged();
}

QStringList ChannelListModel::defaultQualitySuffixes() const
{
    return ChannelGrouper::normalizeSuffixes(ChannelGrouper::defaultSuffixes());
}

void ChannelListModel::resetQualitySuffixes()
{
    setQualitySuffixes(ChannelGrouper::defaultSuffixes());
}

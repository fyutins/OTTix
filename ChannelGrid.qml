pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls

GridView {
    id: root

    property bool isFavoritesModel: false
    property bool isHistoryModel: false
    signal playRequested(string name, string url, string logo, string group)
    signal favoriteToggled(int dbId)

    // Les cellules s'elargissent pour occuper toute la largeur disponible :
    // pas de gouttiere residuelle a droite de la grille.
    readonly property int minCellWidth: 162

    cellWidth: root.width > root.minCellWidth
               ? Math.floor(root.width / Math.floor(root.width / root.minCellWidth))
               : root.minCellWidth
    cellHeight: 128
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    cacheBuffer: cellHeight * 4

    ScrollBar.vertical: AppScrollBar {}

    delegate: ChannelDelegate {
        // Injection explicite : les trois modeles branches ici (ChannelListModel,
        // favoris, historique) n'exposent pas les memes roles.
        required property var model

        width: root.cellWidth
        height: root.cellHeight
        channelName: model.name
        channelUrl: model.url
        channelLogo: model.logo
        channelGroup: root.isHistoryModel ? model.group : (root.isFavoritesModel ? model.group : model.groupName)
        channelDbId: root.isHistoryModel ? -1 : (root.isFavoritesModel ? model.id : model.channelId)
        isFavorite: root.isHistoryModel ? false : (root.isFavoritesModel ? true : model.isFavorite)
        showFavoriteIcon: !root.isHistoryModel
        onPlayRequested: (name, url, logo, group) => root.playRequested(name, url, logo, group)
        onFavoriteToggled: (id) => root.favoriteToggled(id)
    }

    EmptyState {
        anchors.centerIn: parent
        visible: root.count === 0
        glyph: root.isFavoritesModel ? Mdi.starOutline
             : root.isHistoryModel ? Mdi.history : Mdi.televisionOff
        title: root.isFavoritesModel ? qsTr("No favorites yet")
             : root.isHistoryModel ? qsTr("No history yet") : qsTr("No channels found")
        subtitle: root.isFavoritesModel ? qsTr("Star a channel to find it here")
                : root.isHistoryModel ? qsTr("Channels you watch appear here") : ""
    }
}

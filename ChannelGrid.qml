pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls

GridView {
    id: root
    cellWidth: 158
    cellHeight: 118
    clip: true
    ScrollBar.vertical: ScrollBar {}
    boundsBehavior: Flickable.StopAtBounds

    property bool isFavoritesModel: false
    property bool isHistoryModel: false
    signal playRequested(string name, string url, string logo, string group)
    signal favoriteToggled(int dbId)

    delegate: ChannelDelegate {
        // Injection explicite : les trois modeles branches ici (ChannelListModel,
        // favoris, historique) n'exposent pas les memes roles.
        required property var model

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

    Label {
        anchors.centerIn: parent
        text: root.isFavoritesModel ? qsTr("No favorites yet") : (root.isHistoryModel ? qsTr("No history yet") : qsTr("No channels found"))
        color: "#808080"
        font.pixelSize: 16
        visible: root.count === 0
    }
}

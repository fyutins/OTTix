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
    signal playRequested(string name, string url, string logo, string group)
    signal favoriteToggled(int dbId)

    delegate: ChannelDelegate {
        channelName: model.name
        channelUrl: model.url
        channelLogo: model.logo
        channelGroup: isFavoritesModel ? model.group : model.groupName
        channelDbId: isFavoritesModel ? model.id : model.channelId
        isFavorite: isFavoritesModel ? true : model.isFavorite
        onPlayRequested: (name, url, logo, group) => root.playRequested(name, url, logo, group)
        onFavoriteToggled: (id) => root.favoriteToggled(id)
    }

    Label {
        anchors.centerIn: parent
        text: isFavoritesModel ? qsTr("No favorites yet") : qsTr("No channels found")
        color: "#808080"
        font.pixelSize: 16
        visible: parent.count === 0
    }
}

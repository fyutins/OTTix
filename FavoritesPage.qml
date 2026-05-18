import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import IptvPlayer.Database

Rectangle {
    id: root
    color: "transparent"

    signal channelSelected(string name, string url, string logo, string group)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        Label {
            text: qsTr("Favorites")
            color: "#e0e0e0"
            font.pixelSize: 22
            font.bold: true
        }

        GridView {
            id: favoritesGrid
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: listModel
            cellWidth: 158
            cellHeight: 118
            delegate: ChannelDelegate {
                channelName: model.name
                channelUrl: model.url
                channelLogo: model.logo
                channelGroup: model.group
                channelDbId: model.id
                isFavorite: true
                onPlayRequested: (name, url, logo, group) => root.channelSelected(name, url, logo, group)
                onFavoriteToggled: (id) => DatabaseManager.removeFavorite(id)
            }
            clip: true
            ScrollBar.vertical: ScrollBar {}
            boundsBehavior: Flickable.StopAtBounds

            Label {
                anchors.centerIn: parent
                text: qsTr("No favorites yet")
                color: "#808080"
                font.pixelSize: 16
                visible: favoritesGrid.count === 0
            }
        }
    }

    ListModel { id: listModel }

    function refresh() {
        listModel.clear()
        var favs = DatabaseManager.getFavoritesVariant()
        for (var i = 0; i < favs.length; i++)
            listModel.append(favs[i])
    }

    Component.onCompleted: {
        refresh()
        DatabaseManager.favoritesChanged.connect(refresh)
    }
}

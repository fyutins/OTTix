import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import IptvPlayer.Database

Rectangle {
    id: root
    color: "transparent"

    signal channelSelected(string name, string url, string logo, string group)

    property string filterText: ""

    function matchesFilter(name, filter) {
        if (filter === "") return true
        var tokens = filter.split(" ")
        for (var t = 0; t < tokens.length; t++) {
            if (tokens[t] === "") continue
            if (name.toLowerCase().indexOf(tokens[t].toLowerCase()) === -1)
                return false
        }
        return true
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            color: "#16213e"
            radius: 8

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8

                TextField {
                    id: searchField
                    Layout.fillWidth: true
                    placeholderText: qsTr("Search favorites...")
                    color: "#e0e0e0"
                    placeholderTextColor: "#808080"
                    background: Rectangle {
                        color: "#0f3460"
                        radius: 6
                    }
                    onTextChanged: {
                        filterText = text
                        refresh()
                    }
                }

                Label {
                    text: displayCount + " " + qsTr("favorites")
                    color: "#a0a0a0"
                    font.pixelSize: 12
                }
            }
        }

        Item { Layout.preferredHeight: 8 }

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
                onFavoriteToggled: (id) => {
                    DatabaseManager.removeFavorite(id)
                    root.refresh()
                }
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

    property int displayCount: 0

    ListModel { id: listModel }

    function refresh() {
        listModel.clear()
        var count = 0
        var favs = DatabaseManager.getFavoritesVariant()
        for (var i = 0; i < favs.length; i++) {
            if (root.matchesFilter(favs[i].name, root.filterText)) {
                listModel.append(favs[i])
                count++
            }
        }
        displayCount = count
    }

    Component.onCompleted: {
        refresh()
        DatabaseManager.favoritesChanged.connect(refresh)
    }
}

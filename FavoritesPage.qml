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

        ChannelSearchBar {
            id: searchBar
            searchPlaceholder: qsTr("Search favorites...")
            countText: displayCount + " " + qsTr("favorites")
            onSearchChanged: {
                filterText = text
                refresh()
            }
        }

        Item { Layout.preferredHeight: 8 }

        ChannelGrid {
            id: favoritesGrid
            Layout.fillWidth: true
            Layout.fillHeight: true
            isFavoritesModel: true
            model: listModel
            onPlayRequested: (name, url, logo, group) => root.channelSelected(name, url, logo, group)
            onFavoriteToggled: (id) => {
                DatabaseManager.removeFavorite(id)
                root.refresh()
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

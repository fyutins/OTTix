import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    color: "transparent"

    signal channelSelected(string name, string url, string logo, string group)

    property string filterText: ""

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        ChannelSearchBar {
            id: searchBar
            searchPlaceholder: qsTr("Search favorites...")
            countText: root.displayCount + " " + qsTr("favorites")
            onSearchChanged: function(text) {
                root.filterText = text
                root.refresh()
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
            if (ChannelListModel.matchesFilter(favs[i].name, root.filterText)) {
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

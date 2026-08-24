import QtQuick
import QtQuick.Layouts

Item {
    id: root

    signal channelSelected(string name, string url, string logo, string group)

    property string filterText: ""
    property int displayCount: 0

    function focusSearch() { searchBar.focusSearch() }

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

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingMd
        spacing: Theme.spacingSm

        ChannelSearchBar {
            id: searchBar
            searchPlaceholder: qsTr("Search favorites...")
            countText: root.displayCount + " " + qsTr("favorites")
            onSearchChanged: function(text) {
                root.filterText = text
                root.refresh()
            }
        }

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

    ListModel { id: listModel }

    Component.onCompleted: {
        refresh()
        DatabaseManager.favoritesChanged.connect(refresh)
    }
}

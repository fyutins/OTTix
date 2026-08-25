import QtQuick
import QtQuick.Layouts

Item {
    id: root

    signal channelSelected(string name, string url, string logo, string group)

    property string searchText: ""

    // ChannelListModel is shared across tabs: each page re-applies its own
    // filter when it becomes visible again.
    function activate() {
        ChannelListModel.filterGroup = ""
        ChannelListModel.filterText = searchText
    }

    function focusSearch() { searchBar.focusSearch() }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingMd
        spacing: Theme.spacingSm

        ChannelSearchBar {
            id: searchBar
            searchPlaceholder: qsTr("Search channels...")
            countText: ChannelListModel.count + " " + qsTr("channels")
            onSearchChanged: function(text) {
                root.searchText = text
                ChannelListModel.filterText = text
            }
        }

        ChannelGrid {
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: ChannelListModel
            onPlayRequested: (name, url, logo, group) => root.channelSelected(name, url, logo, group)
            onFavoriteToggled: (id) => ChannelListModel.toggleFavorite(id)
        }
    }

    Component.onCompleted: activate()
}

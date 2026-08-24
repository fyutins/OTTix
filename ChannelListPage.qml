import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    color: "transparent"

    signal channelSelected(string name, string url, string logo, string group)

    property string searchText: ""

    // ChannelListModel est partage par les onglets : chaque page reapplique son
    // propre filtre quand elle redevient visible.
    function activate() {
        ChannelListModel.filterGroup = ""
        ChannelListModel.filterText = searchText
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        ChannelSearchBar {
            searchPlaceholder: qsTr("Search channels...")
            countText: ChannelListModel.count + " " + qsTr("channels")
            onSearchChanged: function(text) {
                root.searchText = text
                ChannelListModel.filterText = text
            }
        }

        Item { Layout.preferredHeight: 8 }

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

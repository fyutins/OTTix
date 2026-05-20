import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import IptvPlayer.Models

Rectangle {
    id: root
    color: "transparent"

    signal channelSelected(string name, string url, string logo, string group)

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        ChannelSearchBar {
            searchPlaceholder: qsTr("Search channels...")
            countText: ChannelListModel.count + " " + qsTr("channels")
            onSearchChanged: ChannelListModel.filterText = text
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

    Component.onCompleted: {
        ChannelListModel.filterGroup = ""
        ChannelListModel.refresh()
    }
}

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
                    placeholderText: qsTr("Search channels...")
                    color: "#e0e0e0"
                    placeholderTextColor: "#808080"
                    background: Rectangle {
                        color: "#0f3460"
                        radius: 6
                    }
                    onTextChanged: ChannelListModel.filterText = text
                }

                Label {
                    text: ChannelListModel.count + " " + qsTr("channels")
                    color: "#a0a0a0"
                    font.pixelSize: 12
                }
            }
        }

        Item { Layout.preferredHeight: 8 }

        GridView {
            id: channelGridView
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: ChannelListModel
            cellWidth: 158
            cellHeight: 118
            delegate: ChannelDelegate {
                channelName: model.name
                channelUrl: model.url
                channelLogo: model.logo
                channelGroup: model.groupName
                channelDbId: model.channelId
                isFavorite: model.isFavorite
                onPlayRequested: (name, url, logo, group) => root.channelSelected(name, url, logo, group)
                onFavoriteToggled: (id) => ChannelListModel.toggleFavorite(id)
            }
            clip: true
            ScrollBar.vertical: ScrollBar {}
            boundsBehavior: Flickable.StopAtBounds
        }
    }

    Component.onCompleted: {
        ChannelListModel.filterGroup = ""
        ChannelListModel.refresh()
    }
}
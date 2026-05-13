import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import IptvPlayer.Models

Rectangle {
    id: root
    color: "transparent"

    signal channelSelected(string name, string url)

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

                ComboBox {
                    id: groupFilter
                    Layout.preferredWidth: 150
                    model: {
                        var groups = ChannelListModel.groups
                        var arr = ["All"]
                        for (var i = 0; i < groups.length; i++) {
                            if (groups[i] !== "")
                                arr.push(groups[i])
                        }
                        return arr
                    }
                    onCurrentTextChanged: {
                        if (currentIndex === 0)
                            ChannelListModel.filterGroup = ""
                        else
                            ChannelListModel.filterGroup = currentText
                    }
                }

                Label {
                    text: ChannelListModel.count + " channels"
                    color: "#a0a0a0"
                    font.pixelSize: 12
                }
            }
        }

        Item { Layout.preferredHeight: 8 }

        ListView {
            id: channelListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: ChannelListModel
            delegate: ChannelDelegate {
                width: channelListView.width
                channelName: model.name
                channelUrl: model.url
                channelLogo: model.logo
                channelGroup: model.groupName
                channelDbId: model.channelId
                isFavorite: model.isFavorite
                onPlayRequested: (name, url) => root.channelSelected(name, url)
                onFavoriteToggled: (id) => ChannelListModel.toggleFavorite(id)
            }
            clip: true
            spacing: 2

            ScrollBar.vertical: ScrollBar {}

            Behavior on contentY {
                NumberAnimation { duration: 150 }
            }
        }
    }

    Component.onCompleted: {
        ChannelListModel.refresh()
    }
}
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

        // Search bar
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

        // Channel list
        ListView {
            id: channelListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: ChannelListModel
            delegate: channelDelegate
            clip: true
            spacing: 2

            ScrollBar.vertical: ScrollBar {}

            Behavior on contentY {
                NumberAnimation { duration: 150 }
            }
        }
    }

    Component {
        id: channelDelegate

        Rectangle {
            width: channelListView.width
            height: 56
            color: mouseArea.containsMouse ? "#0f3460" : "#1a1a2e"
            radius: 6

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 12

                // Logo
                Rectangle {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    radius: 6
                    color: "#16213e"

                    Image {
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectFit
                        source: model.logo || ""
                        asynchronous: true
                    }
                }

                // Info
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Label {
                        text: model.name
                        color: "#e0e0e0"
                        font.pixelSize: 14
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Label {
                        text: model.groupName || ""
                        color: "#808080"
                        font.pixelSize: 11
                        visible: text !== ""
                    }
                }

                // Favorite button
                ToolButton {
                    text: model.isFavorite ? "★" : "☆"
                    font.pixelSize: 18
                    onClicked: {
                        // Toggle favorite via C++ would be better
                        // For now we just update the model
                        model.isFavorite = !model.isFavorite
                    }
                }

                // Play button
                Button {
                    text: "▶"
                    onClicked: root.channelSelected(model.name, model.url)
                }
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.channelSelected(model.name, model.url)
            }
        }
    }

    Component.onCompleted: {
        ChannelListModel.refresh()
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import IptvPlayer.Database

Rectangle {
    id: root
    color: "transparent"

    signal channelSelected(string name, string url)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        Label {
            text: qsTr("Favorites")
            color: "#e0e0e0"
            font.pixelSize: 22
            font.bold: true
        }

        ListView {
            id: favoritesList
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: listModel
            delegate: favoriteDelegate
            clip: true
            spacing: 2

            ScrollBar.vertical: ScrollBar {}

            Label {
                anchors.centerIn: parent
                text: qsTr("No favorites yet")
                color: "#808080"
                font.pixelSize: 16
                visible: favoritesList.count === 0
            }
        }
    }

    ListModel { id: listModel }

    Component {
        id: favoriteDelegate

        Rectangle {
            width: favoritesList.width
            height: 56
            color: "#16213e"
            radius: 6

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 12

                Rectangle {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    radius: 6
                    color: "#0f3460"

                    Image {
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectFit
                        source: model.logo || ""
                        asynchronous: true
                    }
                }

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
                        text: model.group || ""
                        color: "#808080"
                        font.pixelSize: 11
                        visible: text !== ""
                    }
                }

                Button {
                    text: "\u2605"
                    font.pixelSize: 18
                    flat: true
                    onClicked: {
                        DatabaseManager.removeFavorite(model.id)
                        refresh()
                    }
                }

                Button {
                    text: "\u25B6"
                    onClicked: root.channelSelected(model.name, model.url)
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.channelSelected(model.name, model.url)
            }
        }
    }

    function refresh() {
        listModel.clear()
        var favs = DatabaseManager.getFavoritesVariant()
        for (var i = 0; i < favs.length; i++)
            listModel.append(favs[i])
    }

    Component.onCompleted: refresh()
}

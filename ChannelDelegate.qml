import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: delegateRoot
    height: 56
    radius: 6
    color: clickArea.containsMouse ? "#0f3460" : "#16213e"

    property string channelName: ""
    property string channelUrl: ""
    property string channelLogo: ""
    property string channelGroup: ""
    property int channelDbId: -1
    property bool isFavorite: false

    signal playRequested(string name, string url, string logo, string group)
    signal favoriteToggled(int channelDbId)

    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 12

        MouseArea {
            id: clickArea
            Layout.fillWidth: true
            Layout.fillHeight: true
            hoverEnabled: true
            onClicked: delegateRoot.playRequested(
                delegateRoot.channelName, delegateRoot.channelUrl,
                delegateRoot.channelLogo, delegateRoot.channelGroup)

            RowLayout {
                anchors.fill: parent
                spacing: 12

                Rectangle {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    radius: 6
                    color: "#0f3460"

                    Image {
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectFit
                        source: delegateRoot.channelLogo || ""
                        asynchronous: true
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Label {
                        text: delegateRoot.channelName
                        color: "#e0e0e0"
                        font.pixelSize: 14
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Label {
                        text: delegateRoot.channelGroup || ""
                        color: "#808080"
                        font.pixelSize: 11
                        visible: text !== ""
                    }
                }
            }
        }

        ToolButton {
            text: delegateRoot.isFavorite ? "\u2605" : "\u2606"
            font.pixelSize: 18
            onClicked: delegateRoot.favoriteToggled(delegateRoot.channelDbId)
        }

        Button {
            text: "\u25B6"
            onClicked: delegateRoot.playRequested(
                delegateRoot.channelName, delegateRoot.channelUrl,
                delegateRoot.channelLogo, delegateRoot.channelGroup)
        }
    }
}
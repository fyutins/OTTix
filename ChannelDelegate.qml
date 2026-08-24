import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: delegateRoot
    width: 150
    height: 110
    radius: 8
    color: mouseArea.containsMouse ? "#0f3460" : "#16213e"

    property string channelName: ""
    property string channelUrl: ""
    property string channelLogo: ""
    property string channelGroup: ""
    property int channelDbId: -1
    property bool isFavorite: false
    property bool showFavoriteIcon: true

    signal playRequested(string name, string url, string logo, string group)
    signal favoriteToggled(int channelDbId)

    Dialog {
        id: infoDialog
        modal: true
        standardButtons: Dialog.Close
        title: delegateRoot.channelName

        ColumnLayout {
            spacing: 8
            Layout.preferredWidth: 400

            Label {
                text: qsTr("ID: %1").arg(delegateRoot.channelDbId)
                color: "#e0e0e0"
                font.pixelSize: 13
            }
            Label {
                text: qsTr("Name: %1").arg(delegateRoot.channelName)
                color: "#e0e0e0"
                font.pixelSize: 13
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            Label {
                text: qsTr("URL: %1").arg(delegateRoot.channelUrl)
                color: "#e0e0e0"
                font.pixelSize: 13
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            Label {
                text: qsTr("Category: %1").arg(delegateRoot.channelGroup || qsTr("None"))
                color: "#e0e0e0"
                font.pixelSize: 13
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }
    }

    Menu {
        id: contextMenu

        MenuItem {
            text: qsTr("Info")
            onTriggered: infoDialog.open()
        }
        MenuSeparator {}
        MenuItem {
            text: delegateRoot.isFavorite
                ? qsTr("Remove from Favorites")
                : qsTr("Add to Favorites")
            onTriggered: delegateRoot.favoriteToggled(delegateRoot.channelDbId)
        }
        MenuSeparator {}
        MenuItem {
            text: qsTr("Copy URL")
            onTriggered: ClipboardHelper.copyText(delegateRoot.channelUrl)
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton)
                contextMenu.popup(mouseArea, mouseX, mouseY)
            else
                delegateRoot.playRequested(
                    delegateRoot.channelName, delegateRoot.channelUrl,
                    delegateRoot.channelLogo, delegateRoot.channelGroup)
        }
    }

    Label {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 6
        anchors.rightMargin: 6
        text: delegateRoot.isFavorite ? "\u2605" : "\u2606"
        color: "#e0e0e0"
        font.pixelSize: 14
        z: 1
        visible: delegateRoot.showFavoriteIcon
        MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            onClicked: delegateRoot.favoriteToggled(delegateRoot.channelDbId)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 2

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36
            radius: 6
            color: "#0f3460"

            Image {
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                source: delegateRoot.channelLogo || ""
                asynchronous: true
            }
        }

        Item { Layout.fillHeight: true }

        Label {
            Layout.fillWidth: true
            text: delegateRoot.channelName
            color: "#e0e0e0"
            font.pixelSize: 11
            maximumLineCount: 2
            wrapMode: Text.WordWrap
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
        }

        Label {
            Layout.fillWidth: true
            text: delegateRoot.channelGroup || ""
            color: "#808080"
            font.pixelSize: 9
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            visible: text !== ""
        }
    }
}

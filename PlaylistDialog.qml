import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
    id: dialog
    title: qsTr("Add Playlist")
    standardButtons: Dialog.Ok | Dialog.Cancel
    modal: true
    width: 480
    height: playlistType === "xtream" ? 520 : 400
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2

    property string playlistType: "m3u"

    signal playlistAdded(string name, string url, string type, string username, string password)

    contentItem: ColumnLayout {
        spacing: 12
        anchors.margins: 16

        Label {
            text: qsTr("Playlist Name")
            color: "#e0e0e0"
        }

        TextField {
            id: nameField
            Layout.fillWidth: true
            placeholderText: qsTr("My Playlist")
            color: "#e0e0e0"
            background: Rectangle { color: "#16213e"; radius: 6 }
        }

        Label {
            text: qsTr("Type")
            color: "#e0e0e0"
        }

        ComboBox {
            id: typeCombo
            Layout.fillWidth: true
            model: ["M3U URL", "XTREAM API"]
            onCurrentIndexChanged: {
                playlistType = currentIndex === 0 ? "m3u" : "xtream"
                xtreamFields.visible = currentIndex === 1
            }
        }

        Label {
            text: qsTr("URL")
            color: "#e0e0e0"
        }

        TextField {
            id: urlField
            Layout.fillWidth: true
            placeholderText: qsTr("http://example.com/playlist.m3u")
            color: "#e0e0e0"
            background: Rectangle { color: "#16213e"; radius: 6 }
        }

        ColumnLayout {
            id: xtreamFields
            Layout.fillWidth: true
            visible: false
            spacing: 12

            Label {
                text: qsTr("Username")
                color: "#e0e0e0"
            }

            TextField {
                id: usernameField
                Layout.fillWidth: true
                placeholderText: qsTr("username")
                color: "#e0e0e0"
                background: Rectangle { color: "#16213e"; radius: 6 }
            }

            Label {
                text: qsTr("Password")
                color: "#e0e0e0"
            }

            TextField {
                id: passwordField
                Layout.fillWidth: true
                placeholderText: qsTr("password")
                echoMode: TextInput.Password
                color: "#e0e0e0"
                background: Rectangle { color: "#16213e"; radius: 6 }
            }
        }
    }

    onAccepted: {
        if (nameField.text === "" || urlField.text === "")
            return

        var type = typeCombo.currentIndex === 0 ? "m3u" : "xtream"
        var username = type === "xtream" ? usernameField.text : ""
        var password = type === "xtream" ? passwordField.text : ""

        dialog.playlistAdded(nameField.text, urlField.text, type, username, password)
    }

    onVisibleChanged: {
        if (visible) {
            nameField.text = ""
            urlField.text = ""
            usernameField.text = ""
            passwordField.text = ""
            typeCombo.currentIndex = 0
        }
    }
}

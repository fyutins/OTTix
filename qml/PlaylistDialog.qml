import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Add / edit a playlist (M3U or Xtream).
Popup {
    id: dialog

    property string playlistType: "m3u"
    property int editId: -1
    readonly property bool isEdit: dialog.editId > 0
    readonly property bool isValid: nameField.text.trim() !== "" && urlField.text.trim() !== ""
        && (dialog.playlistType !== "xtream"
            || (usernameField.text.trim() !== "" && passwordField.text !== ""))

    signal playlistAdded(string name, string url, string type, string username, string password)
    signal playlistEdited(int id, string name, string url, string type, string username, string password)

    modal: true
    parent: Overlay.overlay
    anchors.centerIn: Overlay.overlay
    width: 480
    padding: Theme.spacingLg
    closePolicy: Popup.CloseOnEscape

    function openForEdit(id, name, url, type, username, password) {
        editId = id
        nameField.text = name
        urlField.text = url
        typeCombo.currentIndex = type === "xtream" ? 1 : 0
        usernameField.text = username || ""
        passwordField.text = password || ""
        open()
    }

    function resetFields() {
        nameField.text = ""
        urlField.text = ""
        usernameField.text = ""
        passwordField.text = ""
        typeCombo.currentIndex = 0
    }

    function submit() {
        if (!dialog.isValid)
            return

        var type = typeCombo.currentIndex === 0 ? "m3u" : "xtream"
        var username = type === "xtream" ? usernameField.text : ""
        var password = type === "xtream" ? passwordField.text : ""

        if (dialog.editId > 0)
            dialog.playlistEdited(dialog.editId, nameField.text.trim(), urlField.text.trim(), type, username, password)
        else
            dialog.playlistAdded(nameField.text.trim(), urlField.text.trim(), type, username, password)

        dialog.close()
    }

    Overlay.modal: Rectangle {
        color: Qt.rgba(0, 0, 0, 0.6)
    }

    background: Rectangle {
        color: Theme.surface
        radius: Theme.radiusMd
        border.width: 1
        border.color: Theme.border
    }

    component FieldLabel: Text {
        color: Theme.textMuted
        font.pixelSize: Theme.fontSm
        font.bold: true
    }

    component FieldInput: TextField {
        id: fieldInput

        implicitHeight: Theme.controlMd
        leftPadding: Theme.spacingMd
        rightPadding: Theme.spacingMd
        color: Theme.text
        placeholderTextColor: Theme.textDim
        font.pixelSize: Theme.fontMd
        selectByMouse: true

        background: Rectangle {
            color: Theme.surfaceAlt
            radius: Theme.radiusSm
            border.width: 1
            border.color: fieldInput.activeFocus ? Theme.accent
                        : fieldInput.hovered ? Theme.borderStrong : Theme.border

            Behavior on border.color { ColorAnimation { duration: Theme.durFast } }
        }
    }

    contentItem: ColumnLayout {
        spacing: Theme.spacingMd

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingSm

            MdiIcon {
                glyph: dialog.isEdit ? Mdi.pencil : Mdi.plusCircle
                font.pixelSize: Theme.iconMd
                color: Theme.accent
            }

            Text {
                Layout.fillWidth: true
                text: dialog.isEdit ? qsTr("Edit Playlist") : qsTr("Add Playlist")
                color: Theme.text
                font.pixelSize: Theme.fontLg
                font.bold: true
            }

            IconButton {
                glyph: Mdi.close
                glyphColor: Theme.textMuted
                onClicked: dialog.close()
            }
        }

        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.border }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingXs

            FieldLabel { text: qsTr("Playlist name") }

            FieldInput {
                id: nameField
                Layout.fillWidth: true
                placeholderText: qsTr("My Playlist")
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingXs

            FieldLabel { text: qsTr("Type") }

            AppComboBox {
                id: typeCombo
                Layout.fillWidth: true
                model: ["M3U URL", "XTREAM API"]
                onCurrentIndexChanged: dialog.playlistType = currentIndex === 0 ? "m3u" : "xtream"
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingXs

            FieldLabel {
                text: dialog.playlistType === "xtream" ? qsTr("Server URL") : qsTr("Playlist URL")
            }

            FieldInput {
                id: urlField
                Layout.fillWidth: true
                placeholderText: dialog.playlistType === "xtream"
                    ? qsTr("http://example.com:8080")
                    : qsTr("http://example.com/playlist.m3u")
            }
        }

        ColumnLayout {
            id: xtreamFields
            Layout.fillWidth: true
            visible: dialog.playlistType === "xtream"
            spacing: Theme.spacingMd

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingXs

                FieldLabel { text: qsTr("Username") }

                FieldInput {
                    id: usernameField
                    Layout.fillWidth: true
                    placeholderText: qsTr("username")
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingXs

                FieldLabel { text: qsTr("Password") }

                FieldInput {
                    id: passwordField
                    Layout.fillWidth: true
                    placeholderText: qsTr("password")
                    echoMode: TextInput.Password
                    onAccepted: dialog.submit()
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Theme.spacingXs
            spacing: Theme.spacingSm

            Text {
                Layout.fillWidth: true
                text: dialog.isValid ? "" : qsTr("Fill in every field to continue")
                color: Theme.textDim
                font.pixelSize: Theme.fontSm
            }

            AppButton {
                text: qsTr("Cancel")
                variant: AppButton.Ghost
                onClicked: dialog.close()
            }

            AppButton {
                text: dialog.isEdit ? qsTr("Save") : qsTr("Add")
                variant: AppButton.Primary
                glyph: dialog.isEdit ? Mdi.check : Mdi.plus
                enabled: dialog.isValid
                onClicked: dialog.submit()
            }
        }
    }

    onOpened: {
        if (!dialog.isEdit)
            resetFields()
        nameField.forceActiveFocus()
    }

    onClosed: editId = -1
}

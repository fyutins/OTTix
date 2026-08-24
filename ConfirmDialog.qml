import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Confirmation d'une action destructive.
Popup {
    id: dialog

    property string glyph: Mdi.alert
    property string title: ""
    property string message: ""
    property string confirmText: qsTr("Confirm")
    property string cancelText: qsTr("Cancel")

    signal confirmed()

    modal: true
    parent: Overlay.overlay
    anchors.centerIn: Overlay.overlay
    width: 420
    padding: Theme.spacingLg
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    Overlay.modal: Rectangle {
        color: Qt.rgba(0, 0, 0, 0.6)
    }

    background: Rectangle {
        color: Theme.surface
        radius: Theme.radiusMd
        border.width: 1
        border.color: Theme.border
    }

    contentItem: ColumnLayout {
        spacing: Theme.spacingMd

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingSm

            Rectangle {
                Layout.preferredWidth: Theme.controlLg
                Layout.preferredHeight: Theme.controlLg
                radius: Theme.radiusSm
                color: Theme.dangerSoft

                MdiIcon {
                    anchors.centerIn: parent
                    glyph: dialog.glyph
                    font.pixelSize: Theme.iconMd
                    color: Theme.danger
                }
            }

            Text {
                Layout.fillWidth: true
                text: dialog.title
                color: Theme.text
                font.pixelSize: Theme.fontLg
                font.bold: true
                wrapMode: Text.WordWrap
            }
        }

        Text {
            Layout.fillWidth: true
            text: dialog.message
            color: Theme.textMuted
            font.pixelSize: Theme.fontMd
            wrapMode: Text.WordWrap
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Theme.spacingXs
            spacing: Theme.spacingSm

            Item { Layout.fillWidth: true }

            AppButton {
                text: dialog.cancelText
                variant: AppButton.Ghost
                onClicked: dialog.close()
            }

            AppButton {
                text: dialog.confirmText
                variant: AppButton.Danger
                onClicked: {
                    dialog.confirmed()
                    dialog.close()
                }
            }
        }
    }
}

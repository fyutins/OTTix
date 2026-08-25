import QtQuick
import QtQuick.Layouts

// Settings card: header (icon + title) then free-form content.
Rectangle {
    id: card

    property string glyph: ""
    property string title: ""
    default property alias content: contentColumn.data

    color: Theme.surface
    radius: Theme.radiusMd
    border.width: 1
    border.color: Theme.border
    implicitHeight: cardColumn.implicitHeight + Theme.spacingLg * 2

    ColumnLayout {
        id: cardColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.spacingLg
        spacing: Theme.spacingMd

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingSm

            MdiIcon {
                glyph: card.glyph
                font.pixelSize: Theme.iconMd
                color: Theme.accent
            }

            Text {
                Layout.fillWidth: true
                text: card.title
                color: Theme.text
                font.pixelSize: Theme.fontLg
                font.bold: true
            }
        }

        ColumnLayout {
            id: contentColumn
            Layout.fillWidth: true
            spacing: Theme.spacingSm
        }
    }
}

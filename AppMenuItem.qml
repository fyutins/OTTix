import QtQuick
import QtQuick.Controls

// Menu entry: check mark on the left for checkable items, optional icon,
// chevron for submenus.
MenuItem {
    id: control

    property string glyph: ""
    property bool danger: false

    readonly property color fgColor: !control.enabled ? Theme.textDim
                                   : control.danger ? Theme.danger : Theme.text

    implicitHeight: Theme.controlMd
    leftPadding: Theme.spacingSm
    rightPadding: Theme.spacingSm

    indicator: Item {}

    arrow: MdiIcon {
        anchors.right: parent.right
        anchors.rightMargin: Theme.spacingSm
        anchors.verticalCenter: parent.verticalCenter
        visible: control.subMenu !== null
        glyph: Mdi.chevronRight
        font.pixelSize: Theme.iconSm
        color: Theme.textMuted
    }

    contentItem: Row {
        spacing: Theme.spacingSm

        MdiIcon {
            anchors.verticalCenter: parent.verticalCenter
            width: Theme.iconSm
            visible: control.checkable
            glyph: control.checked ? Mdi.check : ""
            font.pixelSize: Theme.iconSm
            color: Theme.accent
        }

        MdiIcon {
            anchors.verticalCenter: parent.verticalCenter
            visible: control.glyph !== ""
            glyph: control.glyph
            font.pixelSize: Theme.iconSm
            color: control.fgColor
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: control.text
            font.pixelSize: Theme.fontMd
            color: control.fgColor
        }
    }

    background: Rectangle {
        radius: Theme.radiusSm
        color: control.highlighted
               ? (control.danger ? Theme.dangerSoft : Theme.surfaceHi)
               : "transparent"

        Behavior on color { ColorAnimation { duration: Theme.durFast } }
    }
}

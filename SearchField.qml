import QtQuick
import QtQuick.Controls

// Search field: magnifier on the left, clear button on the right, border that
// lights up on focus.
TextField {
    id: control

    implicitHeight: Theme.controlMd
    leftPadding: Theme.spacingXl + Theme.spacingXs
    rightPadding: control.text !== "" ? Theme.controlSm + Theme.spacingXs : Theme.spacingMd
    color: Theme.text
    placeholderTextColor: Theme.textDim
    font.pixelSize: Theme.fontMd
    selectByMouse: true
    selectionColor: Theme.accent
    selectedTextColor: Theme.textOnAccent

    background: Rectangle {
        radius: Theme.radiusSm
        color: Theme.surfaceAlt
        border.width: 1
        border.color: control.activeFocus ? Theme.accent
                    : control.hovered ? Theme.borderStrong : Theme.border

        Behavior on border.color { ColorAnimation { duration: Theme.durFast } }
    }

    MdiIcon {
        x: Theme.spacingMd
        anchors.verticalCenter: parent.verticalCenter
        glyph: Mdi.magnify
        font.pixelSize: Theme.iconSm
        color: control.activeFocus ? Theme.accent : Theme.textDim

        Behavior on color { ColorAnimation { duration: Theme.durFast } }
    }

    IconButton {
        anchors.right: parent.right
        anchors.rightMargin: Theme.spacingXs
        anchors.verticalCenter: parent.verticalCenter
        visible: control.text !== ""
        implicitWidth: Theme.controlSm
        implicitHeight: Theme.controlSm
        glyph: Mdi.closeCircle
        glyphSize: Theme.iconSm
        glyphColor: Theme.textDim
        tooltip: qsTr("Clear")
        onClicked: {
            control.clear()
            control.forceActiveFocus()
        }
    }
}

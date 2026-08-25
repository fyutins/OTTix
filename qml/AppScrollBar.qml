import QtQuick
import QtQuick.Controls

// Discreet scroll bar that thickens on hover.
ScrollBar {
    id: control

    implicitWidth: 10
    padding: 2

    contentItem: Rectangle {
        implicitWidth: control.hovered || control.pressed ? 8 : 5
        radius: width / 2
        color: control.pressed ? Theme.borderStrong
             : control.hovered ? Theme.surfaceHi : Theme.border
        opacity: control.policy === ScrollBar.AlwaysOn || control.active ? 1.0 : 0.0

        Behavior on implicitWidth { NumberAnimation { duration: Theme.durFast } }
        Behavior on color { ColorAnimation { duration: Theme.durFast } }
        Behavior on opacity { NumberAnimation { duration: Theme.durNormal } }
    }

    background: Item {}
}

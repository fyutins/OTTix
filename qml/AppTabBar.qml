import QtQuick
import QtQuick.Controls

// Design system tab bar: surface background, bottom separator line, compact
// left-aligned tabs (see AppTabButton, which sets its own width to stop TabBar
// from splitting the space evenly).
TabBar {
    id: control

    implicitHeight: Theme.tabBarHeight
    leftPadding: Theme.spacingSm
    rightPadding: Theme.spacingSm
    spacing: Theme.spacingXs

    background: Rectangle {
        color: Theme.surface

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: Theme.border
        }
    }
}

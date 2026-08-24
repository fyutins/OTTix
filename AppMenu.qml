import QtQuick
import QtQuick.Controls

// Menu contextuel du design system.
Menu {
    id: control

    implicitWidth: 230
    padding: Theme.spacingXs
    margins: Theme.spacingSm

    delegate: AppMenuItem {}

    background: Rectangle {
        color: Theme.surface
        radius: Theme.radiusSm
        border.width: 1
        border.color: Theme.border
    }
}

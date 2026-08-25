import QtQuick
import QtQuick.Controls

// Design system tooltip, laid over the hovered element.
ToolTip {
    id: tip

    delay: 400
    margins: Theme.spacingXs
    padding: Theme.spacingSm
    x: tip.parent ? Math.round((tip.parent.width - tip.implicitWidth) / 2) : 0
    y: -tip.implicitHeight - Theme.spacingXs

    background: Rectangle {
        color: Theme.surfaceHi
        radius: Theme.radiusSm
        border.width: 1
        border.color: Theme.border
    }

    contentItem: Text {
        text: tip.text
        color: Theme.text
        font.pixelSize: Theme.fontSm
    }
}

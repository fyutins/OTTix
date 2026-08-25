pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls

// Design system drop-down list.
ComboBox {
    id: control

    // Right corners squared off when a control is attached to it (see IconButton.attachedLeft)
    property bool attachedRight: false

    implicitHeight: Theme.controlMd
    leftPadding: Theme.spacingMd
    rightPadding: Theme.controlMd
    font.pixelSize: Theme.fontMd
    hoverEnabled: true

    background: Rectangle {
        radius: Theme.radiusSm
        topRightRadius: control.attachedRight ? 0 : radius
        bottomRightRadius: control.attachedRight ? 0 : radius
        color: control.pressed ? Theme.surfaceHi : Theme.surfaceAlt
        border.width: 1
        border.color: control.activeFocus || control.popup.visible ? Theme.accent
                    : control.hovered ? Theme.borderStrong : Theme.border

        Behavior on color { ColorAnimation { duration: Theme.durFast } }
        Behavior on border.color { ColorAnimation { duration: Theme.durFast } }
    }

    contentItem: Text {
        text: control.displayText
        color: Theme.text
        font: control.font
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter
    }

    indicator: MdiIcon {
        x: control.width - width - Theme.spacingSm
        y: (control.height - height) / 2
        glyph: Mdi.chevronDown
        font.pixelSize: Theme.iconSm
        color: Theme.textMuted
        rotation: control.popup.visible ? 180 : 0

        Behavior on rotation { NumberAnimation { duration: Theme.durFast } }
    }

    delegate: ItemDelegate {
        id: itemDelegate

        required property var model
        required property int index

        width: ListView.view ? ListView.view.width : implicitWidth
        implicitHeight: Theme.controlMd
        highlighted: control.highlightedIndex === itemDelegate.index

        contentItem: Text {
            leftPadding: Theme.spacingSm
            text: itemDelegate.model[control.textRole !== "" ? control.textRole : "modelData"]
            color: control.currentIndex === itemDelegate.index ? Theme.accent : Theme.text
            font.pixelSize: Theme.fontMd
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }

        background: Rectangle {
            radius: Theme.radiusSm
            color: itemDelegate.highlighted ? Theme.surfaceHi : "transparent"
        }
    }

    popup: Popup {
        y: control.height + Theme.spacingXs
        width: control.width
        implicitHeight: Math.min(contentItem.implicitHeight + Theme.spacingSm, 320)
        padding: Theme.spacingXs

        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: control.popup.visible ? control.delegateModel : null
            currentIndex: control.highlightedIndex
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: AppScrollBar {}
        }

        background: Rectangle {
            color: Theme.surface
            radius: Theme.radiusSm
            border.width: 1
            border.color: Theme.border
        }
    }
}

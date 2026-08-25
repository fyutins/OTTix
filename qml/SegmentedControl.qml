pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls

// Segmented selector: several exclusive options inside one box.
//   SegmentedControl {
//       options: [{ label: qsTr("Auto"), glyph: Mdi.themeAuto, value: 0 }, ...]
//       currentValue: Theme.mode
//       onSelected: (value) => Theme.mode = value
//   }
Rectangle {
    id: control

    property var options: []
    property int currentValue: 0
    signal selected(int value)

    implicitWidth: segments.implicitWidth + Theme.spacingXs * 2
    implicitHeight: Theme.controlMd + Theme.spacingXs
    radius: Theme.radiusSm
    color: Theme.surfaceAlt
    border.width: 1
    border.color: Theme.border

    Row {
        id: segments
        anchors.centerIn: parent
        spacing: 2

        Repeater {
            model: control.options

            delegate: AbstractButton {
                id: segment

                required property var modelData

                readonly property bool current: control.currentValue === segment.modelData.value
                readonly property color fgColor: segment.current ? Theme.textOnAccent
                                               : segment.hovered ? Theme.text : Theme.textMuted

                implicitWidth: segmentRow.implicitWidth + Theme.spacingLg * 2
                implicitHeight: Theme.controlMd - 2
                hoverEnabled: true
                onClicked: control.selected(segment.modelData.value)

                background: Rectangle {
                    radius: Theme.radiusSm - 1
                    color: segment.current ? Theme.accent
                         : segment.down ? Theme.pressed
                         : segment.hovered ? Theme.hover : "transparent"

                    Behavior on color { ColorAnimation { duration: Theme.durFast } }
                }

                contentItem: Row {
                    id: segmentRow
                    spacing: Theme.spacingSm

                    MdiIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: segment.modelData.glyph !== undefined
                        glyph: segment.modelData.glyph || ""
                        font.pixelSize: Theme.iconSm
                        color: segment.fgColor

                        Behavior on color { ColorAnimation { duration: Theme.durFast } }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: segment.modelData.label
                        font.pixelSize: Theme.fontMd
                        font.bold: segment.current
                        color: segment.fgColor

                        Behavior on color { ColorAnimation { duration: Theme.durFast } }
                    }
                }

                HoverHandler { cursorShape: Qt.PointingHandCursor }
            }
        }
    }
}

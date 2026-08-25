pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls

GridView {
    id: root

    signal groupSelected(string groupName)

    readonly property int minCellWidth: 232

    cellWidth: root.width > root.minCellWidth
               ? Math.floor(root.width / Math.floor(root.width / root.minCellWidth))
               : root.minCellWidth
    cellHeight: 64
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    ScrollBar.vertical: AppScrollBar {}

    delegate: Item {
        id: groupCell

        required property var model

        readonly property string gName: groupCell.model.name

        width: root.cellWidth
        height: root.cellHeight

        Rectangle {
            anchors.fill: parent
            anchors.margins: Theme.spacingXs
            radius: Theme.radiusMd
            color: mouseArea.containsMouse ? Theme.surfaceHi : Theme.surfaceAlt
            border.width: 1
            border.color: mouseArea.containsMouse ? Theme.accent : Theme.border

            Behavior on color { ColorAnimation { duration: Theme.durFast } }
            Behavior on border.color { ColorAnimation { duration: Theme.durFast } }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.groupSelected(groupCell.gName)
            }

            Row {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.spacingMd
                anchors.rightMargin: Theme.spacingSm
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacingSm

                MdiIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    glyph: Mdi.folderMultiple
                    font.pixelSize: Theme.iconMd
                    color: mouseArea.containsMouse ? Theme.accent : Theme.textMuted
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - Theme.iconMd - Theme.iconSm - Theme.spacingSm * 2
                    text: groupCell.gName
                    color: Theme.text
                    font.pixelSize: Theme.fontMd
                    font.bold: true
                    elide: Text.ElideRight
                }

                MdiIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    glyph: Mdi.chevronRight
                    font.pixelSize: Theme.iconSm
                    color: mouseArea.containsMouse ? Theme.accent : Theme.textDim
                }
            }
        }
    }

    EmptyState {
        anchors.centerIn: parent
        visible: root.count === 0
        glyph: Mdi.folderMultiple
        title: qsTr("No groups found")
    }
}

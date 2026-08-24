pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls

GridView {
    id: root
    cellWidth: 200
    cellHeight: 70
    clip: true
    ScrollBar.vertical: ScrollBar {}
    boundsBehavior: Flickable.StopAtBounds

    signal groupSelected(string groupName)

    delegate: Rectangle {
        id: groupCell

        required property var model

        width: root.cellWidth - 12
        height: root.cellHeight - 12
        x: 6
        y: 6
        radius: 8
        color: mouseArea.containsMouse ? "#0f3460" : "#16213e"

        property string gName: model.name

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.groupSelected(groupCell.gName)
        }

        Label {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: groupCell.gName
            color: "#e0e0e0"
            font.pixelSize: 14
            font.bold: true
            elide: Text.ElideRight
            width: parent.width - 36
        }

        Label {
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: "\u203A"
            color: "#808080"
            font.pixelSize: 20
        }
    }

    Label {
        anchors.centerIn: parent
        text: qsTr("No groups found")
        color: "#808080"
        font.pixelSize: 16
        visible: root.count === 0
    }
}

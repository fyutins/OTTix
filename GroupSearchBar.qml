import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    color: "#16213e"
    radius: 8
    Layout.fillWidth: true
    implicitHeight: 48

    property bool drillMode: false
    property string groupName: ""
    property alias searchText: searchField.text
    property string countText: ""
    signal backRequested()
    signal searchChanged(string text)

    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8

        Button {
            flat: true
            implicitWidth: 32
            implicitHeight: 32
            visible: root.drillMode
            contentItem: Text {
                text: "\u2190"
                color: "#4a90d9"
                font.pixelSize: 18
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle { color: "transparent"; radius: 4 }
            onClicked: root.backRequested()
        }

        TextField {
            id: searchField
            Layout.fillWidth: true
            visible: !root.drillMode
            placeholderText: qsTr("Search groups...")
            color: "#e0e0e0"
            placeholderTextColor: "#808080"
            background: Rectangle {
                color: "#0f3460"
                radius: 6
            }
            onTextChanged: root.searchChanged(text)
        }

        Label {
            visible: root.drillMode
            text: root.groupName
            color: "#e0e0e0"
            font.pixelSize: 16
            font.bold: true
            Layout.fillWidth: true
            elide: Text.ElideRight
        }

        Label {
            text: root.countText
            color: "#a0a0a0"
            font.pixelSize: 12
        }
    }
}

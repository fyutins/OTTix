import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    color: "#16213e"
    radius: 8
    Layout.fillWidth: true
    implicitHeight: 48

    property alias searchText: searchField.text
    property alias countText: countLabel.text
    property alias searchPlaceholder: searchField.placeholderText
    signal searchChanged(string text)

    function focusSearch() { searchField.forceActiveFocus() }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8

        TextField {
            id: searchField
            Layout.fillWidth: true
            color: "#e0e0e0"
            placeholderTextColor: "#808080"
            background: Rectangle {
                color: "#0f3460"
                radius: 6
            }
            onTextChanged: root.searchChanged(text)
        }

        Label {
            id: countLabel
            color: "#a0a0a0"
            font.pixelSize: 12
        }
    }
}

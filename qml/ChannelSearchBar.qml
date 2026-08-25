import QtQuick
import QtQuick.Layouts

// Search bar for the channel grids: field + result counter.
Item {
    id: root

    property alias searchText: searchField.text
    property alias countText: countLabel.text
    property alias searchPlaceholder: searchField.placeholderText
    signal searchChanged(string text)

    function focusSearch() { searchField.forceActiveFocus() }

    Layout.fillWidth: true
    implicitHeight: Theme.controlMd + Theme.spacingSm

    RowLayout {
        anchors.fill: parent
        anchors.topMargin: Theme.spacingXs
        anchors.bottomMargin: Theme.spacingXs
        spacing: Theme.spacingSm

        SearchField {
            id: searchField
            Layout.fillWidth: true
            Layout.maximumWidth: 460
            onTextChanged: root.searchChanged(text)
        }

        Item { Layout.fillWidth: true }

        Rectangle {
            Layout.preferredWidth: countLabel.implicitWidth + Theme.spacingMd
            Layout.preferredHeight: Theme.controlSm
            visible: countLabel.text !== ""
            radius: Theme.radiusPill
            color: Theme.surfaceAlt

            Text {
                id: countLabel
                anchors.centerIn: parent
                color: Theme.textMuted
                font.pixelSize: Theme.fontSm
            }
        }
    }
}

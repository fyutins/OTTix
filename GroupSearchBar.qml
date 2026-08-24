import QtQuick
import QtQuick.Layouts

// Barre de la page Groupes : recherche a la racine, fil d'Ariane en drill-down.
Item {
    id: root

    property bool drillMode: false
    property string groupName: ""
    property alias searchText: searchField.text
    property string countText: ""
    signal backRequested()
    signal searchChanged(string text)

    function focusSearch() { searchField.forceActiveFocus() }

    Layout.fillWidth: true
    implicitHeight: Theme.controlMd + Theme.spacingSm

    RowLayout {
        anchors.fill: parent
        anchors.topMargin: Theme.spacingXs
        anchors.bottomMargin: Theme.spacingXs
        spacing: Theme.spacingSm

        IconButton {
            visible: root.drillMode
            glyph: Mdi.arrowLeft
            glyphColor: Theme.accent
            tooltip: qsTr("Back to groups")
            onClicked: root.backRequested()
        }

        SearchField {
            id: searchField
            Layout.fillWidth: true
            Layout.maximumWidth: 460
            visible: !root.drillMode
            placeholderText: qsTr("Search groups...")
            onTextChanged: root.searchChanged(text)
        }

        Item { Layout.fillWidth: true; visible: !root.drillMode }

        RowLayout {
            Layout.fillWidth: true
            visible: root.drillMode
            spacing: Theme.spacingSm

            MdiIcon {
                glyph: Mdi.folderMultiple
                font.pixelSize: Theme.iconSm
                color: Theme.textMuted
            }

            Text {
                Layout.fillWidth: true
                text: root.groupName
                color: Theme.text
                font.pixelSize: Theme.fontLg
                font.bold: true
                elide: Text.ElideRight
            }
        }

        Rectangle {
            Layout.preferredWidth: countLabel.implicitWidth + Theme.spacingMd
            Layout.preferredHeight: Theme.controlSm
            visible: root.countText !== ""
            radius: Theme.radiusPill
            color: Theme.surfaceAlt

            Text {
                id: countLabel
                anchors.centerIn: parent
                text: root.countText
                color: Theme.textMuted
                font.pixelSize: Theme.fontSm
            }
        }
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import IptvPlayer.Models
import IptvPlayer.Database

Popup {
    id: popup
    modal: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    anchors.centerIn: Overlay.overlay
    width: 700
    height: 550

    property bool pickMode: false
    property string pickLabel: ""

    signal channelSelected(string name, string url, string logo, string group)

    property string selectedGroup: ""

    function openPicker() {
        selectedGroup = ""
        ChannelListModel.filterGroup = ""
        ChannelListModel.filterText = ""
        channelsSearchField.text = ""
        groupsSearchField.text = ""
        groupChannelsSearchField.text = ""
        favoritesSearchField.text = ""
        favoritesModel.refresh()
        tabBar.currentIndex = 0
        groupListModel.build()
        channelsSearchField.forceActiveFocus()
        open()
    }

    function handlePick(name, url, logo, group) {
        popup.channelSelected(name, url, logo, group)
        if (!popup.pickMode)
            popup.close()
    }

    function matchesFilter(name, filter) {
        if (filter === "") return true
        var tokens = filter.split(" ")
        for (var t = 0; t < tokens.length; t++) {
            if (tokens[t] === "") continue
            if (name.toLowerCase().indexOf(tokens[t].toLowerCase()) === -1)
                return false
        }
        return true
    }

    background: Rectangle {
        color: Qt.rgba(0, 0, 0, 0.85)
        radius: 12
    }

    contentItem: Rectangle {
        color: "#1a1a2e"
        radius: 12

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            // ── Header ──
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Label {
                    text: pickMode ? pickLabel : qsTr("Browse Channels")
                    color: "#e0e0e0"
                    font.pixelSize: 16
                    font.bold: true
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Button {
                    text: "\u2715"
                    flat: true
                    implicitWidth: 28
                    implicitHeight: 28
                    contentItem: Text {
                        text: "\u2715"
                        color: "#e0e0e0"
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: "transparent"
                        radius: 4
                    }
                    onClicked: popup.close()
                }
            }

            // ── Tabs ──
            TabBar {
                id: tabBar
                Layout.fillWidth: true

                TabButton { text: qsTr("All Channels") }
                TabButton { text: qsTr("Groups") }
                TabButton { text: qsTr("Favorites") }
            }

            // ── Content ──
            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: tabBar.currentIndex

                // ── Tab 0: All Channels ──
                ColumnLayout {
                    spacing: 8

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        color: "#16213e"
                        radius: 8

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8

                            TextField {
                                id: channelsSearchField
                                Layout.fillWidth: true
                                placeholderText: qsTr("Search channels...")
                                color: "#e0e0e0"
                                placeholderTextColor: "#808080"
                                background: Rectangle {
                                    color: "#0f3460"
                                    radius: 6
                                }
                                onTextChanged: {
                                    if (tabBar.currentIndex === 0)
                                        ChannelListModel.filterText = text
                                }
                            }

                            Label {
                                text: ChannelListModel.count + " " + qsTr("channels")
                                color: "#a0a0a0"
                                font.pixelSize: 11
                            }
                        }
                    }

                    GridView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        model: ChannelListModel
                        cellWidth: 158
                        cellHeight: 118
                        clip: true
                        ScrollBar.vertical: ScrollBar {}
                        boundsBehavior: Flickable.StopAtBounds

                        delegate: ChannelDelegate {
                            channelName: model.name
                            channelUrl: model.url
                            channelLogo: model.logo
                            channelGroup: model.groupName
                            channelDbId: model.channelId
                            isFavorite: model.isFavorite
                            onPlayRequested: (name, url, logo, group) => popup.handlePick(name, url, logo, group)
                            onFavoriteToggled: (id) => ChannelListModel.toggleFavorite(id)
                        }

                        Label {
                            anchors.centerIn: parent
                            text: qsTr("No channels found")
                            color: "#808080"
                            font.pixelSize: 16
                            visible: parent.count === 0
                        }
                    }
                }

                // ── Tab 1: Groups ──
                ColumnLayout {
                    spacing: 8

                    // Search + back button (when drilling into a group)
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: selectedGroup !== "" ? 36 : 40
                        color: "#16213e"
                        radius: 8

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8

                            Button {
                                text: "\u2190"
                                flat: true
                                implicitWidth: 24
                                implicitHeight: 24
                                visible: selectedGroup !== ""
                                contentItem: Text {
                                    text: "\u2190"
                                    color: "#4a90d9"
                                    font.pixelSize: 16
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                background: Rectangle { color: "transparent"; radius: 4 }
                                onClicked: {
                                    selectedGroup = ""
                                    ChannelListModel.filterGroup = ""
                                    ChannelListModel.filterText = ""
                                    groupsSearchField.text = ""
                                }
                            }

                            TextField {
                                id: groupsSearchField
                                Layout.fillWidth: true
                                visible: selectedGroup === ""
                                placeholderText: qsTr("Search groups...")
                                color: "#e0e0e0"
                                placeholderTextColor: "#808080"
                                background: Rectangle {
                                    color: "#0f3460"
                                    radius: 6
                                }
                                onTextChanged: groupListModel.build()
                            }

                            Label {
                                visible: selectedGroup !== ""
                                text: selectedGroup
                                color: "#e0e0e0"
                                font.pixelSize: 13
                                font.bold: true
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Label {
                                text: selectedGroup !== ""
                                    ? ChannelListModel.count + " " + qsTr("channels")
                                    : groupListModel.count + " " + qsTr("groups")
                                color: "#a0a0a0"
                                font.pixelSize: 11
                            }
                        }
                    }

                    StackLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        currentIndex: selectedGroup === "" ? 0 : 1

                        // Group list
                        GridView {
                            id: groupsGrid
                            model: groupListModel
                            cellWidth: 200
                            cellHeight: 56
                            clip: true
                            ScrollBar.vertical: ScrollBar {}
                            boundsBehavior: Flickable.StopAtBounds

                            delegate: Rectangle {
                                width: groupsGrid.cellWidth - 12
                                height: groupsGrid.cellHeight - 12
                                x: 6
                                y: 6
                                radius: 8
                                color: mouseArea.containsMouse ? "#0f3460" : "#16213e"

                                property string gName: model.name

                                MouseArea {
                                    id: mouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        selectedGroup = gName
                                        ChannelListModel.filterGroup = gName
                                        ChannelListModel.filterText = ""
                                    }
                                }

                                Label {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: gName
                                    color: "#e0e0e0"
                                    font.pixelSize: 13
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
                                    font.pixelSize: 18
                                }
                            }

                            Label {
                                anchors.centerIn: parent
                                text: qsTr("No groups found")
                                color: "#808080"
                                font.pixelSize: 16
                                visible: parent.count === 0
                            }
                        }

                        // Channels in group
                        ColumnLayout {
                            spacing: 8

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                color: "#16213e"
                                radius: 8

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 8

                                    TextField {
                                        id: groupChannelsSearchField
                                        Layout.fillWidth: true
                                        placeholderText: qsTr("Search in group...")
                                        color: "#e0e0e0"
                                        placeholderTextColor: "#808080"
                                        background: Rectangle {
                                            color: "#0f3460"
                                            radius: 6
                                        }
                                        onTextChanged: {
                                            if (selectedGroup !== "")
                                                ChannelListModel.filterText = text
                                        }
                                    }

                                    Label {
                                        text: ChannelListModel.count + " " + qsTr("channels")
                                        color: "#a0a0a0"
                                        font.pixelSize: 11
                                    }
                                }
                            }

                            GridView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                model: ChannelListModel
                                cellWidth: 158
                                cellHeight: 118
                                clip: true
                                ScrollBar.vertical: ScrollBar {}
                                boundsBehavior: Flickable.StopAtBounds

                                delegate: ChannelDelegate {
                                    channelName: model.name
                                    channelUrl: model.url
                                    channelLogo: model.logo
                                    channelGroup: model.groupName
                                    channelDbId: model.channelId
                                    isFavorite: model.isFavorite
                                    onPlayRequested: (name, url, logo, group) => popup.handlePick(name, url, logo, group)
                                    onFavoriteToggled: (id) => ChannelListModel.toggleFavorite(id)
                                }

                                Label {
                                    anchors.centerIn: parent
                                    text: qsTr("No channels found")
                                    color: "#808080"
                                    font.pixelSize: 16
                                    visible: parent.count === 0
                                }
                            }
                        }
                    }
                }

                // ── Tab 2: Favorites ──
                ColumnLayout {
                    spacing: 8

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        color: "#16213e"
                        radius: 8

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8

                            TextField {
                                id: favoritesSearchField
                                Layout.fillWidth: true
                                placeholderText: qsTr("Search favorites...")
                                color: "#e0e0e0"
                                placeholderTextColor: "#808080"
                                background: Rectangle {
                                    color: "#0f3460"
                                    radius: 6
                                }
                                onTextChanged: favoritesModel.refresh()
                            }

                            Label {
                                text: favoritesModel.count + " " + qsTr("favorites")
                                color: "#a0a0a0"
                                font.pixelSize: 11
                            }
                        }
                    }

                    GridView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        model: favoritesModel
                        cellWidth: 158
                        cellHeight: 118
                        clip: true
                        ScrollBar.vertical: ScrollBar {}
                        boundsBehavior: Flickable.StopAtBounds

                        delegate: ChannelDelegate {
                            channelName: model.name
                            channelUrl: model.url
                            channelLogo: model.logo
                            channelGroup: model.group
                            channelDbId: model.id
                            isFavorite: true
                            onPlayRequested: (name, url, logo, group) => popup.handlePick(name, url, logo, group)
                            onFavoriteToggled: (id) => {
                                DatabaseManager.removeFavorite(id)
                                favoritesModel.refresh()
                            }
                        }

                        Label {
                            anchors.centerIn: parent
                            text: qsTr("No favorites yet")
                            color: "#808080"
                            font.pixelSize: 16
                            visible: parent.count === 0
                        }
                    }
                }
            }
        }
    }

    ListModel {
        id: groupListModel

        function build() {
            clear()
            var groups = ChannelListModel.groups
            var filter = groupsSearchField.text
            for (var i = 0; i < groups.length; i++) {
                if (groups[i] === "") continue
                if (filter === "" || popup.matchesFilter(groups[i], filter))
                    append({ name: groups[i] })
            }
        }
    }

    ListModel {
        id: favoritesModel

        function refresh() {
            clear()
            var favs = DatabaseManager.getFavoritesVariant()
            var filter = favoritesSearchField.text
            for (var i = 0; i < favs.length; i++) {
                if (filter === "" || popup.matchesFilter(favs[i].name, filter))
                    append(favs[i])
            }
        }
    }

    Connections {
        target: tabBar
        function onCurrentIndexChanged() {
            var idx = tabBar.currentIndex
            if (idx === 2)
                favoritesModel.refresh()
            else if (idx === 1 && selectedGroup === "")
                groupListModel.build()
        }
    }

    onClosed: {
        selectedGroup = ""
        ChannelListModel.filterText = ""
        ChannelListModel.filterGroup = ""
    }

    Connections {
        target: ChannelListModel
        function onGroupsChanged() {
            if (tabBar.currentIndex === 1 && selectedGroup === "")
                groupListModel.build()
        }
    }

    Component.onCompleted: {
        groupListModel.build()
    }
}

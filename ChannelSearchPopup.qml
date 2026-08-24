import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

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
        if (channelsSearchBar) channelsSearchBar.searchText = ""
        if (groupSearchBar) groupSearchBar.searchText = ""
        if (groupChannelsBar) groupChannelsBar.searchText = ""
        if (favoritesSearchBar) favoritesSearchBar.searchText = ""
        if (historySearchBar) historySearchBar.searchText = ""
        favoritesModel.refresh()
        historyModel.refresh()
        tabBar.currentIndex = 0
        groupListModel.build()
        if (channelsSearchBar) channelsSearchBar.focusSearch()
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
                    text: popup.pickMode ? popup.pickLabel : qsTr("Browse Channels")
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

                TabButton { text: qsTr("Favorites") }
                TabButton { text: qsTr("All Channels") }
                TabButton { text: qsTr("Groups") }
                TabButton { text: qsTr("History") }
            }

            // ── Content ──
            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: tabBar.currentIndex

                // ── Tab 0: Favorites ──
                ColumnLayout {
                    spacing: 8

                    ChannelSearchBar {
                        id: favoritesSearchBar
                        searchPlaceholder: qsTr("Search favorites...")
                        countText: favoritesModel.count + " " + qsTr("favorites")
                        onSearchChanged: favoritesModel.refresh()
                    }

                    ChannelGrid {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        isFavoritesModel: true
                        model: favoritesModel
                        onPlayRequested: (name, url, logo, group) => popup.handlePick(name, url, logo, group)
                        onFavoriteToggled: (id) => {
                            DatabaseManager.removeFavorite(id)
                            favoritesModel.refresh()
                        }
                    }
                }

                // ── Tab 1: All Channels ──
                ColumnLayout {
                    spacing: 8

                    ChannelSearchBar {
                        id: channelsSearchBar
                        searchPlaceholder: qsTr("Search channels...")
                        countText: ChannelListModel.count + " " + qsTr("channels")
                        onSearchChanged: function(text) {
                            if (tabBar.currentIndex === 1)
                                ChannelListModel.filterText = text
                        }
                    }

                    ChannelGrid {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        model: ChannelListModel
                        onPlayRequested: (name, url, logo, group) => popup.handlePick(name, url, logo, group)
                        onFavoriteToggled: (id) => ChannelListModel.toggleFavorite(id)
                    }
                }

                // ── Tab 2: Groups ──
                ColumnLayout {
                    spacing: 8

                    GroupSearchBar {
                        id: groupSearchBar
                        drillMode: popup.selectedGroup !== ""
                        groupName: popup.selectedGroup
                        countText: popup.selectedGroup !== ""
                            ? ChannelListModel.count + " " + qsTr("channels")
                            : groupListModel.count + " " + qsTr("groups")
                        onBackRequested: {
                            popup.selectedGroup = ""
                            ChannelListModel.filterGroup = ""
                            ChannelListModel.filterText = ""
                        }
                        onSearchChanged: groupListModel.build()
                    }

                    StackLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        currentIndex: popup.selectedGroup === "" ? 0 : 1

                        GroupGrid {
                            model: groupListModel
                            onGroupSelected: (gName) => {
                                popup.selectedGroup = gName
                                ChannelListModel.filterGroup = gName
                                ChannelListModel.filterText = ""
                            }
                        }

                        ColumnLayout {
                            spacing: 8

                            ChannelSearchBar {
                                id: groupChannelsBar
                                searchPlaceholder: qsTr("Search in group...")
                                countText: ""
                                onSearchChanged: function(text) {
                                    if (popup.selectedGroup !== "")
                                        ChannelListModel.filterText = text
                                }
                            }

                            ChannelGrid {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                model: ChannelListModel
                                onPlayRequested: (name, url, logo, group) => popup.handlePick(name, url, logo, group)
                                onFavoriteToggled: (id) => ChannelListModel.toggleFavorite(id)
                            }
                        }
                    }
                }

                // ── Tab 3: History ──
                ColumnLayout {
                    spacing: 8

                    ChannelSearchBar {
                        id: historySearchBar
                        searchPlaceholder: qsTr("Search history...")
                        countText: historyModel.count + " " + qsTr("channels")
                        onSearchChanged: historyModel.refresh()
                    }

                    ChannelGrid {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        isHistoryModel: true
                        model: historyModel
                        onPlayRequested: (name, url, logo, group) => popup.handlePick(name, url, logo, group)
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
            var filter = groupSearchBar.searchText
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
            var filter = favoritesSearchBar.searchText
            for (var i = 0; i < favs.length; i++) {
                if (filter === "" || popup.matchesFilter(favs[i].name, filter))
                    append(favs[i])
            }
        }
    }

    ListModel {
        id: historyModel

        function refresh() {
            clear()
            var entries = DatabaseManager.getHistoryVariant()
            var filter = historySearchBar.searchText
            for (var i = 0; i < entries.length; i++) {
                if (filter === "" || popup.matchesFilter(entries[i].name, filter))
                    append(entries[i])
            }
        }
    }

    Connections {
        target: tabBar
        function onCurrentIndexChanged() {
            var idx = tabBar.currentIndex
            if (idx === 0)
                favoritesModel.refresh()
            else if (idx === 2 && popup.selectedGroup === "")
                groupListModel.build()
            else if (idx === 3)
                historyModel.refresh()
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
            if (tabBar.currentIndex === 2 && popup.selectedGroup === "")
                groupListModel.build()
        }
    }

    Connections {
        target: DatabaseManager
        function onHistoryChanged() {
            if (tabBar.currentIndex === 3)
                historyModel.refresh()
        }
    }

    Component.onCompleted: {
        groupListModel.build()
    }
}

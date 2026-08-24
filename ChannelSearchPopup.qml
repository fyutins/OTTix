import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: popup
    modal: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    parent: Overlay.overlay
    anchors.centerIn: Overlay.overlay
    width: Math.min(popup.parent ? popup.parent.width - Theme.spacingXl * 2 : 860, 900)
    height: Math.min(popup.parent ? popup.parent.height - Theme.spacingXl * 2 : 620, 660)
    padding: 0

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

    Overlay.modal: Rectangle {
        color: Qt.rgba(0, 0, 0, 0.6)
    }

    background: Rectangle {
        color: Theme.bg
        radius: Theme.radiusLg
        border.width: 1
        border.color: Theme.border
    }

    contentItem: ColumnLayout {
        spacing: 0

        // ── En-tete ──
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.toolbarHeight
            color: Theme.surface
            topLeftRadius: Theme.radiusLg
            topRightRadius: Theme.radiusLg

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.spacingMd
                anchors.rightMargin: Theme.spacingSm
                spacing: Theme.spacingSm

                MdiIcon {
                    glyph: popup.pickMode ? Mdi.plusCircle : Mdi.magnify
                    font.pixelSize: Theme.iconMd
                    color: popup.pickMode ? Theme.accent : Theme.textMuted
                }

                Label {
                    text: popup.pickMode ? popup.pickLabel : qsTr("Browse Channels")
                    color: Theme.text
                    font.pixelSize: Theme.fontLg
                    font.bold: true
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                IconButton {
                    glyph: Mdi.close
                    glyphColor: Theme.textMuted
                    tooltip: qsTr("Close (Esc)")
                    onClicked: popup.close()
                }
            }
        }

        // ── Onglets ──
        AppTabBar {
            id: tabBar
            Layout.fillWidth: true

            AppTabButton { text: qsTr("Favorites"); glyph: Mdi.star }
            AppTabButton { text: qsTr("All Channels"); glyph: Mdi.television }
            AppTabButton { text: qsTr("Groups"); glyph: Mdi.folderMultiple }
            AppTabButton { text: qsTr("History"); glyph: Mdi.history }
        }

        // ── Contenu ──
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: Theme.spacingMd
            currentIndex: tabBar.currentIndex

            // ── Tab 0: Favorites ──
            ColumnLayout {
                spacing: Theme.spacingSm

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
                spacing: Theme.spacingSm

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
                spacing: Theme.spacingSm

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
                        spacing: Theme.spacingSm

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
                spacing: Theme.spacingSm

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

    ListModel {
        id: groupListModel

        function build() {
            clear()
            var groups = ChannelListModel.groups
            var filter = groupSearchBar.searchText
            for (var i = 0; i < groups.length; i++) {
                if (groups[i] === "") continue
                if (filter === "" || ChannelListModel.matchesFilter(groups[i], filter))
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
                if (filter === "" || ChannelListModel.matchesFilter(favs[i].name, filter))
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
                if (filter === "" || ChannelListModel.matchesFilter(entries[i].name, filter))
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

    Component.onCompleted: {
        groupListModel.build()
    }
}

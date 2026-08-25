import QtQuick
import QtQuick.Layouts

Item {
    id: root

    signal channelSelected(string name, string url, string logo, string group)

    property string currentGroup: ""
    property string groupFilterText: ""
    property string channelFilterText: ""

    // Re-applies this page's filter on the shared model (see
    // ChannelListPage.activate()).
    function activate() {
        ChannelListModel.filterGroup = currentGroup
        ChannelListModel.filterText = currentGroup !== "" ? channelFilterText : ""
    }

    function focusSearch() {
        if (currentGroup === "")
            groupBar.focusSearch()
        else
            groupChannelsBar.focusSearch()
    }

    function backToGroups() {
        currentGroup = ""
        groupFilterText = ""
        channelFilterText = ""
        activate()
    }

    function openGroup(group) {
        currentGroup = group
        groupFilterText = ""
        channelFilterText = ""
        activate()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingMd
        spacing: Theme.spacingSm

        GroupSearchBar {
            id: groupBar
            drillMode: root.currentGroup !== ""
            groupName: root.currentGroup
            countText: root.currentGroup !== ""
                ? ChannelListModel.count + " " + qsTr("channels")
                : groupListModel.count + " " + qsTr("groups")
            onBackRequested: root.backToGroups()
            onSearchChanged: function(text) {
                root.groupFilterText = text
                groupListModel.build()
            }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: root.currentGroup === "" ? 0 : 1

            GroupGrid {
                id: groupsGrid
                model: groupListModel
                onGroupSelected: (groupName) => root.openGroup(groupName)
            }

            ColumnLayout {
                spacing: Theme.spacingSm

                ChannelSearchBar {
                    id: groupChannelsBar
                    visible: root.currentGroup !== ""
                    searchPlaceholder: qsTr("Search in group...")
                    countText: ""
                    onSearchChanged: function(text) {
                        if (root.currentGroup !== "") {
                            root.channelFilterText = text
                            ChannelListModel.filterText = text
                        }
                    }
                }

                ChannelGrid {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: ChannelListModel
                    onPlayRequested: (name, url, logo, group) => root.channelSelected(name, url, logo, group)
                    onFavoriteToggled: (id) => ChannelListModel.toggleFavorite(id)
                }
            }
        }
    }

    ListModel {
        id: groupListModel

        function build() {
            clear()
            var groups = ChannelListModel.groups
            for (var i = 0; i < groups.length; i++) {
                if (groups[i] === "") continue
                if (ChannelListModel.matchesFilter(groups[i], root.groupFilterText))
                    append({ name: groups[i] })
            }
        }
    }

    Connections {
        target: ChannelListModel
        function onGroupsChanged() {
            groupListModel.build()
        }
    }

    Component.onCompleted: groupListModel.build()
}

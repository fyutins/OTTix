import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import IptvPlayer.Models

Rectangle {
    id: root
    color: "transparent"

    signal channelSelected(string name, string url, string logo, string group)

    property string currentGroup: ""
    property string groupFilterText: ""

    function backToGroups() {
        currentGroup = ""
        groupFilterText = ""
        ChannelListModel.filterGroup = ""
        ChannelListModel.filterText = ""
    }

    function openGroup(group) {
        currentGroup = group
        groupFilterText = ""
        ChannelListModel.filterGroup = group
        ChannelListModel.filterText = ""
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

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        GroupSearchBar {
            id: groupBar
            drillMode: currentGroup !== ""
            groupName: currentGroup
            countText: currentGroup !== ""
                ? ChannelListModel.count + " " + qsTr("channels")
                : groupListModel.count + " " + qsTr("groups")
            onBackRequested: backToGroups()
            onSearchChanged: {
                groupFilterText = text
                groupListModel.build()
            }
        }

        Item { Layout.preferredHeight: 8 }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: currentGroup === "" ? 0 : 1

            GroupGrid {
                id: groupsGrid
                model: groupListModel
                onGroupSelected: (groupName) => openGroup(groupName)
            }

            ColumnLayout {
                spacing: 8

                ChannelSearchBar {
                    visible: currentGroup !== ""
                    searchPlaceholder: qsTr("Search in group...")
                    countText: ""
                    onSearchChanged: {
                        if (currentGroup !== "")
                            ChannelListModel.filterText = text
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
                if (root.matchesFilter(groups[i], root.groupFilterText))
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

    Component.onCompleted: {
        groupListModel.build()
        ChannelListModel.filterGroup = ""
        ChannelListModel.filterText = ""
    }
}

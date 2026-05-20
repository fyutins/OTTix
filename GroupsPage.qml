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

        // Header: search bar when listing groups, back button when drilling in
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            color: "#16213e"
            radius: 8

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8

                Button {
                    text: "\u2190"
                    flat: true
                    implicitWidth: 32
                    implicitHeight: 32
                    visible: currentGroup !== ""
                    contentItem: Text {
                        text: "\u2190"
                        color: "#4a90d9"
                        font.pixelSize: 18
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: "transparent"
                        radius: 4
                    }
                    onClicked: backToGroups()
                }

                TextField {
                    id: searchField
                    visible: currentGroup === ""
                    Layout.fillWidth: true
                    placeholderText: qsTr("Search groups...")
                    color: "#e0e0e0"
                    placeholderTextColor: "#808080"
                    background: Rectangle {
                        color: "#0f3460"
                        radius: 6
                    }
                    onTextChanged: {
                        groupFilterText = text
                        groupListModel.build()
                    }
                }

                Label {
                    visible: currentGroup !== ""
                    text: currentGroup
                    color: "#e0e0e0"
                    font.pixelSize: 16
                    font.bold: true
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Label {
                    text: currentGroup !== ""
                        ? ChannelListModel.count + " " + qsTr("channels")
                        : groupListModel.count + " " + qsTr("groups")
                    color: "#a0a0a0"
                    font.pixelSize: 12
                }
            }
        }

        Item { Layout.preferredHeight: 8 }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: currentGroup === "" ? 0 : 1

            GridView {
                id: groupsGrid
                model: groupListModel
                cellWidth: 200
                cellHeight: 70
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

                    property string groupName: model.name

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: openGroup(groupName)
                    }

                    Label {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: groupName
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
                    visible: groupsGrid.count === 0
                }
            }

            GridView {
                id: channelGridView
                model: ChannelListModel
                cellWidth: 158
                cellHeight: 118
                delegate: ChannelDelegate {
                    channelName: model.name
                    channelUrl: model.url
                    channelLogo: model.logo
                    channelGroup: model.groupName
                    channelDbId: model.channelId
                    isFavorite: model.isFavorite
                    onPlayRequested: (name, url, logo, group) => root.channelSelected(name, url, logo, group)
                    onFavoriteToggled: (id) => ChannelListModel.toggleFavorite(id)
                }
                clip: true
                ScrollBar.vertical: ScrollBar {}
                boundsBehavior: Flickable.StopAtBounds
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

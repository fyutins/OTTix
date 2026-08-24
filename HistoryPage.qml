import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    color: "transparent"

    signal channelSelected(string name, string url, string logo, string group)

    property string filterText: ""

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

        ChannelSearchBar {
            id: searchBar
            searchPlaceholder: qsTr("Search history...")
            countText: displayCount + " " + qsTr("channels")
            onSearchChanged: {
                filterText = text
                refresh()
            }
        }

        Item { Layout.preferredHeight: 8 }

        ChannelGrid {
            id: historyGrid
            Layout.fillWidth: true
            Layout.fillHeight: true
            isHistoryModel: true
            model: listModel
            onPlayRequested: (name, url, logo, group) => root.channelSelected(name, url, logo, group)
        }
    }

    property int displayCount: 0

    ListModel { id: listModel }

    function refresh() {
        listModel.clear()
        var count = 0
        var entries = DatabaseManager.getHistoryVariant()
        for (var i = 0; i < entries.length; i++) {
            if (root.matchesFilter(entries[i].name, root.filterText)) {
                listModel.append(entries[i])
                count++
            }
        }
        displayCount = count
    }

    Component.onCompleted: {
        refresh()
        DatabaseManager.historyChanged.connect(refresh)
    }
}

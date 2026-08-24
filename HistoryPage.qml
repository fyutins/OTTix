import QtQuick
import QtQuick.Layouts

Item {
    id: root

    signal channelSelected(string name, string url, string logo, string group)

    property string filterText: ""
    property int displayCount: 0

    function focusSearch() { searchBar.focusSearch() }

    function refresh() {
        listModel.clear()
        var count = 0
        var entries = DatabaseManager.getHistoryVariant()
        for (var i = 0; i < entries.length; i++) {
            if (ChannelListModel.matchesFilter(entries[i].name, root.filterText)) {
                listModel.append(entries[i])
                count++
            }
        }
        displayCount = count
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingMd
        spacing: Theme.spacingSm

        ChannelSearchBar {
            id: searchBar
            searchPlaceholder: qsTr("Search history...")
            countText: root.displayCount + " " + qsTr("channels")
            onSearchChanged: function(text) {
                root.filterText = text
                root.refresh()
            }
        }

        ChannelGrid {
            id: historyGrid
            Layout.fillWidth: true
            Layout.fillHeight: true
            isHistoryModel: true
            model: listModel
            onPlayRequested: (name, url, logo, group) => root.channelSelected(name, url, logo, group)
        }
    }

    ListModel { id: listModel }

    Component.onCompleted: {
        refresh()
        DatabaseManager.historyChanged.connect(refresh)
    }
}

pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    color: "#1a1a2e"

    signal backRequested()

    PlaylistLoader {
        id: loader
        onLoadComplete: (playlistId, channelCount) => {
            ChannelListModel.setChannels(playlistId)
        }
        onLoadError: (playlistId, error) => {
            console.log("Playlist load error:", error)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            color: "#16213e"

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8

                Button {
                    text: "\u2190"
                    flat: true
                    implicitWidth: 32
                    implicitHeight: 32
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
                    onClicked: root.backRequested()
                }

                Label {
                    text: qsTr("Administration")
                    color: "#e0e0e0"
                    font.pixelSize: 16
                    font.bold: true
                }

                Item { Layout.fillWidth: true }
            }
        }

        // Tabs
        TabBar {
            id: adminTabBar
            Layout.fillWidth: true

            TabButton { text: qsTr("Playlists") }
            TabButton { text: qsTr("Settings") }
        }

        // Content
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: adminTabBar.currentIndex

            // ── Playlists tab ──
            Item {
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true

                        Button {
                            text: qsTr("Add Playlist")
                            onClicked: playlistDialog.open()
                        }

                        Item { Layout.fillWidth: true }
                    }

                    ListView {
                        id: playlistView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        model: PlaylistModel
                        delegate: playlistDelegate
                        clip: true

                        ScrollBar.vertical: ScrollBar {}

                        Label {
                            anchors.centerIn: parent
                            text: qsTr("No playlists yet")
                            color: "#808080"
                            font.pixelSize: 16
                            visible: playlistView.count === 0
                        }
                    }

                    Component {
                        id: playlistDelegate

                        Rectangle {
                            id: playlistRow

                            required property var model

                            width: ListView.view.width
                            height: 60
                            color: "#16213e"
                            border.color: "#0f3460"
                            radius: 8

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 12

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4

                                    Label {
                                        text: playlistRow.model.name
                                        color: "#e0e0e0"
                                        font.pixelSize: 16
                                        font.bold: true
                                    }

                                    Label {
                                        text: playlistRow.model.type + " \u00B7 " + playlistRow.model.channelCount + " " + qsTr("channels")
                                        color: "#a0a0a0"
                                        font.pixelSize: 12
                                    }
                                }

                                Button {
                                    text: qsTr("Load")
                                    onClicked: {
                                        if (playlistRow.model.type === "m3u")
                                            loader.loadM3U(playlistRow.model.playlistId, playlistRow.model.url)
                                        else if (playlistRow.model.type === "xtream")
                                            loader.loadXtream(playlistRow.model.playlistId, playlistRow.model.url,
                                                               playlistRow.model.username, playlistRow.model.password)
                                    }
                                }

                                Button {
                                    text: qsTr("Edit")
                                    onClicked: {
                                        playlistDialog.openForEdit(playlistRow.model.playlistId,
                                            playlistRow.model.name, playlistRow.model.url, playlistRow.model.type,
                                            playlistRow.model.username, playlistRow.model.password)
                                    }
                                }

                                Button {
                                    text: qsTr("Delete")
                                    onClicked: {
                                        PlaylistModel.removePlaylist(playlistRow.model.playlistId)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── Settings tab ──
            Flickable {
                contentHeight: settingsColumn.height
                clip: true
                ScrollBar.vertical: ScrollBar {}

                ColumnLayout {
                    id: settingsColumn
                    width: parent.width
                    anchors.margins: 24
                    spacing: 16

                    GroupBox {
                        id: dbGroup
                        title: qsTr("Database")
                        Layout.fillWidth: true
                        label: Label {
                            text: dbGroup.title
                            color: "#e0e0e0"
                            font.bold: true
                        }

                        ColumnLayout {
                            width: parent.width
                            spacing: 12

                            Button {
                                text: qsTr("Clear Cache")
                                onClicked: {
                                    DatabaseManager.clearCache(0)
                                }
                            }

                            Label {
                                text: qsTr("Database location: ") + DatabaseManager.databasePath
                                color: "#808080"
                                font.pixelSize: 11
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }
                    }

                    GroupBox {
                        id: suffixGroup
                        title: qsTr("Quality Suffixes")
                        Layout.fillWidth: true
                        label: Label {
                            text: suffixGroup.title
                            color: "#e0e0e0"
                            font.bold: true
                        }

                        ColumnLayout {
                            width: parent.width
                            spacing: 8

                            Text {
                                text: qsTr("Custom quality suffixes used to group channel variants (HD, FHD, SD...)")
                                color: "#808080"
                                font.pixelSize: 11
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }

                            ListView {
                                id: suffixListView
                                Layout.fillWidth: true
                                Layout.preferredHeight: Math.min(contentHeight, 200)
                                interactive: contentHeight > 200
                                clip: true
                                model: suffixListModel
                                visible: suffixListModel.count > 0

                                delegate: Rectangle {
                                    id: suffixRow

                                    required property string suffix
                                    required property int index

                                    width: suffixListView.width
                                    height: 28
                                    color: "transparent"
                                    radius: 4

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 4
                                        spacing: 8

                                        Text {
                                            text: suffixRow.suffix
                                            color: "#e0e0e0"
                                            font.pixelSize: 12
                                            font.bold: true
                                            Layout.fillWidth: true
                                        }

                                        Button {
                                            text: qsTr("×")
                                            flat: true
                                            implicitWidth: 24
                                            implicitHeight: 24
                                            contentItem: Text {
                                                text: qsTr("×")
                                                color: "#e57373"
                                                font.pixelSize: 14
                                                horizontalAlignment: Text.AlignHCenter
                                                verticalAlignment: Text.AlignVCenter
                                            }
                                            background: Rectangle {
                                                color: mouseArea.containsMouse ? Qt.rgba(1,0,0,0.2) : "transparent"
                                                radius: 4
                                            }
                                            MouseArea {
                                                id: mouseArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    var arr = ChannelListModel.customSuffixes
                                                    arr.splice(suffixRow.index, 1)
                                                    ChannelListModel.customSuffixes = arr
                                                    suffixGroup.refreshSuffixList()
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Text {
                                text: qsTr("No custom suffixes added")
                                color: "#808080"
                                font.pixelSize: 11
                                visible: suffixListModel.count === 0
                            }

                            RowLayout {
                                spacing: 8

                                TextField {
                                    id: suffixInput
                                    Layout.fillWidth: true
                                    placeholderText: qsTr("e.g. HQ, LQ, 4K")
                                    color: "#e0e0e0"
                                    font.pixelSize: 12
                                    background: Rectangle {
                                        color: "#16213e"
                                        radius: 4
                                        border.color: suffixInput.activeFocus ? "#4a90d9" : "#0f3460"
                                        border.width: 1
                                    }
                                    onAccepted: suffixGroup.addSuffix()
                                }

                                Button {
                                    text: qsTr("Add")
                                    enabled: suffixInput.text.trim().length > 0
                                    onClicked: suffixGroup.addSuffix()
                                }
                            }

                            Item { Layout.preferredHeight: 4 }
                        }

                        function addSuffix() {
                            var val = suffixInput.text.trim()
                            if (val.length === 0) return
                            var arr = ChannelListModel.customSuffixes
                            if (arr.indexOf(val) < 0) {
                                arr.push(val)
                                ChannelListModel.customSuffixes = arr
                            }
                            suffixInput.text = ""
                            suffixGroup.refreshSuffixList()
                        }

                        function refreshSuffixList() {
                            suffixListModel.clear()
                            var arr = ChannelListModel.customSuffixes
                            for (var i = 0; i < arr.length; i++)
                                suffixListModel.append({ suffix: arr[i] })
                        }

                        ListModel { id: suffixListModel }

                        Component.onCompleted: suffixGroup.refreshSuffixList()
                    }

                    GroupBox {
                        id: aboutGroup
                        title: qsTr("About")
                        Layout.fillWidth: true
                        label: Label {
                            text: aboutGroup.title
                            color: "#e0e0e0"
                            font.bold: true
                        }

                        ColumnLayout {
                            width: parent.width
                            spacing: 8

                            Label {
                                text: qsTr("IPTV Player v0.1")
                                color: "#e0e0e0"
                            }

                            Label {
                                text: qsTr("Supports M3U playlists and XTREAM API")
                                color: "#a0a0a0"
                            }
                        }
                    }

                    Item { Layout.preferredHeight: 24 }
                }
            }
        }
    }

    PlaylistDialog {
        id: playlistDialog
        onPlaylistAdded: (name, url, type, username, password) => {
            PlaylistModel.addPlaylist(name, url, type, username, password)
        }
        onPlaylistEdited: (id, name, url, type, username, password) => {
            PlaylistModel.updatePlaylist(id, name, url, type, username, password)
        }
    }

    Component.onCompleted: {
        PlaylistModel.refresh()
    }
}

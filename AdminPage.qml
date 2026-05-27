import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import IptvPlayer.Models
import IptvPlayer.Loader
import IptvPlayer.Database

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
                                        text: model.name
                                        color: "#e0e0e0"
                                        font.pixelSize: 16
                                        font.bold: true
                                    }

                                    Label {
                                        text: model.type + " \u00B7 " + model.channelCount + " " + qsTr("channels")
                                        color: "#a0a0a0"
                                        font.pixelSize: 12
                                    }
                                }

                                Button {
                                    text: qsTr("Load")
                                    onClicked: {
                                        if (model.type === "m3u")
                                            loader.loadM3U(model.playlistId, model.url)
                                        else if (model.type === "xtream")
                                            loader.loadXtream(model.playlistId, model.url,
                                                               model.username, model.password)
                                    }
                                }

                                Button {
                                    text: qsTr("Edit")
                                    onClicked: {
                                        playlistDialog.openForEdit(model.playlistId,
                                            model.name, model.url, model.type,
                                            model.username, model.password)
                                    }
                                }

                                Button {
                                    text: qsTr("Delete")
                                    onClicked: {
                                        PlaylistModel.removePlaylist(model.playlistId)
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
                        title: qsTr("Database")
                        Layout.fillWidth: true
                        label: Label {
                            text: parent.title
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
                        title: qsTr("About")
                        Layout.fillWidth: true
                        label: Label {
                            text: parent.title
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

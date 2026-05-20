import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import IptvPlayer.Player
import IptvPlayer.Models
import IptvPlayer.Loader

Window {
    id: window
    width: 1280
    height: 720
    visible: true
    title: qsTr("IPTV Player")

    property bool isFullScreen: false
    property bool showPlayer: false
    property bool showAdmin: false

    property int multiplexMode: 1
    property int activeAudioSlot: 0
    property int pendingPickSlot: -1
    property var slotChannels: [
        { name: "", url: "", logo: "", group: "" },
        { name: "", url: "", logo: "", group: "" },
        { name: "", url: "", logo: "", group: "" },
        { name: "", url: "", logo: "", group: "" }
    ]

    function setSlotChannel(index, name, url, logo, group) {
        var arr = slotChannels.slice()
        arr[index] = { name: name, url: url, logo: logo || "", group: group || "" }
        slotChannels = arr
    }

    function handleChannelSelected(name, url, logo, group) {
        var slot = pendingPickSlot >= 0 ? pendingPickSlot : 0
        var isPick = pendingPickSlot >= 0
        pendingPickSlot = -1

        // Clear first to force reload even if same URL
        var empty = { name: "", url: "", logo: "", group: "" }
        var ch = slotChannels.slice()
        ch[slot] = empty
        slotChannels = ch

        // Set the new channel
        ch = slotChannels.slice()
        ch[slot] = { name: name, url: url, logo: logo, group: group }
        slotChannels = ch

        if (!showPlayer)
            showPlayer = true
        if (multiplexMode === 1 || !isPick)
            activeAudioSlot = slot
    }

    function stopPlayback() {
        showPlayer = false
        pendingPickSlot = -1
        var empty = { name: "", url: "", logo: "", group: "" }
        var ch = []
        for (var i = 0; i < 4; i++) ch.push(empty)
        slotChannels = ch
    }

    function openChannelSearch() {
        channelSearchPopup.pickMode = pendingPickSlot >= 0
        if (pendingPickSlot >= 0)
            channelSearchPopup.pickLabel = qsTr("Select a channel for Player %1").arg(pendingPickSlot + 1)
        else
            channelSearchPopup.pickLabel = ""
        channelSearchPopup.openPicker()
    }

    PlaylistLoader {
        id: loader
        onLoadComplete: (playlistId, channelCount) => {
            ChannelListModel.setChannels(playlistId)
            tabBar.currentIndex = 0
        }
        onLoadError: (playlistId, error) => {
            console.log("Playlist load error:", error)
        }
    }

    Shortcut {
        sequence: "F11"
        onActivated: {
            if (window.visibility === Window.FullScreen) {
                window.visibility = Window.Windowed
                isFullScreen = false
            } else {
                window.visibility = Window.FullScreen
                isFullScreen = true
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: {
            if (pendingPickSlot >= 0) {
                pendingPickSlot = -1
            } else if (window.visibility === Window.FullScreen) {
                window.visibility = Window.Windowed
                isFullScreen = false
            }
        }
    }

    Shortcut {
        sequence: "Space"
        onActivated: {
            if (showPlayer && playerPage.activeSlotItem) {
                var p = playerPage.activeSlotItem
                if (p.mpvPlaying)
                    p.doPause()
                else
                    p.doPlay()
            }
        }
    }

    // ── Navigation layer ──
    Rectangle {
        anchors.fill: parent
        color: "#1a1a2e"
        visible: !showPlayer

        StackLayout {
            anchors.fill: parent
            currentIndex: showAdmin ? 1 : 0

            // Page 0: Main navigation
            ColumnLayout {
                spacing: 0

                // Toolbar
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    color: "#16213e"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 8

                        Label {
                            text: qsTr("IPTV Player")
                            color: "#e0e0e0"
                            font.pixelSize: 16
                            font.bold: true
                        }

                        Item { Layout.fillWidth: true }

                        Button {
                            text: "\u2699"
                            flat: true
                            implicitWidth: 36
                            implicitHeight: 36
                            contentItem: Text {
                                text: "\u2699"
                                color: "#e0e0e0"
                                font.pixelSize: 20
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle {
                                radius: 6
                                color: adminBtnMouse.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
                            }
                            MouseArea {
                                id: adminBtnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: showAdmin = true
                            }
                        }
                    }
                }

                // Pick mode banner
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: pendingPickSlot >= 0 ? 40 : 0
                    visible: pendingPickSlot >= 0
                    color: "#0f3460"
                    clip: true

                    Behavior on Layout.preferredHeight {
                        NumberAnimation { duration: 200 }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 8

                        Label {
                            text: qsTr("Select a channel for Player %1").arg(pendingPickSlot + 1)
                            color: "white"
                            font.pixelSize: 13
                            font.bold: true
                            Layout.fillWidth: true
                        }

                        Button {
                            text: qsTr("Cancel")
                            flat: true
                            contentItem: Text {
                                text: qsTr("Cancel")
                                color: "#4a90d9"
                                font.pixelSize: 12
                            }
                            background: Rectangle {
                                color: "transparent"
                                border.color: "#4a90d9"
                                border.width: 1
                                radius: 4
                            }
                            onClicked: pendingPickSlot = -1
                        }
                    }
                }

                // Tab bar
                TabBar {
                    id: tabBar
                    Layout.fillWidth: true

                    TabButton { text: qsTr("All Channels") }
                    TabButton { text: qsTr("Groups") }
                    TabButton { text: qsTr("Favorites") }
                }

                // Content
                StackLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: tabBar.currentIndex

                    ChannelListPage {
                        onChannelSelected: (name, url, logo, group) => handleChannelSelected(name, url, logo, group)
                    }

                    GroupsPage {
                        onChannelSelected: (name, url, logo, group) => handleChannelSelected(name, url, logo, group)
                    }

                    FavoritesPage {
                        onChannelSelected: (name, url, logo, group) => handleChannelSelected(name, url, logo, group)
                    }
                }
            }

            // Page 1: Admin page
            AdminDialog {
                onBackRequested: showAdmin = false
            }
        }
    }

    // ── Player layer ──
    PlayerPage {
        id: playerPage
        anchors.fill: parent
        visible: showPlayer

        multiplexMode: window.multiplexMode
        activeAudioSlot: window.activeAudioSlot
        pendingPickSlot: window.pendingPickSlot
        slotChannels: window.slotChannels

        onMultiplexModeChangeRequested: (mode) => {
            window.multiplexMode = mode
            var empty = { name: "", url: "", logo: "", group: "" }
            var ch = window.slotChannels.slice()
            for (var i = mode; i < 4; i++)
                ch[i] = empty
            window.slotChannels = ch
        }
        onActiveAudioSlotChangeRequested: (slot) => { window.activeAudioSlot = slot }
        onPendingPickSlotChangeRequested: (slot) => { window.pendingPickSlot = slot }

        onCloseRequested: stopPlayback()
        onNavigateRequested: openChannelSearch()
        onToggleFullscreenRequested: {
            if (window.visibility === Window.FullScreen) {
                window.visibility = Window.Windowed
                isFullScreen = false
            } else {
                window.visibility = Window.FullScreen
                isFullScreen = true
            }
        }
    }

    // ── Channel search popup ──
    ChannelSearchPopup {
        id: channelSearchPopup
        onChannelSelected: (name, url, logo, group) => handleChannelSelected(name, url, logo, group)
    }

    // ── Initial load ──
    Component.onCompleted: {
        PlaylistModel.refresh()

        if (PlaylistModel.count > 0) {
            var first = PlaylistModel.get(0)
            if (first) {
                if (first.type === "xtream")
                    loader.loadXtream(first.id, first.url, first.username, first.password)
                else
                    loader.loadM3U(first.id, first.url)
            }
        }
    }
}

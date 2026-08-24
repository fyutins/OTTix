import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Window {
    id: window
    width: 1280
    height: 720
    visible: true
    title: qsTr("IPTV Player")

    property bool isFullScreen: false
    property bool showPlayer: false
    property bool showAdmin: false

    property int activePlaylistId: -1
    property bool refreshing: false

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

        // Record in watch history
        DatabaseManager.addHistoryEntry(name, url, logo, group)

        SleepInhibitor.enable()
    }

    function stopPlayback() {
        showPlayer = false
        pendingPickSlot = -1
        var empty = { name: "", url: "", logo: "", group: "" }
        var ch = []
        for (var i = 0; i < 4; i++) ch.push(empty)
        slotChannels = ch
        SleepInhibitor.disable()
    }

    function navigateChannel(direction) {
        var url = slotChannels[activeAudioSlot].url
        if (!url) return

        var next = ChannelListModel.channelAfter(url, direction)
        if (!next || !next.url) return

        handleChannelSelected(next.name, next.url, next.logo, next.group)
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
            window.refreshing = false
            ChannelListModel.setChannels(playlistId)
        }
        onLoadError: (playlistId, error) => {
            window.refreshing = false
            // Les chaines deja en base restent affichees : un refresh rate
            // n'est pas bloquant.
            console.warn("Playlist refresh failed:", error)
        }
    }

    // Recharge une playlist depuis le reseau. Les chaines de la base restent
    // affichees pendant l'operation.
    function refreshPlaylist(playlist) {
        if (!playlist || refreshing)
            return
        refreshing = true
        if (playlist.type === "xtream")
            loader.loadXtream(playlist.id, playlist.url, playlist.username, playlist.password)
        else
            loader.loadM3U(playlist.id, playlist.url)
    }

    function refreshActivePlaylist() {
        if (activePlaylistId < 0)
            return
        for (var i = 0; i < PlaylistModel.count; i++) {
            var pl = PlaylistModel.get(i)
            if (pl && pl.id === activePlaylistId) {
                refreshPlaylist(pl)
                return
            }
        }
    }

    Shortcut {
        sequence: "F11"
        onActivated: {
            if (window.visibility === Window.FullScreen) {
                window.visibility = Window.Windowed
                window.isFullScreen = false
            } else {
                window.visibility = Window.FullScreen
                window.isFullScreen = true
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: {
            if (window.pendingPickSlot >= 0) {
                window.pendingPickSlot = -1
            } else if (window.visibility === Window.FullScreen) {
                window.visibility = Window.Windowed
                window.isFullScreen = false
            }
        }
    }

    Shortcut {
        sequence: "Space"
        onActivated: {
            if (window.showPlayer && playerPage.activeSlotItem) {
                var p = playerPage.activeSlotItem
                if (p.mpvPlaying)
                    p.doPause()
                else
                    p.doPlay()
            }
        }
    }

    Shortcut {
        sequence: "Left"
        onActivated: { if (window.showPlayer) window.navigateChannel(-1) }
    }

    Shortcut {
        sequence: "Right"
        onActivated: { if (window.showPlayer) window.navigateChannel(1) }
    }

    // ── Navigation layer ──
    Rectangle {
        anchors.fill: parent
        color: "#1a1a2e"
        visible: !window.showPlayer

        StackLayout {
            anchors.fill: parent
            currentIndex: window.showAdmin ? 1 : 0

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

                        Label {
                            text: qsTr("Updating\u2026")
                            color: "#a0a0a0"
                            font.pixelSize: 12
                            visible: window.refreshing
                        }

                        Button {
                            text: "\u21BB"
                            flat: true
                            enabled: !window.refreshing && window.activePlaylistId >= 0
                            implicitWidth: 36
                            implicitHeight: 36
                            contentItem: Text {
                                text: "\u21BB"
                                color: parent.enabled ? "#e0e0e0" : "#606060"
                                font.pixelSize: 18
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle {
                                radius: 6
                                color: refreshBtnMouse.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
                            }
                            MouseArea {
                                id: refreshBtnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: window.refreshActivePlaylist()
                            }
                            ToolTip.visible: refreshBtnMouse.containsMouse
                            ToolTip.text: qsTr("Refresh the playlist")
                        }

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
                                onClicked: window.showAdmin = true
                            }
                        }
                    }
                }

                // Pick mode banner
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: window.pendingPickSlot >= 0 ? 40 : 0
                    visible: window.pendingPickSlot >= 0
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
                            text: qsTr("Select a channel for Player %1").arg(window.pendingPickSlot + 1)
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
                            onClicked: window.pendingPickSlot = -1
                        }
                    }
                }

                // Tab bar
                TabBar {
                    id: tabBar
                    Layout.fillWidth: true

                    TabButton { text: qsTr("Favorites") }
                    TabButton { text: qsTr("All Channels") }
                    TabButton { text: qsTr("Groups") }
                    TabButton { text: qsTr("History") }
                }

                // Content
                StackLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: tabBar.currentIndex

                    // ChannelListModel etant partage, l'onglet qui devient
                    // visible reapplique son propre filtre.
                    onCurrentIndexChanged: {
                        if (currentIndex === 1)
                            allChannelsPage.activate()
                        else if (currentIndex === 2)
                            groupsPage.activate()
                    }

                    FavoritesPage {
                        onChannelSelected: (name, url, logo, group) => window.handleChannelSelected(name, url, logo, group)
                    }

                    ChannelListPage {
                        id: allChannelsPage
                        onChannelSelected: (name, url, logo, group) => window.handleChannelSelected(name, url, logo, group)
                    }

                    GroupsPage {
                        id: groupsPage
                        onChannelSelected: (name, url, logo, group) => window.handleChannelSelected(name, url, logo, group)
                    }

                    HistoryPage {
                        onChannelSelected: (name, url, logo, group) => window.handleChannelSelected(name, url, logo, group)
                    }
                }
            }

            // Page 1: Admin page
            AdminPage {
                onBackRequested: window.showAdmin = false
            }
        }
    }

    // ── Player layer ──
    PlayerPage {
        id: playerPage
        anchors.fill: parent
        visible: window.showPlayer

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

        onCloseRequested: window.stopPlayback()
        onNavigateRequested: window.openChannelSearch()
        onPrevChannelRequested: window.navigateChannel(-1)
        onNextChannelRequested: window.navigateChannel(1)
        onVariantSwitchRequested: (slotIndex, url, name, logo) => {
            window.setSlotChannel(slotIndex, name, url, logo, window.slotChannels[slotIndex].group)
            DatabaseManager.addHistoryEntry(name, url, logo, window.slotChannels[slotIndex].group)
        }
        onToggleFullscreenRequested: {
            if (window.visibility === Window.FullScreen) {
                window.visibility = Window.Windowed
                window.isFullScreen = false
            } else {
                window.visibility = Window.FullScreen
                window.isFullScreen = true
            }
        }
    }

    // ── Channel search popup ──
    ChannelSearchPopup {
        id: channelSearchPopup
        onChannelSelected: (name, url, logo, group) => window.handleChannelSelected(name, url, logo, group)
    }

    // ── Initial load ──
    // DB-first : les chaines deja en base s'affichent immediatement (donc aussi
    // hors ligne), et le retelechargement n'a lieu que si la playlist est vide
    // ou perimee.
    Component.onCompleted: {
        PlaylistModel.refresh()

        if (PlaylistModel.count === 0)
            return

        var first = PlaylistModel.get(0)
        if (!first)
            return

        activePlaylistId = first.id
        ChannelListModel.setChannels(first.id)

        if (DatabaseManager.needsRefresh(first.id, 24))
            refreshPlaylist(first)
    }
}

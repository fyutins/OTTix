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
    color: Theme.bg

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

    function toggleFullScreen() {
        if (window.visibility === Window.FullScreen) {
            window.visibility = Window.Windowed
            window.isFullScreen = false
        } else {
            window.visibility = Window.FullScreen
            window.isFullScreen = true
        }
    }

    // Donne le focus au champ de recherche de l'onglet courant (Ctrl+F).
    function focusCurrentSearch() {
        if (window.showPlayer || window.showAdmin)
            return
        if (tabBar.currentIndex === 0)
            favoritesPage.focusSearch()
        else if (tabBar.currentIndex === 1)
            allChannelsPage.focusSearch()
        else if (tabBar.currentIndex === 2)
            groupsPage.focusSearch()
        else
            historyPage.focusSearch()
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

    // Bascule sur une autre playlist : affichage immediat depuis la base, et
    // retelechargement seulement si elle est vide ou perimee.
    function selectPlaylist(index) {
        var pl = PlaylistModel.get(index)
        if (!pl || pl.id === activePlaylistId)
            return
        activePlaylistId = pl.id
        ChannelListModel.setChannels(pl.id)
        if (DatabaseManager.needsRefresh(pl.id, 24))
            refreshPlaylist(pl)
    }

    function playlistIndexOf(id) {
        for (var i = 0; i < PlaylistModel.count; i++) {
            var pl = PlaylistModel.get(i)
            if (pl && pl.id === id)
                return i
        }
        return -1
    }

    Shortcut {
        sequence: "F11"
        onActivated: window.toggleFullScreen()
    }

    Shortcut {
        sequences: [StandardKey.Find]
        onActivated: window.focusCurrentSearch()
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
        color: Theme.bg
        visible: !window.showPlayer

        StackLayout {
            anchors.fill: parent
            currentIndex: window.showAdmin ? 1 : 0

            // Page 0: Main navigation
            ColumnLayout {
                spacing: 0

                // ── Barre d'outils ──
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.toolbarHeight
                    color: Theme.surface

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.spacingMd
                        anchors.rightMargin: Theme.spacingSm
                        spacing: Theme.spacingSm

                        Rectangle {
                            Layout.preferredWidth: Theme.controlSm
                            Layout.preferredHeight: Theme.controlSm
                            radius: Theme.radiusSm
                            color: Theme.accent

                            MdiIcon {
                                anchors.centerIn: parent
                                glyph: Mdi.playlistPlay
                                font.pixelSize: Theme.iconSm
                                color: Theme.textOnAccent
                            }
                        }

                        Label {
                            text: qsTr("IPTV Player")
                            color: Theme.text
                            font.pixelSize: Theme.fontLg
                            font.bold: true
                        }

                        // Selecteur de playlist active
                        AppComboBox {
                            id: playlistCombo
                            Layout.leftMargin: Theme.spacingSm
                            Layout.preferredWidth: 220
                            visible: PlaylistModel.count > 0
                            model: PlaylistModel
                            textRole: "name"
                            onActivated: (index) => window.selectPlaylist(index)
                        }

                        Item { Layout.fillWidth: true }

                        Label {
                            text: qsTr("Updating…")
                            color: Theme.textMuted
                            font.pixelSize: Theme.fontSm
                            visible: window.refreshing
                        }

                        IconButton {
                            id: refreshButton
                            glyph: Mdi.refresh
                            enabled: !window.refreshing && window.activePlaylistId >= 0
                            tooltip: qsTr("Refresh the playlist")
                            onClicked: window.refreshActivePlaylist()

                            RotationAnimation on rotation {
                                running: window.refreshing
                                loops: Animation.Infinite
                                from: 0
                                to: 360
                                duration: 1200
                                onRunningChanged: if (!running) refreshButton.rotation = 0
                            }
                        }

                        IconButton {
                            glyph: Mdi.cogOutline
                            tooltip: qsTr("Settings and playlists")
                            onClicked: window.showAdmin = true
                        }
                    }

                    // Filet de progression indeterminee pendant un refresh
                    Item {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 2
                        clip: true
                        visible: window.refreshing

                        Rectangle {
                            id: progressSliver
                            width: parent.width * 0.3
                            height: parent.height
                            color: Theme.accent

                            XAnimator on x {
                                running: window.refreshing
                                loops: Animation.Infinite
                                from: -progressSliver.width
                                to: progressSliver.parent.width
                                duration: 1100
                            }
                        }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 1
                        color: Theme.border
                        visible: !window.refreshing
                    }
                }

                // ── Banniere du mode selection (multiplex) ──
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: window.pendingPickSlot >= 0 ? Theme.controlLg + Theme.spacingSm : 0
                    visible: window.pendingPickSlot >= 0
                    color: Theme.accentSoft
                    clip: true

                    Behavior on Layout.preferredHeight {
                        NumberAnimation { duration: Theme.durNormal; easing.type: Easing.OutCubic }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 3
                        color: Theme.accent
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.spacingMd
                        anchors.rightMargin: Theme.spacingSm
                        spacing: Theme.spacingSm

                        MdiIcon {
                            glyph: Mdi.plusCircle
                            font.pixelSize: Theme.iconSm
                            color: Theme.accent
                        }

                        Label {
                            Layout.fillWidth: true
                            text: qsTr("Select a channel for Player %1").arg(window.pendingPickSlot + 1)
                            color: Theme.text
                            font.pixelSize: Theme.fontMd
                            font.bold: true
                        }

                        AppButton {
                            text: qsTr("Cancel")
                            variant: AppButton.Ghost
                            onClicked: window.pendingPickSlot = -1
                        }
                    }
                }

                // ── Onglets ──
                AppTabBar {
                    id: tabBar
                    Layout.fillWidth: true

                    AppTabButton {
                        text: qsTr("Favorites")
                        glyph: Mdi.star
                        badgeText: favoritesPage.displayCount > 0 ? favoritesPage.displayCount : ""
                    }
                    AppTabButton {
                        text: qsTr("All Channels")
                        glyph: Mdi.television
                    }
                    AppTabButton {
                        text: qsTr("Groups")
                        glyph: Mdi.folderMultiple
                    }
                    AppTabButton {
                        text: qsTr("History")
                        glyph: Mdi.history
                    }
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
                        id: favoritesPage
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
                        id: historyPage
                        onChannelSelected: (name, url, logo, group) => window.handleChannelSelected(name, url, logo, group)
                    }
                }
            }

            // Page 1: Admin page
            AdminPage {
                onBackRequested: window.showAdmin = false
                onPlaylistsChanged: window.syncPlaylistSelection()
            }
        }
    }

    // Aligne le selecteur sur la playlist active (et en adopte une si celle en
    // cours a disparu).
    function syncPlaylistSelection() {
        PlaylistModel.refresh()
        var idx = playlistIndexOf(activePlaylistId)
        if (idx < 0 && PlaylistModel.count > 0) {
            idx = 0
            var pl = PlaylistModel.get(0)
            if (pl) {
                activePlaylistId = pl.id
                ChannelListModel.setChannels(pl.id)
            }
        }
        playlistCombo.currentIndex = idx
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
        isFullScreen: window.isFullScreen

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
        onToggleFullscreenRequested: window.toggleFullScreen()
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
        playlistCombo.currentIndex = 0
        ChannelListModel.setChannels(first.id)

        if (DatabaseManager.needsRefresh(first.id, 24))
            refreshPlaylist(first)
    }
}

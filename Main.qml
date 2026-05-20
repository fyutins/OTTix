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

    function startSlotPick(index) {
        pendingPickSlot = index
    }

    function setActiveAudioSlot(index) {
        activeAudioSlot = index
    }

    function handleChannelSelected(name, url, logo, group) {
        if (pendingPickSlot >= 0) {
            var slot = pendingPickSlot
            pendingPickSlot = -1
            setSlotChannel(slot, name, url, logo, group)
            if (!showPlayer)
                showPlayer = true
            if (multiplexMode === 1)
                activeAudioSlot = slot
        } else {
            setSlotChannel(0, name, url, logo, group)
            showPlayer = true
            activeAudioSlot = 0
        }
    }

    function stopPlayback() {
        showPlayer = false
        var empty = { name: "", url: "", logo: "", group: "" }
        slotChannels = [empty, empty, empty, empty]
    }

    function getSlotItem(index) {
        if (index === 0) return slot0
        if (index === 1) return slot1
        if (index === 2) return slot2
        if (index === 3) return slot3
        return null
    }

    property var activeSlotItem: null

    function updateActiveSlotItem() {
        activeSlotItem = getSlotItem(activeAudioSlot)
    }

    onActiveAudioSlotChanged: {
        updateActiveSlotItem()
    }

    onMultiplexModeChanged: {
        if (activeAudioSlot >= multiplexMode)
            activeAudioSlot = 0
    }

    onShowPlayerChanged: {
        if (showPlayer)
            controlsTimer.start()
    }

    PlaylistLoader {
        id: loader
        onLoadComplete: (playlistId, channelCount) => {
            console.log("[QML] onLoadComplete: playlistId=" + playlistId + " channelCount=" + channelCount)
            console.log("[QML] Calling ChannelListModel.setChannels...")
            ChannelListModel.setChannels(playlistId)
            console.log("[QML] setChannels done, switching to tab 0")
            tabBar.currentIndex = 0
            console.log("[QML] onLoadComplete done")
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
            if (showPlayer && activeSlotItem) {
                var p = activeSlotItem
                if (p.mpvPlaying)
                    p.doPause()
                else
                    p.doPlay()
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            id: playerArea
            Layout.fillWidth: true
            Layout.preferredHeight: showPlayer ? (isFullScreen ? parent.height : parent.height * 0.45) : 0
            color: "black"
            visible: showPlayer
            clip: true

            Behavior on Layout.preferredHeight {
                NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 2

                    PlayerSlot {
                        id: slot0
                        slotIndex: 0
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: multiplexMode >= 1
                        channelName: slotChannels[0].name
                        channelUrl: slotChannels[0].url
                        channelLogo: slotChannels[0].logo
                        channelGroup: slotChannels[0].group
                        isActiveAudio: activeAudioSlot === 0
                        globalVolume: volumeSlider.value
                        pendingPick: pendingPickSlot === 0
                        onPickRequested: startSlotPick(slotIndex)
                        onAudioToggleRequested: setActiveAudioSlot(slotIndex)
                    }

                    PlayerSlot {
                        id: slot1
                        slotIndex: 1
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: multiplexMode >= 2
                        channelName: slotChannels[1].name
                        channelUrl: slotChannels[1].url
                        channelLogo: slotChannels[1].logo
                        channelGroup: slotChannels[1].group
                        isActiveAudio: activeAudioSlot === 1
                        globalVolume: volumeSlider.value
                        pendingPick: pendingPickSlot === 1
                        onPickRequested: startSlotPick(slotIndex)
                        onAudioToggleRequested: setActiveAudioSlot(slotIndex)
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 2
                    visible: multiplexMode >= 3

                    PlayerSlot {
                        id: slot2
                        slotIndex: 2
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        channelName: slotChannels[2].name
                        channelUrl: slotChannels[2].url
                        channelLogo: slotChannels[2].logo
                        channelGroup: slotChannels[2].group
                        isActiveAudio: activeAudioSlot === 2
                        globalVolume: volumeSlider.value
                        pendingPick: pendingPickSlot === 2
                        onPickRequested: startSlotPick(slotIndex)
                        onAudioToggleRequested: setActiveAudioSlot(slotIndex)
                    }

                    PlayerSlot {
                        id: slot3
                        slotIndex: 3
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: multiplexMode >= 4
                        channelName: slotChannels[3].name
                        channelUrl: slotChannels[3].url
                        channelLogo: slotChannels[3].logo
                        channelGroup: slotChannels[3].group
                        isActiveAudio: activeAudioSlot === 3
                        globalVolume: volumeSlider.value
                        pendingPick: pendingPickSlot === 3
                        onPickRequested: startSlotPick(slotIndex)
                        onAudioToggleRequested: setActiveAudioSlot(slotIndex)
                    }
                }
            }

            Rectangle {
                id: controlsOverlay
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 40
                color: Qt.rgba(0, 0, 0, 0.65)
                opacity: controlsTimer.running ? 1.0 : 0.0
                visible: showPlayer

                Behavior on opacity {
                    NumberAnimation { duration: 300 }
                }

                Timer {
                    id: controlsTimer
                    interval: 3000
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onPositionChanged: controlsTimer.restart()
                    propagateComposedEvents: true
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 8

                    RowLayout {
                        spacing: 4

                        Repeater {
                            model: [1, 2, 3, 4]
                            delegate: ToolButton {
                                text: modelData
                                checkable: true
                                checked: multiplexMode === modelData
                                font.pixelSize: 11
                                implicitWidth: 28
                                implicitHeight: 24
                                onClicked: multiplexMode = modelData
                                contentItem: Text {
                                    text: modelData
                                    color: checked ? "white" : "#a0a0a0"
                                    font.pixelSize: 11
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                background: Rectangle {
                                    color: checked ? "#4a90d9" : "transparent"
                                    radius: 4
                                    border.color: checked ? "#4a90d9" : "#555"
                                    border.width: 1
                                }
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Slider {
                        id: volumeSlider
                        Layout.preferredWidth: 80
                        from: 0
                        to: 100
                        value: 100
                    }
                }
            }

        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#1a1a2e"
            visible: !isFullScreen

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

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

                TabBar {
                    id: tabBar
                    Layout.fillWidth: true

                    TabButton { text: qsTr("Channels") }
                    TabButton { text: qsTr("Favorites") }
                    TabButton { text: qsTr("Playlists") }
                    TabButton { text: qsTr("Settings") }
                }

                StackLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: tabBar.currentIndex

                    ChannelListPage {
                        onChannelSelected: (name, url, logo, group) => handleChannelSelected(name, url, logo, group)
                    }

                    FavoritesPage {
                        onChannelSelected: (name, url, logo, group) => handleChannelSelected(name, url, logo, group)
                    }

                    Item {
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 16

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
                                                text: model.type + " \u00B7 " + model.channelCount + " channels"
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

                    SettingsPage {}
                }
            }
        }
    }

    PlaylistDialog {
        id: playlistDialog
        onPlaylistAdded: (name, url, type, username, password) => {
            PlaylistModel.addPlaylist(name, url, type, username, password)
        }
    }

    function formatTime(seconds) {
        if (seconds <= 0) return "00:00"
        var h = Math.floor(seconds / 3600)
        var m = Math.floor((seconds % 3600) / 60)
        var s = Math.floor(seconds % 60)
        if (h > 0)
            return h.toString().padStart(2, '0') + ":" +
                   m.toString().padStart(2, '0') + ":" +
                   s.toString().padStart(2, '0')
        return m.toString().padStart(2, '0') + ":" +
               s.toString().padStart(2, '0')
    }

    Component.onCompleted: {
        updateActiveSlotItem()
        console.log("[QML] Component.onCompleted: refreshing playlist model")
        PlaylistModel.refresh()
        console.log("[QML] PlaylistModel.count=" + PlaylistModel.count)

        if (PlaylistModel.count > 0) {
            var first = PlaylistModel.get(0)
            console.log("[QML] First playlist: id=" + first.id + " type=" + first.type + " url=" + first.url)
            if (first) {
                if (first.type === "xtream") {
                    console.log("[QML] Loading xtream playlist...")
                    loader.loadXtream(first.id, first.url, first.username, first.password)
                } else {
                    console.log("[QML] Loading M3U playlist...")
                    loader.loadM3U(first.id, first.url)
                }
            }
        } else {
            console.log("[QML] No playlists found, waiting for user to add one")
        }
    }
}

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
    property string currentChannelName: ""
    property string currentChannelUrl: ""
    property string currentChannelLogo: ""
    property string currentChannelGroup: ""

    function playChannel(name, url, logo, group) {
        console.log("[QML] playChannel:", name, url)
        currentChannelName = name
        currentChannelLogo = logo || ""
        currentChannelGroup = group || ""
        showPlayer = true
        mpvItem.clearVideo()
        currentChannelUrl = url
    }

    function stopPlayback() {
        showPlayer = false
        mpvItem.stop()
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
            if (window.visibility === Window.FullScreen) {
                window.visibility = Window.Windowed
                isFullScreen = false
            }
        }
    }

    Shortcut {
        sequence: "Space"
        onActivated: {
            if (showPlayer) {
                if (mpvItem.playing)
                    mpvItem.pause()
                else
                    mpvItem.play()
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

            MpvObject {
                id: mpvItem
                anchors.fill: parent
                source: currentChannelUrl
                visible: showPlayer
                volume: volumeSlider.value
                onReady: {
                    console.log("[QML] mpvItem.onReady received, calling play()")
                    errorLabel.visible = false
                    mpvItem.play()
                }
                onErrorOccurred: {
                    errorLabel.text = "Error: " + error
                    errorLabel.visible = true
                    errorHideTimer.restart()
                }
            }

            Rectangle {
                id: loadingOverlay
                anchors.fill: parent
                color: "#1a1a2e"
                visible: mpvItem.loading

                BusyIndicator {
                    anchors.centerIn: parent
                    running: parent.visible
                    palette {
                        dark: "#e0e0e0"
                        mid: "#4a90d9"
                    }
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.verticalCenter
                    anchors.topMargin: 40
                    text: qsTr("Loading...")
                    color: "#a0a0a0"
                    font.pixelSize: 14
                }
            }

            Label {
                id: errorLabel
                anchors.centerIn: parent
                color: "red"
                font.pixelSize: 16
                visible: false
            }

            Timer {
                id: errorHideTimer
                interval: 3000
                onTriggered: errorLabel.visible = false
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onPositionChanged: controlsTimer.restart()
                onDoubleClicked: {
                    if (window.visibility === Window.FullScreen) {
                        window.visibility = Window.Windowed
                        isFullScreen = false
                    } else {
                        window.visibility = Window.FullScreen
                        isFullScreen = true
                    }
                }
            }

            Rectangle {
                id: controlsOverlay
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 80
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

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Image {
                            Layout.preferredWidth: 36
                            Layout.preferredHeight: 36
                            source: currentChannelLogo || ""
                            asynchronous: true
                            fillMode: Image.PreserveAspectFit
                            visible: currentChannelLogo !== ""
                        }

                        ColumnLayout {
                            spacing: 0
                            Label {
                                text: currentChannelName
                                color: "white"
                                font.pixelSize: 13
                                font.bold: true
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Label {
                                text: currentChannelGroup
                                color: "#a0a0a0"
                                font.pixelSize: 11
                                visible: currentChannelGroup !== ""
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        Item { Layout.fillWidth: true }

                        ComboBox {
                            id: audioTrackCombo
                            model: mpvItem.audioTracks
                            textRole: "label"
                            visible: mpvItem.audioTracks.length > 1
                            Layout.preferredWidth: 100
                            delegate: ItemDelegate {
                                text: modelData.label + (modelData.selected ? "  *" : "")
                                width: parent.width
                            }
                            onActivated: mpvItem.setAudioTrack(mpvItem.audioTracks[index].id)
                        }

                        ComboBox {
                            id: subTrackCombo
                            model: mpvItem.subtitleTracks
                            textRole: "label"
                            visible: mpvItem.subtitleTracks.length > 0
                            Layout.preferredWidth: 100
                            delegate: ItemDelegate {
                                text: modelData.label + (modelData.selected ? "  *" : "")
                                width: parent.width
                            }
                            onActivated: mpvItem.setSubtitleTrack(mpvItem.subtitleTracks[index].id)
                        }

                        ComboBox {
                            id: videoTrackCombo
                            model: mpvItem.videoTracks
                            textRole: "label"
                            visible: mpvItem.videoTracks.length > 1
                            Layout.preferredWidth: 100
                            delegate: ItemDelegate {
                                text: modelData.label + (modelData.selected ? "  *" : "")
                                width: parent.width
                            }
                            onActivated: mpvItem.setVideoTrack(mpvItem.videoTracks[index].id)
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Slider {
                            id: positionSlider
                            Layout.fillWidth: true
                            from: 0
                            to: mpvItem.sessionDuration > 0 ? mpvItem.sessionDuration : 1
                            value: mpvItem.sessionPosition
                            enabled: mpvItem.sessionDuration > 0
                            onMoved: mpvItem.seek(value)
                        }

                        Label {
                            text: formatTime(mpvItem.sessionPosition) + " / " + formatTime(mpvItem.sessionDuration)
                            color: "white"
                            font.pixelSize: 11
                            Layout.preferredWidth: 100
                        }

                        ToolButton {
                            text: mpvItem.playing ? "\u23F8" : "\u25B6"
                            font.pixelSize: 16
                            onClicked: {
                                if (mpvItem.playing)
                                    mpvItem.pause()
                                else
                                    mpvItem.play()
                            }
                        }

                        ToolButton {
                            text: mpvItem.muted ? "\uD83D\uDD07" : "\uD83D\uDD0A"
                            font.pixelSize: 14
                            onClicked: mpvItem.setMuted(!mpvItem.muted)
                        }

                        Slider {
                            id: volumeSlider
                            Layout.preferredWidth: 80
                            from: 0
                            to: 100
                            value: 100
                            onMoved: mpvItem.setVolume(value)
                        }
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
                        onChannelSelected: (name, url, logo, group) => playChannel(name, url, logo, group)
                    }

                    FavoritesPage {
                        onChannelSelected: (name, url, logo, group) => playChannel(name, url, logo, group)
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

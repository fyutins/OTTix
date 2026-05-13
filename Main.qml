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

    function playChannel(name, url) {
        console.log("[QML] playChannel:", name, url)
        currentChannelName = name
        showPlayer = true
        // Clear current frame and stop before loading new channel
        mpvItem.clearVideo()
        mpvItem.stop()
        currentChannelUrl = url
    }

    function stopPlayback() {
        showPlayer = false
        mpvItem.stop()
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
            window.visibility = window.visibility === Window.FullScreen
                ? Window.Windowed
                : Window.FullScreen
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: {
            if (window.visibility === Window.FullScreen)
                window.visibility = Window.Windowed
            if (showPlayer)
                stopPlayback()
        }
    }

    Shortcut {
        sequence: "Space"
        onActivated: {
            if (showPlayer) {
                if (mpvItem.isPlaying)
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
            Layout.preferredHeight: showPlayer ? (parent.height * 0.45) : 0
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

            Rectangle {
                id: controlsOverlay
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 50
                color: Qt.rgba(0, 0, 0, 0.6)
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
                    anchors.margins: 8
                    spacing: 8

                    Label {
                        text: currentChannelName
                        color: "white"
                        font.pixelSize: 14
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Slider {
                        id: positionSlider
                        Layout.fillWidth: true
                        Layout.preferredWidth: 300
                        from: 0
                        to: mpvItem.duration > 0 ? mpvItem.duration : 1
                        value: mpvItem.position
                        enabled: mpvItem.duration > 0
                        onMoved: mpvItem.seek(value)
                    }

                    Label {
                        text: formatTime(mpvItem.position) + " / " + formatTime(mpvItem.duration)
                        color: "white"
                        font.pixelSize: 12
                    }

                    ToolButton {
                        text: mpvItem.isPlaying ? "\u23F8" : "\u25B6"
                        onClicked: {
                            if (mpvItem.isPlaying)
                                mpvItem.pause()
                            else
                                mpvItem.play()
                        }
                    }

                    ToolButton {
                        text: "\u23F9"
                        onClicked: stopPlayback()
                    }

                    Item { width: 16 }

                    ToolButton {
                        text: mpvItem.isMuted ? "\uD83D\uDD07" : "\uD83D\uDD0A"
                        onClicked: mpvItem.setMuted(!mpvItem.isMuted)
                    }

                    Slider {
                        id: volumeSlider
                        Layout.preferredWidth: 100
                        from: 0
                        to: 100
                        value: 100
                        onMoved: mpvItem.setVolume(value)
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onPositionChanged: controlsTimer.restart()
                onDoubleClicked: {
                    window.visibility = window.visibility === Window.FullScreen
                        ? Window.Windowed
                        : Window.FullScreen
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#1a1a2e"

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
                        onChannelSelected: (name, url) => playChannel(name, url)
                    }

                    FavoritesPage {
                        onChannelSelected: (name, url) => playChannel(name, url)
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
        PlaylistModel.refresh()

        if (PlaylistModel.count > 0) {
            var first = PlaylistModel.get(0)
            if (first)
                loader.loadM3U(first.id, first.url)
        }
    }
}

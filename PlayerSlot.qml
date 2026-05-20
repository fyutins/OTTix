import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import IptvPlayer.Player

Rectangle {
    id: root
    color: "black"
    clip: true

    property int slotIndex: 0
    property string channelName: ""
    property string channelUrl: ""
    property string channelLogo: ""
    property string channelGroup: ""
    property bool isActiveAudio: false
    property bool pendingPick: false
    property int globalVolume: 100

    property bool mpvPlaying: mpvItem.playing
    property alias mpvRef: mpvItem

    signal pickRequested(int slotIndex)
    signal audioToggleRequested(int slotIndex)

    function doPlay() { mpvItem.play() }
    function doPause() { mpvItem.pause() }
    function doStop() { mpvItem.stop() }
    function doSeek(pos) { mpvItem.seek(pos) }

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

    function showControls() {
        controlsOpacity = 1.0
        if (root.channelUrl !== "")
            hideTimer.restart()
    }

    MpvObject {
        id: mpvItem
        anchors.fill: parent
        source: root.channelUrl
        volume: root.globalVolume
        muted: !root.isActiveAudio
    }

    BusyIndicator {
        anchors.centerIn: parent
        running: mpvItem.loading && root.channelUrl !== ""
        palette {
            dark: "#e0e0e0"
            mid: "#4a90d9"
        }
    }

    property real controlsOpacity: 1.0

    Timer {
        id: hideTimer
        interval: 3000
        onTriggered: {
            if (root.channelUrl !== "")
                controlsOpacity = 0.0
        }
    }

    onChannelUrlChanged: {
        if (root.channelUrl === "") {
            controlsOpacity = 1.0
            hideTimer.stop()
        } else {
            controlsOpacity = 1.0
            hideTimer.restart()
        }
    }

    Item {
        anchors.fill: parent
        opacity: controlsOpacity
        enabled: opacity > 0.5
        Behavior on opacity { NumberAnimation { duration: 300 } }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 50
            color: Qt.rgba(0, 0, 0, 0.75)
            visible: root.channelUrl !== ""
            z: 4

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 4
                spacing: 2

                // Row 1: logo + channel name
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Image {
                        Layout.preferredWidth: 18
                        Layout.preferredHeight: 18
                        source: root.channelLogo || ""
                        asynchronous: true
                        fillMode: Image.PreserveAspectFit
                        visible: root.channelLogo !== ""
                    }

                    Text {
                        text: root.channelName
                        color: "white"
                        font.pixelSize: 12
                        font.bold: true
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                // Row 2: seek + time + audio
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Slider {
                        id: seekSlider
                        Layout.fillWidth: true
                        from: 0
                        to: mpvItem.sessionDuration > 0 ? mpvItem.sessionDuration : 1
                        value: mpvItem.sessionPosition
                        enabled: mpvItem.sessionDuration > 0
                        implicitHeight: 12
                        onMoved: mpvItem.seek(value)
                    }

                    Text {
                        text: formatTime(mpvItem.sessionPosition) + " / " + formatTime(mpvItem.sessionDuration)
                        color: "#a0a0a0"
                        font.pixelSize: 10
                    }

                    Rectangle {
                        width: 22
                        height: 22
                        radius: 11
                        color: root.isActiveAudio ? "#4a90d9" : Qt.rgba(1,1,1,0.2)
                        border.color: root.isActiveAudio ? "#4a90d9" : "#888"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: root.isActiveAudio ? "\uD83D\uDD0A" : "\uD83D\uDD07"
                            font.pixelSize: 11
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.audioToggleRequested(root.slotIndex)
                        }
                    }
                }
            }
        }

        Item {
            anchors.centerIn: parent
            width: childrenRect.width
            height: childrenRect.height
            z: 3

            ColumnLayout {
                spacing: 16

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 48
                    height: 48
                    radius: 24
                    color: Qt.rgba(0, 0, 0, 0.65)
                    visible: root.channelUrl !== ""

                    Text {
                        anchors.centerIn: parent
                        text: mpvItem.playing ? "\u23F8" : "\u25B6"
                        color: "white"
                        font.pixelSize: 22
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (mpvItem.playing) mpvItem.pause()
                            else mpvItem.play()
                        }
                    }
                }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 48
                    height: 48
                    radius: 24
                    color: Qt.rgba(0, 0, 0, 0.7)
                    visible: root.channelUrl !== ""

                    Text {
                        anchors.centerIn: parent
                        text: "\u2630"
                        color: "white"
                        font.pixelSize: 22
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.pickRequested(root.slotIndex)
                    }
                }
            }
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: 56
        height: 56
        radius: 28
        color: Qt.rgba(0, 0, 0, 0.7)
        visible: root.channelUrl === ""
        z: 2

        Text {
            anchors.centerIn: parent
            text: "+"
            color: "white"
            font.pixelSize: 28
            font.bold: true
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.pickRequested(root.slotIndex)
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        z: 100
        propagateComposedEvents: true
        cursorShape: Qt.PointingHandCursor
        onPositionChanged: root.showControls()
        onPressed: (mouse) => {
            root.showControls()
            mouse.accepted = false
        }
        onClicked: (mouse) => {
            root.showControls()
            mouse.accepted = false
        }
    }
}

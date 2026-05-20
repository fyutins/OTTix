import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import IptvPlayer.Player

Rectangle {
    id: root
    color: "black"

    signal closeRequested()
    signal navigateRequested()
    signal multiplexModeChangeRequested(int mode)
    signal activeAudioSlotChangeRequested(int slot)
    signal pendingPickSlotChangeRequested(int slot)

    property int multiplexMode: 1
    property int activeAudioSlot: 0
    property int pendingPickSlot: -1

    property var slotChannels: [
        { name: "", url: "", logo: "", group: "" },
        { name: "", url: "", logo: "", group: "" },
        { name: "", url: "", logo: "", group: "" },
        { name: "", url: "", logo: "", group: "" }
    ]

    property int globalVolume: 100

    property bool anyChannelLoaded: slotChannels[0].url !== ""
        || slotChannels[1].url !== ""
        || slotChannels[2].url !== ""
        || slotChannels[3].url !== ""

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

    onActiveAudioSlotChanged: updateActiveSlotItem()

    onMultiplexModeChanged: {
        if (activeAudioSlot >= multiplexMode)
            activeAudioSlotChangeRequested(0)
    }

    function startSlotPick(index) {
        pendingPickSlotChangeRequested(index)
        navigateRequested()
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

    property real controlsOpacity: 1.0

    Timer {
        id: hideTimer
        interval: 3000
        onTriggered: {
            if (root.anyChannelLoaded)
                controlsOpacity = 0.0
        }
    }

    onAnyChannelLoadedChanged: {
        if (root.anyChannelLoaded) {
            controlsOpacity = 1.0
            hideTimer.restart()
        } else {
            controlsOpacity = 1.0
            hideTimer.stop()
        }
    }

    function showControls() {
        controlsOpacity = 1.0
        if (root.anyChannelLoaded)
            hideTimer.restart()
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
                globalVolume: globalVolume
                pendingPick: pendingPickSlot === 0
                onPickRequested: root.startSlotPick(slotIndex)
                onAudioToggleRequested: root.activeAudioSlotChangeRequested(slotIndex)
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
                globalVolume: globalVolume
                pendingPick: pendingPickSlot === 1
                onPickRequested: root.startSlotPick(slotIndex)
                onAudioToggleRequested: root.activeAudioSlotChangeRequested(slotIndex)
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
                globalVolume: globalVolume
                pendingPick: pendingPickSlot === 2
                onPickRequested: root.startSlotPick(slotIndex)
                onAudioToggleRequested: root.activeAudioSlotChangeRequested(slotIndex)
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
                globalVolume: globalVolume
                pendingPick: pendingPickSlot === 3
                onPickRequested: root.startSlotPick(slotIndex)
                onAudioToggleRequested: root.activeAudioSlotChangeRequested(slotIndex)
            }
        }
    }

    // ── Top bar (close + centrered mode selector + volume) ──
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 40
        color: Qt.rgba(0, 0, 0, 0.65)
        opacity: controlsOpacity
        Behavior on opacity { NumberAnimation { duration: 300 } }
        z: 10

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 6

            Button {
                text: "\u2715"
                flat: true
                implicitWidth: 28
                implicitHeight: 28
                contentItem: Text {
                    text: "\u2715"
                    color: "#e0e0e0"
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: mouseArea.containsMouse ? Qt.rgba(1,1,1,0.15) : "transparent"
                    radius: 4
                }
                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.closeRequested()
                }
            }

            Item { Layout.fillWidth: true }

            RowLayout {
                spacing: 6

                Repeater {
                    model: [1, 2, 3, 4]
                    delegate: ToolButton {
                        text: modelData
                        checkable: true
                        checked: root.multiplexMode === modelData
                        font.pixelSize: 11
                        implicitWidth: 28
                        implicitHeight: 24
                        onClicked: root.multiplexModeChangeRequested(modelData)
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

            RowLayout {
                spacing: 6

                Label {
                    text: qsTr("Volume")
                    color: "#a0a0a0"
                    font.pixelSize: 11
                }

                Slider {
                    id: volumeSlider
                    Layout.preferredWidth: 80
                    from: 0
                    to: 100
                    value: root.globalVolume
                    onValueChanged: root.globalVolume = value
                }
            }
        }
    }

    // ── Click anywhere to show controls ──
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        z: 5
        propagateComposedEvents: true
        onPositionChanged: root.showControls()
        onPressed: (mouse) => {
            root.showControls()
            mouse.accepted = false
        }
    }

    Component.onCompleted: {
        updateActiveSlotItem()
    }
}

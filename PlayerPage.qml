pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore

Rectangle {
    id: root
    color: "black"

    signal closeRequested()
    signal navigateRequested()
    signal prevChannelRequested()
    signal nextChannelRequested()
    signal multiplexModeChangeRequested(int mode)
    signal activeAudioSlotChangeRequested(int slot)
    signal pendingPickSlotChangeRequested(int slot)
    signal toggleFullscreenRequested()
    signal variantSwitchRequested(int slotIndex, string url, string name, string logo)

    property int multiplexMode: 1
    property int activeAudioSlot: 0
    property int pendingPickSlot: -1

    property var slotChannels: [
        { name: "", url: "", logo: "", group: "" },
        { name: "", url: "", logo: "", group: "" },
        { name: "", url: "", logo: "", group: "" },
        { name: "", url: "", logo: "", group: "" }
    ]

    property bool anyChannelLoaded: slotChannels[0].url !== ""
        || slotChannels[1].url !== ""
        || slotChannels[2].url !== ""
        || slotChannels[3].url !== ""

    function stopAll() {
        for (var i = 0; i < 4; i++) {
            slotChannels[i] = { name: "", url: "", logo: "", group: "" }
        }
    }

    property string playerHwdec: "auto"

    Settings {
        property alias volume: volumeSlider.value
        property alias playerHwdec: root.playerHwdec
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

    onActiveAudioSlotChanged: updateActiveSlotItem()

    onMultiplexModeChanged: {
        if (activeAudioSlot >= multiplexMode)
            activeAudioSlotChangeRequested(0)
    }

    function applyHwdecToAll(value) {
        for (var i = 0; i < 4; i++) {
            var slot = getSlotItem(i)
            if (slot)
                slot.mpvRef.setHwdec(value)
        }
        for (var i = 0; i < 4; i++) {
            var slot = getSlotItem(i)
            if (slot && slot.channelUrl !== "")
                slot.mpvRef.reload()
        }
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
                visible: root.multiplexMode >= 1
                channelName: root.slotChannels[0].name
                channelUrl: root.slotChannels[0].url
                channelLogo: root.slotChannels[0].logo
                channelGroup: root.slotChannels[0].group
                isActiveAudio: root.activeAudioSlot === 0
                globalVolume: volumeSlider.value
                pendingPick: root.pendingPickSlot === 0
                onPickRequested: root.startSlotPick(slotIndex)
                onAudioToggleRequested: root.activeAudioSlotChangeRequested(slotIndex)
                onDoubleClickRequested: root.toggleFullscreenRequested()
                onHwdecChangeRequested: (value) => { root.playerHwdec = value; root.applyHwdecToAll(value) }
                onPrevRequested: root.prevChannelRequested()
                onNextRequested: root.nextChannelRequested()
                onVariantSwitchRequested: (url, name, logo) => root.variantSwitchRequested(slotIndex, url, name, logo)
            }

            PlayerSlot {
                id: slot1
                slotIndex: 1
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.multiplexMode >= 2
                channelName: root.slotChannels[1].name
                channelUrl: root.slotChannels[1].url
                channelLogo: root.slotChannels[1].logo
                channelGroup: root.slotChannels[1].group
                isActiveAudio: root.activeAudioSlot === 1
                globalVolume: volumeSlider.value
                pendingPick: root.pendingPickSlot === 1
                onPickRequested: root.startSlotPick(slotIndex)
                onAudioToggleRequested: root.activeAudioSlotChangeRequested(slotIndex)
                onDoubleClickRequested: root.toggleFullscreenRequested()
                onHwdecChangeRequested: (value) => { root.playerHwdec = value; root.applyHwdecToAll(value) }
                onPrevRequested: root.prevChannelRequested()
                onNextRequested: root.nextChannelRequested()
                onVariantSwitchRequested: (url, name, logo) => root.variantSwitchRequested(slotIndex, url, name, logo)
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 2
            visible: root.multiplexMode >= 3

            PlayerSlot {
                id: slot2
                slotIndex: 2
                Layout.fillWidth: true
                Layout.fillHeight: true
                channelName: root.slotChannels[2].name
                channelUrl: root.slotChannels[2].url
                channelLogo: root.slotChannels[2].logo
                channelGroup: root.slotChannels[2].group
                isActiveAudio: root.activeAudioSlot === 2
                globalVolume: volumeSlider.value
                pendingPick: root.pendingPickSlot === 2
                onPickRequested: root.startSlotPick(slotIndex)
                onAudioToggleRequested: root.activeAudioSlotChangeRequested(slotIndex)
                onDoubleClickRequested: root.toggleFullscreenRequested()
                onHwdecChangeRequested: (value) => { root.playerHwdec = value; root.applyHwdecToAll(value) }
                onPrevRequested: root.prevChannelRequested()
                onNextRequested: root.nextChannelRequested()
                onVariantSwitchRequested: (url, name, logo) => root.variantSwitchRequested(slotIndex, url, name, logo)
            }

            PlayerSlot {
                id: slot3
                slotIndex: 3
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.multiplexMode >= 4
                channelName: root.slotChannels[3].name
                channelUrl: root.slotChannels[3].url
                channelLogo: root.slotChannels[3].logo
                channelGroup: root.slotChannels[3].group
                isActiveAudio: root.activeAudioSlot === 3
                globalVolume: volumeSlider.value
                pendingPick: root.pendingPickSlot === 3
                onPickRequested: root.startSlotPick(slotIndex)
                onAudioToggleRequested: root.activeAudioSlotChangeRequested(slotIndex)
                onDoubleClickRequested: root.toggleFullscreenRequested()
                onHwdecChangeRequested: (value) => { root.playerHwdec = value; root.applyHwdecToAll(value) }
                onPrevRequested: root.prevChannelRequested()
                onNextRequested: root.nextChannelRequested()
                onVariantSwitchRequested: (url, name, logo) => root.variantSwitchRequested(slotIndex, url, name, logo)
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
        opacity: slot0.overlayActive || slot1.overlayActive || slot2.overlayActive || slot3.overlayActive ? 1.0 : 0.0
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
                    onClicked: { root.stopAll(); root.closeRequested() }
                }
            }

            Item { Layout.fillWidth: true }

            RowLayout {
                spacing: 6

                Repeater {
                    model: [1, 2, 3, 4]
                    delegate: ToolButton {
                        id: modeButton

                        required property int modelData

                        text: modeButton.modelData
                        checkable: true
                        checked: root.multiplexMode === modeButton.modelData
                        font.pixelSize: 11
                        implicitWidth: 28
                        implicitHeight: 24
                        onClicked: root.multiplexModeChangeRequested(modeButton.modelData)
                        contentItem: Text {
                            text: modeButton.modelData
                            color: modeButton.checked ? "white" : "#a0a0a0"
                            font.pixelSize: 11
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            color: modeButton.checked ? "#4a90d9" : "transparent"
                            radius: 4
                            border.color: modeButton.checked ? "#4a90d9" : "#555"
                            border.width: 1
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true }

            RowLayout {
                spacing: 8

                Label {
                    text: qsTr("Vol")
                    color: "#a0a0a0"
                    font.pixelSize: 11
                }

                Slider {
                    id: volumeSlider
                    Layout.preferredWidth: 130
                    implicitHeight: 22
                    from: 0
                    to: 100
                    stepSize: 1
                    value: 100
                    handle: Rectangle {
                        x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
                        y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                        width: 16
                        height: 16
                        radius: 8
                        color: volumeSlider.pressed ? "#6ab0f0" : "#4a90d9"
                        Behavior on color { ColorAnimation { duration: 100 } }
                    }
                }

                Label {
                    text: Math.round(volumeSlider.value) + "%"
                    color: "#e0e0e0"
                    font.pixelSize: 11
                    horizontalAlignment: Text.AlignRight
                    Layout.preferredWidth: 30
                }
            }
        }
    }

    Component.onCompleted: {
        updateActiveSlotItem()
        applyHwdecToAll(playerHwdec)
    }
}

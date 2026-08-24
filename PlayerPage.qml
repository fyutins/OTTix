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
    property bool isFullScreen: false

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
    property int lastVolume: 100

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

    function toggleMute() {
        if (volumeSlider.value > 0) {
            root.lastVolume = volumeSlider.value
            volumeSlider.value = 0
        } else {
            volumeSlider.value = root.lastVolume > 0 ? root.lastVolume : 100
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
                multiplexed: root.multiplexMode > 1
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
                multiplexed: root.multiplexMode > 1
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
                multiplexed: root.multiplexMode > 1
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
                multiplexed: root.multiplexMode > 1
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

    // ── Barre haute : fermeture · disposition · volume · plein ecran ──
    Rectangle {
        id: topBar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: Theme.toolbarHeight
        opacity: slot0.overlayActive || slot1.overlayActive || slot2.overlayActive || slot3.overlayActive ? 1.0 : 0.0
        visible: opacity > 0.01
        z: 10

        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.scrimStrong }
            GradientStop { position: 1.0; color: "transparent" }
        }

        Behavior on opacity { NumberAnimation { duration: Theme.durSlow } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.spacingSm
            anchors.rightMargin: Theme.spacingSm
            spacing: Theme.spacingSm

            IconButton {
                glyph: Mdi.close
                tinted: true
                round: true
                glyphColor: Theme.text
                tooltip: qsTr("Close the player")
                onClicked: { root.stopAll(); root.closeRequested() }
            }

            IconButton {
                glyph: Mdi.menu
                tinted: true
                round: true
                glyphColor: Theme.text
                tooltip: qsTr("Browse channels")
                onClicked: root.navigateRequested()
            }

            Item { Layout.fillWidth: true }

            // ── Selecteur de disposition (segmente) ──
            Rectangle {
                Layout.preferredWidth: modeRow.implicitWidth + Theme.spacingXs * 2
                Layout.preferredHeight: Theme.controlMd
                radius: Theme.radiusSm
                color: Theme.glassDark

                Row {
                    id: modeRow
                    anchors.centerIn: parent
                    spacing: 2

                    Repeater {
                        model: [
                            { mode: 1, glyph: Mdi.layout1, label: qsTr("Single screen") },
                            { mode: 2, glyph: Mdi.layout2, label: qsTr("Two screens") },
                            { mode: 3, glyph: Mdi.layout3, label: qsTr("Three screens") },
                            { mode: 4, glyph: Mdi.layout4, label: qsTr("Four screens") }
                        ]

                        delegate: IconButton {
                            id: modeButton

                            required property var modelData

                            implicitWidth: Theme.controlSm + Theme.spacingXs
                            implicitHeight: Theme.controlSm
                            glyph: modeButton.modelData.glyph
                            glyphSize: Theme.iconSm
                            glyphColor: Theme.textMuted
                            checkable: true
                            checked: root.multiplexMode === modeButton.modelData.mode
                            tooltip: modeButton.modelData.label
                            onClicked: root.multiplexModeChangeRequested(modeButton.modelData.mode)
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // ── Volume ──
            RowLayout {
                spacing: Theme.spacingXs

                IconButton {
                    glyph: volumeSlider.value === 0 ? Mdi.volumeOff
                         : volumeSlider.value < 50 ? Mdi.volumeMedium : Mdi.volumeHigh
                    tinted: true
                    round: true
                    glyphColor: volumeSlider.value === 0 ? Theme.textDim : Theme.text
                    tooltip: volumeSlider.value === 0 ? qsTr("Unmute") : qsTr("Mute")
                    onClicked: root.toggleMute()
                }

                Slider {
                    id: volumeSlider
                    Layout.preferredWidth: 130
                    implicitHeight: Theme.controlSm
                    from: 0
                    to: 100
                    stepSize: 1
                    value: 100

                    background: Rectangle {
                        x: volumeSlider.leftPadding
                        y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                        width: volumeSlider.availableWidth
                        height: 4
                        radius: 2
                        color: Theme.glass

                        Rectangle {
                            width: volumeSlider.visualPosition * parent.width
                            height: parent.height
                            radius: parent.radius
                            color: Theme.accent
                        }
                    }

                    handle: Rectangle {
                        x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
                        y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                        width: volumeSlider.pressed || volumeSlider.hovered ? 16 : 12
                        height: width
                        radius: width / 2
                        color: volumeSlider.pressed ? Theme.accentPressed : Theme.accent
                        border.width: 2
                        border.color: Theme.textOnAccent

                        Behavior on width { NumberAnimation { duration: Theme.durFast } }
                        Behavior on color { ColorAnimation { duration: Theme.durFast } }
                    }

                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                }

                Label {
                    text: Math.round(volumeSlider.value) + "%"
                    color: Theme.textMuted
                    font.pixelSize: Theme.fontSm
                    horizontalAlignment: Text.AlignRight
                    Layout.preferredWidth: 32
                }
            }

            IconButton {
                glyph: root.isFullScreen ? Mdi.fullscreenExit : Mdi.fullscreen
                tinted: true
                round: true
                glyphColor: Theme.text
                tooltip: root.isFullScreen ? qsTr("Exit full screen (F11)")
                                           : qsTr("Full screen (F11)")
                onClicked: root.toggleFullscreenRequested()
            }
        }
    }

    Component.onCompleted: {
        updateActiveSlotItem()
        applyHwdecToAll(playerHwdec)
        lastVolume = volumeSlider.value > 0 ? volumeSlider.value : 100
    }
}

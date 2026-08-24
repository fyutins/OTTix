pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

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

    signal pickRequested(int slotIndex)
    signal audioToggleRequested(int slotIndex)
    signal doubleClickRequested()
    signal hwdecChangeRequested(string value)
    signal prevRequested()
    signal nextRequested()
    signal variantSwitchRequested(string url, string name, string logo)

    property bool mpvPlaying: mpvItem.playing
    property alias mpvRef: mpvItem
    property bool overlayActive: false
    property int hideBlockedUntil: 0

    function showControls() {
        if (Date.now() < hideBlockedUntil) return
        controlsOpacity = 1.0
        overlayActive = true
        if (root.channelUrl !== "")
            hideTimer.restart()
    }

    MpvObject {
        id: mpvItem
        anchors.fill: parent
        source: root.channelUrl
        volume: Math.pow(root.globalVolume / 100.0, 1.1) * 100.0
        muted: !root.isActiveAudio
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        visible: root.channelUrl === ""
        z: 1
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
            if (root.channelUrl !== "") {
                root.controlsOpacity = 0.0
                root.overlayActive = false
                root.hideBlockedUntil = Date.now() + 500
            }
        }
    }

    onChannelUrlChanged: {
        if (root.channelUrl === "") {
            mpvItem.stop()
            controlsOpacity = 1.0
            overlayActive = false
            hideTimer.stop()
        } else {
            qualityBadge.currentLabel = ChannelListModel.getVariantLabelForUrl(root.channelUrl)
            controlsOpacity = 1.0
            overlayActive = true
            hideTimer.restart()
        }
    }

    property string currentAudioTrackLabel: ""

    property string currentSubtitleTrackLabel: ""

    Connections {
        target: mpvItem
        function onTracksChanged() {
            var at = mpvItem.audioTracks
            root.currentAudioTrackLabel = ""
            for (var i = 0; i < at.length; i++) {
                if (at[i].selected) {
                    root.currentAudioTrackLabel = at[i].lang || at[i].label || ""
                    break
                }
            }

            var st = mpvItem.subtitleTracks
            root.currentSubtitleTrackLabel = ""
            for (var j = 0; j < st.length; j++) {
                if (st[j].selected) {
                    root.currentSubtitleTrackLabel = st[j].lang || st[j].label || ""
                    break
                }
            }
        }
    }

    Item {
        anchors.fill: parent
        opacity: root.controlsOpacity
        enabled: opacity > 0.5
        Behavior on opacity { NumberAnimation { duration: 300 } }

        // ── Bottom bar (logo, name, controls) ──
        Rectangle {
            id: bottomBar
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 36
            color: Qt.rgba(0, 0, 0, 0.75)
            visible: root.channelUrl !== ""
            z: 4

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 6
                anchors.topMargin: 0
                anchors.bottomMargin: 0
                spacing: 6

                Image {
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                    source: root.channelLogo || ""
                    asynchronous: true
                    fillMode: Image.PreserveAspectFit
                    visible: root.channelLogo !== ""
                }

                Text {
                    text: root.channelName
                    color: "white"
                    font.pixelSize: 11
                    font.bold: true
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                // Quality badge
                Rectangle {
                    id: qualityBadge
                    implicitWidth: qualityLabel.implicitWidth + 12
                    Layout.preferredHeight: 20
                    radius: 4
                    color: Qt.rgba(1,1,1,0.15)
                    border.color: "#888"
                    border.width: 1
                    visible: root.channelUrl !== "" && ChannelListModel.channelHasVariants(root.channelUrl)

                    property string currentLabel: ""

                    Text {
                        id: qualityLabel
                        anchors.centerIn: parent
                        text: qualityBadge.currentLabel.length > 0 ? qualityBadge.currentLabel : qsTr("SD")
                        color: "white"
                        font.pixelSize: 9
                        font.bold: true
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            qualityListModel.clear()
                            var variants = ChannelListModel.getVariantsForUrl(root.channelUrl)
                            for (var i = 0; i < variants.length; i++) {
                                var v = variants[i]
                                qualityListModel.append({
                                    label: v.label || qsTr("Default"),
                                    name: v.name,
                                    url: v.url,
                                    logo: v.logo || "",
                                    group: v.group || "",
                                    isCurrent: v.url === root.channelUrl
                                })
                            }
                            var pos = root.mapFromItem(qualityBadge, 0, 0)
                            qualityPopup.x = pos.x + qualityBadge.width - qualityPopup.width
                            qualityPopup.y = pos.y - qualityPopup.implicitHeight - 8
                            qualityPopup.open()
                        }
                    }
                }

                // Reload
                Rectangle {
                    Layout.preferredWidth: 22
                    Layout.preferredHeight: 22
                    radius: 11
                    color: Qt.rgba(1,1,1,0.2)
                    border.color: "#888"
                    border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: "\u21BB"
                        font.pixelSize: 11
                        color: "white"
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: mpvItem.reload()
                    }
                }

                // ── Audio slot mute toggle ──
                Rectangle {
                    Layout.preferredWidth: 22
                    Layout.preferredHeight: 22
                    radius: 11
                    color: root.isActiveAudio ? "#4a90d9" : Qt.rgba(1,1,1,0.2)
                    border.color: root.isActiveAudio ? "#4a90d9" : "#888"
                    border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: root.isActiveAudio ? "\uD83D\uDD0A" : "\uD83D\uDD07"
                        font.pixelSize: 10
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.audioToggleRequested(root.slotIndex)
                    }
                }
            }
        }

        // ── Center: ≡ (top) · ◀ ▶ Play/Pause (bottom) ──
        Item {
            anchors.centerIn: parent
            width: centerColumn.implicitWidth
            height: centerColumn.implicitHeight
            z: 3

            ColumnLayout {
                id: centerColumn
                spacing: 12
                visible: root.channelUrl !== ""

                // ≡ (pick) — centered above play/pause
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    radius: 20
                    color: Qt.rgba(0, 0, 0, 0.7)
                    Text {
                        anchors.centerIn: parent
                        text: "\u2630"
                        color: "white"
                        font.pixelSize: 18
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.pickRequested(root.slotIndex)
                    }
                }

                // ◀ · Play/Pause · ▶
                RowLayout {
                    spacing: 12
                    Layout.alignment: Qt.AlignHCenter

                    // ◀ Prev
                    Rectangle {
                        Layout.preferredWidth: 44
                        Layout.preferredHeight: 44
                        radius: 22
                        color: Qt.rgba(0, 0, 0, 0.65)
                        Text {
                            anchors.centerIn: parent
                            text: "\u25C0"
                            color: "white"
                            font.pixelSize: 18
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.prevRequested()
                        }
                    }

                    // Play / Pause
                    Rectangle {
                        Layout.preferredWidth: 48
                        Layout.preferredHeight: 48
                        radius: 24
                        color: Qt.rgba(0, 0, 0, 0.65)
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

                    // ▶ Next
                    Rectangle {
                        Layout.preferredWidth: 44
                        Layout.preferredHeight: 44
                        radius: 22
                        color: Qt.rgba(0, 0, 0, 0.65)
                        Text {
                            anchors.centerIn: parent
                            text: "\u25B6"
                            color: "white"
                            font.pixelSize: 18
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.nextRequested()
                        }
                    }
                }
            }
        }

        // ── -15s · LIVE · +15s (above bottom bar) ──
        RowLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: bottomBar.top
            anchors.bottomMargin: 12
            spacing: 16
            visible: root.channelUrl !== "" && mpvItem.sessionDuration > 0
            z: 3

            // -15s
            Rectangle {
                Layout.preferredWidth: 44
                Layout.preferredHeight: 44
                radius: 22
                color: Qt.rgba(0, 0, 0, 0.65)
                Text {
                    anchors.centerIn: parent
                    text: "-15s"
                    color: "white"
                    font.pixelSize: 11
                    font.bold: true
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: mpvItem.seek(mpvItem.sessionPosition - 15)
                }
            }

            // LIVE + delay
            ColumnLayout {
                spacing: 2
                Layout.alignment: Qt.AlignVCenter

                Rectangle {
                    id: liveBtn
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredHeight: 24
                    implicitWidth: liveLabel.implicitWidth + 16
                    radius: 4
                    color: isLive ? "#d32f2f" : Qt.rgba(1, 1, 1, 0.25)
                    property bool isLive: mpvItem.sessionDuration - mpvItem.sessionPosition < 5
                    Text {
                        id: liveLabel
                        anchors.centerIn: parent
                        text: qsTr("LIVE")
                        color: parent.isLive ? "white" : Qt.rgba(1, 1, 1, 0.6)
                        font.pixelSize: 11
                        font.bold: true
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: !liveBtn.isLive
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: mpvItem.reload()
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    visible: root.channelUrl !== "" && mpvItem.sessionDuration > 0 && !liveBtn.isLive
                    text: {
                        var delta = mpvItem.sessionDuration - mpvItem.sessionPosition
                        if (delta < 1) return ""
                        var totalSec = Math.round(delta)
                        var h = Math.floor(totalSec / 3600)
                        var m = Math.floor((totalSec % 3600) / 60)
                        var s = totalSec % 60
                        var sign = "-"
                        if (h > 0)
                            return sign + h + ":" + (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s
                        if (m > 0)
                            return sign + m + ":" + (s < 10 ? "0" : "") + s
                        return sign + s + "s"
                    }
                    color: Qt.rgba(1, 1, 1, 0.5)
                    font.pixelSize: 10
                }
            }

            // +15s (opacity hide/show to keep layout fixed)
            Rectangle {
                Layout.preferredWidth: 44
                Layout.preferredHeight: 44
                radius: 22
                color: Qt.rgba(0, 0, 0, 0.65)
                opacity: liveBtn.isLive ? 0.0 : 1.0
                enabled: !liveBtn.isLive
                Text {
                    anchors.centerIn: parent
                    text: "+15s"
                    color: "white"
                    font.pixelSize: 11
                    font.bold: true
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: mpvItem.seek(mpvItem.sessionPosition + 15)
                }
            }
        }
    }

    // ── Right-click context menu ──
    Menu {
        id: contextMenu

        Menu {
            id: audioTrackMenu
            title: qsTr("Audio Track")
            onAboutToShow: root.buildTrackMenu(audioTrackMenu, mpvItem.audioTracks, true)
        }

        Menu {
            id: subtitleTrackMenu
            title: qsTr("Subtitle Track")
            onAboutToShow: root.buildTrackMenu(subtitleTrackMenu, mpvItem.subtitleTracks, false)
        }

        MenuSeparator {}

        Menu {
            id: hwdecMenu
            title: qsTr("Hardware Decoding")

            MenuItem {
                text: "auto"
                checkable: true
                checked: mpvItem.hwdec === "auto"
                onTriggered: root.hwdecChangeRequested("auto")
            }
            MenuItem {
                text: "no"
                checkable: true
                checked: mpvItem.hwdec === "no"
                onTriggered: root.hwdecChangeRequested("no")
            }
            MenuItem {
                text: "d3d11va"
                checkable: true
                checked: mpvItem.hwdec === "d3d11va"
                onTriggered: root.hwdecChangeRequested("d3d11va")
            }
            MenuItem {
                text: "nvdec"
                checkable: true
                checked: mpvItem.hwdec === "nvdec"
                onTriggered: root.hwdecChangeRequested("nvdec")
            }
        }

        MenuSeparator {}

        MenuItem {
            text: qsTr("Info...")
            onTriggered: infoPopup.open()
        }
    }

    Component {
        id: trackItemComponent
        MenuItem { checkable: true }
    }

    Component {
        id: trackSeparatorComponent
        MenuSeparator {}
    }

    function buildTrackMenu(menu, tracks, isAudio) {
        while (menu.count > 0)
            menu.removeItem(menu.itemAt(0))

        if (!isAudio) {
            var offItem = trackItemComponent.createObject(menu, { text: qsTr("Off") }) as MenuItem
            offItem.checked = (root.currentSubtitleTrackLabel === "")
            offItem.triggered.connect(function() { mpvItem.setSubtitleTrack(-1) })
            menu.addItem(offItem)
            menu.addItem(trackSeparatorComponent.createObject(menu))
        }

        tracks.forEach(function(track) {
            var tid = track.id
            var label = track.label
            if (label === undefined || label === null || label === "")
                label = (tid !== undefined && tid !== null) ? qsTr("Track %1").arg(tid) : qsTr("Unknown")
            var item = trackItemComponent.createObject(menu, { text: label }) as MenuItem
            item.checked = !!track.selected
            if (isAudio)
                item.triggered.connect(function() { mpvItem.setAudioTrack(tid) })
            else
                item.triggered.connect(function() { mpvItem.setSubtitleTrack(tid) })
            menu.addItem(item)
        })
    }

    // ── Info popup ──
    Popup {
        id: infoPopup
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        x: Math.round((root.width - width) / 2)
        y: Math.round((root.height - height) / 2)
        width: 280
        height: infoColumn.implicitHeight + 40
        padding: 16

        background: Rectangle {
            color: "#1a1a2e"
            radius: 8
            border.color: "#0f3460"
            border.width: 1
        }

        ColumnLayout {
            id: infoColumn
            anchors.fill: parent
            spacing: 8

            Text {
                text: qsTr("Channel Info")
                color: "#e0e0e0"
                font.pixelSize: 14
                font.bold: true
            }

            Rectangle { Layout.preferredHeight: 1; color: "#0f3460"; Layout.fillWidth: true }

            RowLayout {
                spacing: 8
                Text { text: qsTr("Name:"); color: "#a0a0a0"; font.pixelSize: 11 }
                Text { text: root.channelName; color: "#e0e0e0"; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
            }

            RowLayout {
                spacing: 8
                Text { text: qsTr("Group:"); color: "#a0a0a0"; font.pixelSize: 11 }
                Text { text: root.channelGroup; color: "#e0e0e0"; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
            }

            ColumnLayout {
                spacing: 4
                Text { text: qsTr("URL:"); color: "#a0a0a0"; font.pixelSize: 11 }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 28
                    color: "#0f3460"
                    radius: 4

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        anchors.rightMargin: 4
                        anchors.topMargin: 0
                        anchors.bottomMargin: 0
                        spacing: 4

                        Text {
                            text: root.channelUrl
                            color: "#4a90d9"
                            font.pixelSize: 10
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            Layout.preferredWidth: 20
                            Layout.preferredHeight: 20
                            radius: 4
                            color: Qt.rgba(1,1,1,0.15)
                            Text {
                                anchors.centerIn: parent
                                text: "\u2398"
                                color: "white"
                                font.pixelSize: 11
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    ClipboardHelper.copyText(root.channelUrl)
                                    copyFeedback.visible = true
                                    hideFeedback.restart()
                                }
                            }
                        }
                    }
                }

                Text {
                    id: copyFeedback
                    text: qsTr("Copied!")
                    color: "#4a90d9"
                    font.pixelSize: 10
                    visible: false
                }

                Timer {
                    id: hideFeedback
                    interval: 1500
                    onTriggered: copyFeedback.visible = false
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

    // ── Quality variant popup ──
    Popup {
        id: qualityPopup
        x: qualityBadge.x
        y: qualityBadge.y - implicitHeight - 8
        width: 280
        implicitHeight: qualityListColumn.implicitHeight + 24
        padding: 8
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: "#1a1a2e"
            radius: 6
            border.color: "#0f3460"
            border.width: 1
        }

        ColumnLayout {
            id: qualityListColumn
            anchors.fill: parent
            spacing: 6

            Text {
                text: qsTr("Quality Variants")
                color: "#808080"
                font.pixelSize: 10
                font.bold: true
            }

            Rectangle {
                Layout.preferredHeight: 1
                color: "#0f3460"
                Layout.fillWidth: true
            }

            ListView {
                id: qualityListView
                Layout.fillWidth: true
                Layout.preferredHeight: contentHeight
                interactive: contentHeight > 260
                clip: true
                model: ListModel { id: qualityListModel }
                delegate: Rectangle {
                    id: variantRow

                    required property var model

                    width: qualityListView.width
                    height: 44
                    radius: 4
                    color: mouseArea.containsMouse ? "#0f3460" : "transparent"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 2

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                text: variantRow.model.label
                                color: variantRow.model.isCurrent ? "#4a90d9" : "#e0e0e0"
                                font.pixelSize: 12
                                font.bold: variantRow.model.isCurrent
                                Layout.minimumWidth: implicitWidth
                            }

                            Text {
                                text: variantRow.model.name
                                color: "#a0a0a0"
                                font.pixelSize: 10
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: variantRow.model.isCurrent ? "\u2713" : ""
                                color: "#4a90d9"
                                font.pixelSize: 13
                                visible: variantRow.model.isCurrent
                            }
                        }

                        Text {
                            text: variantRow.model.group || ""
                            color: "#606060"
                            font.pixelSize: 10
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            visible: (variantRow.model.group || "") !== ""
                        }
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!variantRow.model.isCurrent) {
                                root.channelUrl = variantRow.model.url
                                root.channelName = variantRow.model.name
                                root.channelLogo = variantRow.model.logo
                                root.variantSwitchRequested(variantRow.model.url, variantRow.model.name, variantRow.model.logo)
                            }
                            qualityPopup.close()
                        }
                    }
                }
            }
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        z: 100
        propagateComposedEvents: true
        cursorShape: Qt.PointingHandCursor
        onPositionChanged: {
            if (root.controlsOpacity < 0.5)
                root.showControls()
        }
        onDoubleClicked: root.doubleClickRequested()
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        z: 101
        onClicked: (mouse) => contextMenu.popup(mouse.x, mouse.y)
    }
}

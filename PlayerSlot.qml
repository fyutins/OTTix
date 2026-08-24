pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    color: Theme.videoBg
    clip: true

    property int slotIndex: 0
    property string channelName: ""
    property string channelUrl: ""
    property string channelLogo: ""
    property string channelGroup: ""
    property bool isActiveAudio: false
    property bool multiplexed: false
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

    function doPlay() { mpvItem.play() }
    function doPause() { mpvItem.pause() }

    MpvObject {
        id: mpvItem
        anchors.fill: parent
        source: root.channelUrl
        volume: Math.pow(root.globalVolume / 100.0, 1.1) * 100.0
        muted: !root.isActiveAudio
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.videoBg
        visible: root.channelUrl === ""
        z: 1
    }

    BusyIndicator {
        anchors.centerIn: parent
        running: mpvItem.loading && root.channelUrl !== ""
        z: 2
        palette {
            dark: Theme.scrimText
            mid: Theme.accent
        }
    }

    // Double-clic sur la video : plein ecran. Volontairement **sous** la couche
    // de controles (z: 0) pour que les boutons recoivent l'appui les premiers ;
    // une MouseArea pleine surface posee au-dessus le capterait et les boutons
    // (Controls) ne seraient plus cliquables.
    MouseArea {
        id: doubleClickArea
        anchors.fill: parent
        z: 0
        onDoubleClicked: root.doubleClickRequested()
    }

    // Liseré sur le slot dont on entend le son (utile en multiplex).
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: 2
        border.color: Theme.accent
        radius: 2
        visible: root.multiplexed && root.isActiveAudio && root.channelUrl !== ""
        z: 5
    }

    property real controlsOpacity: 1.0

    Timer {
        id: hideTimer
        interval: 3000
        onTriggered: {
            // Ne rien masquer tant qu'un menu ou une bulle est ouvert.
            if (qualityPopup.opened || infoPopup.opened || contextMenu.opened) {
                hideTimer.restart()
                return
            }
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
        Behavior on opacity { NumberAnimation { duration: Theme.durSlow } }

        // ── Barre basse : logo, nom, qualite, rechargement, audio ──
        Rectangle {
            id: bottomBar
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 44
            visible: root.channelUrl !== ""
            z: 4

            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.45; color: Theme.scrim }
                GradientStop { position: 1.0; color: Theme.scrimStrong }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.spacingMd
                anchors.rightMargin: Theme.spacingSm
                spacing: Theme.spacingSm

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
                    color: Theme.scrimText
                    font.pixelSize: Theme.fontSm
                    font.bold: true
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                // ── Pastille de qualite (variantes) ──
                Rectangle {
                    id: qualityBadge
                    Layout.preferredWidth: qualityRow.implicitWidth + Theme.spacingMd
                    Layout.preferredHeight: Theme.controlXs
                    radius: Theme.radiusSm
                    color: qualityMouse.containsMouse ? Theme.glassHover : Theme.glass
                    border.width: 1
                    border.color: qualityMouse.containsMouse ? Theme.accent : Theme.scrimTextDim
                    visible: root.channelUrl !== "" && ChannelListModel.channelHasVariants(root.channelUrl)

                    property string currentLabel: ""

                    Behavior on color { ColorAnimation { duration: Theme.durFast } }
                    Behavior on border.color { ColorAnimation { duration: Theme.durFast } }

                    Row {
                        id: qualityRow
                        anchors.centerIn: parent
                        spacing: Theme.spacingXs

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: qualityBadge.currentLabel.length > 0 ? qualityBadge.currentLabel : qsTr("SD")
                            color: Theme.scrimText
                            font.pixelSize: Theme.fontXs
                            font.bold: true
                        }

                        MdiIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            glyph: qualityPopup.opened ? Mdi.chevronDown : Mdi.chevronUp
                            font.pixelSize: Theme.iconXs
                            color: Theme.scrimTextMuted
                        }
                    }

                    MouseArea {
                        id: qualityMouse
                        anchors.fill: parent
                        hoverEnabled: true
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
                            qualityPopup.showFrom(qualityBadge)
                        }
                    }

                    Tip {
                        visible: qualityMouse.containsMouse && !qualityPopup.opened
                        text: qsTr("Quality variants")
                    }
                }

                IconButton {
                    implicitWidth: Theme.controlSm
                    implicitHeight: Theme.controlSm
                    round: true
                    tinted: true
                    glyph: Mdi.refresh
                    glyphSize: Theme.iconSm
                    tooltip: qsTr("Reload the stream")
                    onClicked: mpvItem.reload()
                }

                IconButton {
                    implicitWidth: Theme.controlSm
                    implicitHeight: Theme.controlSm
                    round: true
                    tinted: true
                    checkable: true
                    checked: root.isActiveAudio
                    glyph: root.isActiveAudio ? Mdi.volumeHigh : Mdi.volumeOff
                    glyphSize: Theme.iconSm
                    glyphColor: Theme.scrimTextMuted
                    tooltip: root.isActiveAudio ? qsTr("Audio on this screen")
                                                : qsTr("Listen to this screen")
                    onClicked: root.audioToggleRequested(root.slotIndex)
                }
            }
        }

        // ── Centre : parcourir (haut) · precedent / lecture / suivant ──
        Item {
            anchors.centerIn: parent
            width: centerColumn.implicitWidth
            height: centerColumn.implicitHeight
            z: 3

            ColumnLayout {
                id: centerColumn
                spacing: Theme.spacingMd
                visible: root.channelUrl !== ""

                IconButton {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: Theme.controlLg
                    implicitHeight: Theme.controlLg
                    round: true
                    tinted: true
                    dark: true
                    glyph: Mdi.remoteTv
                    tooltip: qsTr("Change the channel on this screen")
                    onClicked: root.pickRequested(root.slotIndex)
                }

                RowLayout {
                    spacing: Theme.spacingMd
                    Layout.alignment: Qt.AlignHCenter

                    IconButton {
                        implicitWidth: 44
                        implicitHeight: 44
                        round: true
                        tinted: true
                        dark: true
                        glyph: Mdi.skipPrevious
                        glyphSize: Theme.iconLg
                        tooltip: qsTr("Previous channel")
                        onClicked: root.prevRequested()
                    }

                    IconButton {
                        implicitWidth: 56
                        implicitHeight: 56
                        round: true
                        tinted: true
                        dark: true
                        glyph: mpvItem.playing ? Mdi.pause : Mdi.play
                        glyphSize: Theme.iconXl
                        tooltip: mpvItem.playing ? qsTr("Pause (Space)") : qsTr("Play (Space)")
                        onClicked: {
                            if (mpvItem.playing) mpvItem.pause()
                            else mpvItem.play()
                        }
                    }

                    IconButton {
                        implicitWidth: 44
                        implicitHeight: 44
                        round: true
                        tinted: true
                        dark: true
                        glyph: Mdi.skipNext
                        glyphSize: Theme.iconLg
                        tooltip: qsTr("Next channel")
                        onClicked: root.nextRequested()
                    }
                }
            }
        }

        // ── -15s · LIVE · +15s (au-dessus de la barre basse) ──
        RowLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: bottomBar.top
            anchors.bottomMargin: Theme.spacingMd
            spacing: Theme.spacingLg
            visible: root.channelUrl !== "" && mpvItem.sessionDuration > 0
            z: 3

            IconButton {
                implicitWidth: 40
                implicitHeight: 40
                round: true
                tinted: true
                dark: true
                glyph: Mdi.rewind15
                glyphSize: Theme.iconLg
                tooltip: qsTr("Back 15 seconds")
                onClicked: mpvItem.seek(mpvItem.sessionPosition - 15)
            }

            ColumnLayout {
                spacing: 2
                Layout.alignment: Qt.AlignVCenter

                Rectangle {
                    id: liveBtn
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredHeight: Theme.controlXs
                    implicitWidth: liveRow.implicitWidth + Theme.spacingMd
                    radius: Theme.radiusSm
                    color: isLive ? Theme.live : Theme.glassDark
                    property bool isLive: mpvItem.sessionDuration - mpvItem.sessionPosition < 5

                    Behavior on color { ColorAnimation { duration: Theme.durNormal } }

                    Row {
                        id: liveRow
                        anchors.centerIn: parent
                        spacing: Theme.spacingXs

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 6
                            height: 6
                            radius: 3
                            color: liveBtn.isLive ? Theme.scrimText : Theme.scrimTextDim
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: qsTr("LIVE")
                            color: liveBtn.isLive ? Theme.scrimText : Theme.scrimTextMuted
                            font.pixelSize: Theme.fontSm
                            font.bold: true
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !liveBtn.isLive
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: mpvItem.reload()
                    }

                    HoverHandler { id: liveHover }

                    Tip {
                        visible: !liveBtn.isLive && liveHover.hovered
                        text: qsTr("Back to live")
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
                    color: Theme.scrimTextMuted
                    font.pixelSize: Theme.fontXs
                }
            }

            // Masque par l'opacite pour garder la rangee stable en direct.
            IconButton {
                implicitWidth: 40
                implicitHeight: 40
                round: true
                tinted: true
                dark: true
                glyph: Mdi.fastForward15
                glyphSize: Theme.iconLg
                opacity: liveBtn.isLive ? 0.0 : 1.0
                enabled: !liveBtn.isLive
                tooltip: qsTr("Forward 15 seconds")
                onClicked: mpvItem.seek(mpvItem.sessionPosition + 15)
            }
        }
    }

    // ── Menu contextuel (clic droit) ──
    AppMenu {
        id: contextMenu

        AppMenu {
            id: audioTrackMenu
            title: qsTr("Audio Track")
            onAboutToShow: root.buildTrackMenu(audioTrackMenu, mpvItem.audioTracks, true)
        }

        AppMenu {
            id: subtitleTrackMenu
            title: qsTr("Subtitle Track")
            onAboutToShow: root.buildTrackMenu(subtitleTrackMenu, mpvItem.subtitleTracks, false)
        }

        MenuSeparator {}

        AppMenu {
            id: hwdecMenu
            title: qsTr("Hardware Decoding")

            AppMenuItem {
                text: "auto"
                checkable: true
                checked: mpvItem.hwdec === "auto"
                onTriggered: root.hwdecChangeRequested("auto")
            }
            AppMenuItem {
                text: "no"
                checkable: true
                checked: mpvItem.hwdec === "no"
                onTriggered: root.hwdecChangeRequested("no")
            }
            AppMenuItem {
                text: "d3d11va"
                checkable: true
                checked: mpvItem.hwdec === "d3d11va"
                onTriggered: root.hwdecChangeRequested("d3d11va")
            }
            AppMenuItem {
                text: "nvdec"
                checkable: true
                checked: mpvItem.hwdec === "nvdec"
                onTriggered: root.hwdecChangeRequested("nvdec")
            }
        }

        MenuSeparator {}

        AppMenuItem {
            text: qsTr("Reload the stream")
            glyph: Mdi.refresh
            onTriggered: mpvItem.reload()
        }

        AppMenuItem {
            text: qsTr("Info...")
            glyph: Mdi.information
            onTriggered: infoPopup.open()
        }
    }

    Component {
        id: trackItemComponent
        AppMenuItem { checkable: true }
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

    // ── Informations sur la chaine ──
    Popup {
        id: infoPopup
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        parent: Overlay.overlay
        anchors.centerIn: Overlay.overlay
        width: 420
        implicitHeight: infoColumn.implicitHeight + padding * 2
        padding: Theme.spacingLg

        background: Rectangle {
            color: Theme.surface
            radius: Theme.radiusMd
            border.color: Theme.border
            border.width: 1
        }

        ColumnLayout {
            id: infoColumn
            anchors.fill: parent
            spacing: Theme.spacingSm

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingSm

                MdiIcon {
                    glyph: Mdi.information
                    font.pixelSize: Theme.iconMd
                    color: Theme.accent
                }

                Text {
                    Layout.fillWidth: true
                    text: qsTr("Channel Info")
                    color: Theme.text
                    font.pixelSize: Theme.fontLg
                    font.bold: true
                }

                IconButton {
                    implicitWidth: Theme.controlSm
                    implicitHeight: Theme.controlSm
                    glyph: Mdi.close
                    glyphSize: Theme.iconSm
                    glyphColor: Theme.textMuted
                    onClicked: infoPopup.close()
                }
            }

            Rectangle { Layout.preferredHeight: 1; color: Theme.border; Layout.fillWidth: true }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingSm
                Text { text: qsTr("Name:"); color: Theme.textDim; font.pixelSize: Theme.fontMd }
                Text {
                    text: root.channelName; color: Theme.text; font.pixelSize: Theme.fontMd
                    Layout.fillWidth: true; elide: Text.ElideRight
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingSm
                Text { text: qsTr("Group:"); color: Theme.textDim; font.pixelSize: Theme.fontMd }
                Text {
                    text: root.channelGroup; color: Theme.text; font.pixelSize: Theme.fontMd
                    Layout.fillWidth: true; elide: Text.ElideRight
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingXs

                Text { text: qsTr("URL:"); color: Theme.textDim; font.pixelSize: Theme.fontMd }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.controlMd
                    color: Theme.surfaceAlt
                    radius: Theme.radiusSm
                    border.width: 1
                    border.color: Theme.border

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.spacingSm
                        anchors.rightMargin: Theme.spacingXs
                        spacing: Theme.spacingXs

                        Text {
                            text: root.channelUrl
                            color: Theme.accent
                            font.pixelSize: Theme.fontSm
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        IconButton {
                            implicitWidth: Theme.controlSm
                            implicitHeight: Theme.controlSm
                            glyph: Mdi.copy
                            glyphSize: Theme.iconSm
                            glyphColor: Theme.textMuted
                            tooltip: qsTr("Copy the URL")
                            onClicked: {
                                ClipboardHelper.copyText(root.channelUrl)
                                copyFeedback.visible = true
                                hideFeedback.restart()
                            }
                        }
                    }
                }

                RowLayout {
                    spacing: Theme.spacingXs
                    visible: copyFeedback.visible

                    MdiIcon {
                        glyph: Mdi.checkCircle
                        font.pixelSize: Theme.iconXs
                        color: Theme.success
                    }

                    Text {
                        id: copyFeedback
                        text: qsTr("Copied!")
                        color: Theme.success
                        font.pixelSize: Theme.fontSm
                        visible: false
                    }
                }

                Timer {
                    id: hideFeedback
                    interval: 1500
                    onTriggered: copyFeedback.visible = false
                }
            }
        }
    }

    // ── Slot vide : invite a choisir une chaine ──
    Rectangle {
        anchors.centerIn: parent
        width: 200
        height: 116
        radius: Theme.radiusMd
        color: emptyMouse.containsMouse ? Theme.glassDarkHover : Theme.glassDark
        border.width: 1
        border.color: emptyMouse.containsMouse ? Theme.accent : Theme.scrimTextDim
        visible: root.channelUrl === ""
        z: 2

        Behavior on color { ColorAnimation { duration: Theme.durFast } }
        Behavior on border.color { ColorAnimation { duration: Theme.durFast } }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: Theme.spacingSm

            MdiIcon {
                Layout.alignment: Qt.AlignHCenter
                glyph: Mdi.plusCircle
                font.pixelSize: Theme.iconXl
                color: emptyMouse.containsMouse ? Theme.accent : Theme.scrimTextMuted

                Behavior on color { ColorAnimation { duration: Theme.durFast } }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Choose a channel")
                color: Theme.scrimTextMuted
                font.pixelSize: Theme.fontMd
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Screen %1").arg(root.slotIndex + 1)
                color: Theme.scrimTextDim
                font.pixelSize: Theme.fontSm
            }
        }

        MouseArea {
            id: emptyMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.pickRequested(root.slotIndex)
        }
    }

    // ── Variantes de qualite ──
    // Positionnee dans l'overlay de la fenetre, jamais dans le slot : la bulle
    // reste ainsi entierement visible meme quand le slot est petit ou colle a
    // un bord. La hauteur est deduite du nombre d'items pour que le calcul de
    // position soit juste des la premiere ouverture.
    Popup {
        id: qualityPopup
        parent: Overlay.overlay
        width: 320
        padding: Theme.spacingSm
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        readonly property int rowHeight: 46
        readonly property int listHeight: Math.min(qualityListModel.count * rowHeight, 276)

        property point anchorPoint: Qt.point(0, 0)
        property real anchorHeight: 0

        implicitHeight: qualityHeader.implicitHeight + listHeight
                        + Theme.spacingSm * 2 + padding * 2 + 1

        function showFrom(item) {
            var p = item.mapToItem(qualityPopup.parent, item.width, 0)
            qualityPopup.anchorPoint = p
            qualityPopup.anchorHeight = item.height
            qualityPopup.open()
            qualityPopup.reposition()
        }

        // Aligne le coin bas-droit sur le badge, bascule sous le badge s'il n'y
        // a pas la place au-dessus, puis borne le tout a la fenetre.
        function reposition() {
            if (!qualityPopup.parent)
                return
            var m = Theme.spacingSm
            var wantX = qualityPopup.anchorPoint.x - qualityPopup.width
            var wantY = qualityPopup.anchorPoint.y - qualityPopup.height - m
            if (wantY < m)
                wantY = qualityPopup.anchorPoint.y + qualityPopup.anchorHeight + m
            qualityPopup.x = Math.max(m, Math.min(wantX, qualityPopup.parent.width - qualityPopup.width - m))
            qualityPopup.y = Math.max(m, Math.min(wantY, qualityPopup.parent.height - qualityPopup.height - m))
        }

        onHeightChanged: reposition()
        onOpened: reposition()

        background: Rectangle {
            color: Theme.surface
            radius: Theme.radiusMd
            border.color: Theme.border
            border.width: 1
        }

        contentItem: ColumnLayout {
            id: qualityListColumn
            spacing: Theme.spacingSm

            RowLayout {
                id: qualityHeader
                Layout.fillWidth: true
                spacing: Theme.spacingXs

                MdiIcon {
                    glyph: Mdi.highDefinition
                    font.pixelSize: Theme.iconSm
                    color: Theme.textDim
                }

                Text {
                    Layout.fillWidth: true
                    text: qsTr("Quality Variants")
                    color: Theme.textDim
                    font.pixelSize: Theme.fontSm
                    font.bold: true
                }
            }

            Rectangle {
                Layout.preferredHeight: 1
                Layout.fillWidth: true
                color: Theme.border
            }

            ListView {
                id: qualityListView
                Layout.fillWidth: true
                Layout.preferredHeight: qualityPopup.listHeight
                interactive: contentHeight > height
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: ListModel { id: qualityListModel }

                ScrollBar.vertical: AppScrollBar {}

                delegate: Rectangle {
                    id: variantRow

                    required property var model

                    width: qualityListView.width
                    height: qualityPopup.rowHeight
                    radius: Theme.radiusSm
                    color: variantMouse.containsMouse ? Theme.surfaceHi
                         : variantRow.model.isCurrent ? Theme.accentSoft : "transparent"

                    Behavior on color { ColorAnimation { duration: Theme.durFast } }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.spacingSm
                        anchors.rightMargin: Theme.spacingSm
                        spacing: 2

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spacingXs

                            Text {
                                text: variantRow.model.label
                                color: variantRow.model.isCurrent ? Theme.accent : Theme.text
                                font.pixelSize: Theme.fontMd
                                font.bold: variantRow.model.isCurrent
                                Layout.minimumWidth: implicitWidth
                            }

                            Text {
                                text: variantRow.model.name
                                color: Theme.textMuted
                                font.pixelSize: Theme.fontXs
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            MdiIcon {
                                glyph: Mdi.check
                                font.pixelSize: Theme.iconSm
                                color: Theme.accent
                                visible: variantRow.model.isCurrent
                            }
                        }

                        Text {
                            text: variantRow.model.group || ""
                            color: Theme.textDim
                            font.pixelSize: Theme.fontXs
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            visible: (variantRow.model.group || "") !== ""
                        }
                    }

                    MouseArea {
                        id: variantMouse
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

    // Le survol reveille les controles. Un HoverHandler et non une MouseArea
    // pleine surface : la MouseArea capterait l'appui et les boutons (Controls)
    // ne le recevraient jamais. `propagateComposedEvents` ne rattrape pas ce
    // cas — il ne repropage les evenements composes qu'a d'autres MouseArea.
    HoverHandler {
        id: hoverHandler
        onPointChanged: {
            if (root.controlsOpacity < 0.5)
                root.showControls()
        }
    }

    // Clic droit : un TapHandler et non une MouseArea pleine surface. Posee
    // au-dessus des controles, celle-ci laissait bien passer les clics gauches
    // mais devenait l'element le plus haut sous le curseur : le curseur des
    // boutons (HoverHandler) n'etait plus applique et la main ne s'affichait
    // jamais. Un handler observe sans s'interposer.
    TapHandler {
        acceptedButtons: Qt.RightButton
        gesturePolicy: TapHandler.ReleaseWithinBounds
        onTapped: (eventPoint) => {
            root.showControls()
            contextMenu.popup(eventPoint.position.x, eventPoint.position.y)
        }
    }
}

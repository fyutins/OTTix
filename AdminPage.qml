pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    color: Theme.bg

    signal backRequested()
    signal playlistsChanged()

    property int pendingDeleteId: -1
    property string pendingDeleteName: ""

    PlaylistLoader {
        id: loader
        onLoadComplete: (playlistId, channelCount) => {
            root.loadingPlaylistId = -1
            ChannelListModel.setChannels(playlistId)
            PlaylistModel.refresh()
            root.playlistsChanged()
        }
        onLoadError: (playlistId, error) => {
            root.loadingPlaylistId = -1
            root.errorText = error
        }
    }

    property int loadingPlaylistId: -1
    property string errorText: ""

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── En-tete ──
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.toolbarHeight
            color: Theme.surface

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.spacingSm
                anchors.rightMargin: Theme.spacingSm
                spacing: Theme.spacingSm

                IconButton {
                    glyph: Mdi.arrowLeft
                    glyphColor: Theme.accent
                    tooltip: qsTr("Back")
                    onClicked: root.backRequested()
                }

                Label {
                    text: qsTr("Administration")
                    color: Theme.text
                    font.pixelSize: Theme.fontLg
                    font.bold: true
                }

                Item { Layout.fillWidth: true }
            }
        }

        // ── Onglets ──
        AppTabBar {
            id: adminTabBar
            Layout.fillWidth: true

            AppTabButton { text: qsTr("Playlists"); glyph: Mdi.playlistPlay }
            AppTabButton { text: qsTr("Settings"); glyph: Mdi.cogOutline }
        }

        // Bandeau d'erreur du dernier chargement
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: root.errorText !== "" ? Theme.controlLg : 0
            visible: root.errorText !== ""
            color: Theme.dangerSoft
            clip: true

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.spacingMd
                anchors.rightMargin: Theme.spacingSm
                spacing: Theme.spacingSm

                MdiIcon {
                    glyph: Mdi.alert
                    font.pixelSize: Theme.iconSm
                    color: Theme.danger
                }

                Text {
                    Layout.fillWidth: true
                    text: root.errorText
                    color: Theme.danger
                    font.pixelSize: Theme.fontMd
                    elide: Text.ElideRight
                }

                IconButton {
                    implicitWidth: Theme.controlSm
                    implicitHeight: Theme.controlSm
                    glyph: Mdi.close
                    glyphSize: Theme.iconSm
                    glyphColor: Theme.danger
                    onClicked: root.errorText = ""
                }
            }
        }

        // ── Contenu ──
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: adminTabBar.currentIndex

            // ── Onglet Playlists ──
            Item {
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingLg
                    spacing: Theme.spacingMd

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacingSm

                        Text {
                            Layout.fillWidth: true
                            text: qsTr("%1 playlist(s)").arg(PlaylistModel.count)
                            color: Theme.textMuted
                            font.pixelSize: Theme.fontMd
                        }

                        AppButton {
                            text: qsTr("Add Playlist")
                            glyph: Mdi.plus
                            variant: AppButton.Primary
                            onClicked: playlistDialog.open()
                        }
                    }

                    ListView {
                        id: playlistView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        model: PlaylistModel
                        delegate: playlistDelegate
                        spacing: Theme.spacingSm
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        ScrollBar.vertical: AppScrollBar {}

                        EmptyState {
                            anchors.centerIn: parent
                            visible: playlistView.count === 0
                            glyph: Mdi.playlistPlay
                            title: qsTr("No playlists yet")
                            subtitle: qsTr("Add an M3U or Xtream playlist to get started")
                        }
                    }

                    Component {
                        id: playlistDelegate

                        Rectangle {
                            id: playlistRow

                            required property var model

                            readonly property bool isLoading: root.loadingPlaylistId === playlistRow.model.playlistId

                            width: ListView.view ? ListView.view.width : implicitWidth
                            height: 72
                            color: rowHover.hovered ? Theme.surfaceHi : Theme.surfaceAlt
                            border.color: rowHover.hovered ? Theme.borderStrong : Theme.border
                            border.width: 1
                            radius: Theme.radiusMd

                            Behavior on color { ColorAnimation { duration: Theme.durFast } }

                            HoverHandler { id: rowHover }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: Theme.spacingMd
                                anchors.rightMargin: Theme.spacingSm
                                spacing: Theme.spacingMd

                                Rectangle {
                                    Layout.preferredWidth: Theme.controlLg
                                    Layout.preferredHeight: Theme.controlLg
                                    radius: Theme.radiusSm
                                    color: Theme.bg

                                    MdiIcon {
                                        anchors.centerIn: parent
                                        glyph: playlistRow.model.type === "xtream" ? Mdi.server : Mdi.link
                                        font.pixelSize: Theme.iconMd
                                        color: Theme.accent
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Label {
                                        Layout.fillWidth: true
                                        text: playlistRow.model.name
                                        color: Theme.text
                                        font.pixelSize: Theme.fontLg
                                        font.bold: true
                                        elide: Text.ElideRight
                                    }

                                    RowLayout {
                                        spacing: Theme.spacingSm

                                        Rectangle {
                                            Layout.preferredWidth: typeLabel.implicitWidth + Theme.spacingSm
                                            Layout.preferredHeight: 18
                                            radius: Theme.radiusPill
                                            color: Theme.surface

                                            Text {
                                                id: typeLabel
                                                anchors.centerIn: parent
                                                text: playlistRow.model.type.toUpperCase()
                                                color: Theme.textMuted
                                                font.pixelSize: Theme.fontXs
                                                font.bold: true
                                            }
                                        }

                                        Label {
                                            text: playlistRow.model.channelCount + " " + qsTr("channels")
                                            color: Theme.textMuted
                                            font.pixelSize: Theme.fontSm
                                        }
                                    }
                                }

                                BusyIndicator {
                                    Layout.preferredWidth: Theme.controlSm
                                    Layout.preferredHeight: Theme.controlSm
                                    running: playlistRow.isLoading
                                    visible: running
                                    palette {
                                        dark: Theme.text
                                        mid: Theme.accent
                                    }
                                }

                                IconButton {
                                    glyph: Mdi.download
                                    enabled: root.loadingPlaylistId < 0
                                    tooltip: qsTr("Reload from the source")
                                    onClicked: {
                                        root.errorText = ""
                                        root.loadingPlaylistId = playlistRow.model.playlistId
                                        if (playlistRow.model.type === "m3u")
                                            loader.loadM3U(playlistRow.model.playlistId, playlistRow.model.url)
                                        else if (playlistRow.model.type === "xtream")
                                            loader.loadXtream(playlistRow.model.playlistId, playlistRow.model.url,
                                                               playlistRow.model.username, playlistRow.model.password)
                                    }
                                }

                                IconButton {
                                    glyph: Mdi.pencil
                                    tooltip: qsTr("Edit")
                                    onClicked: {
                                        playlistDialog.openForEdit(playlistRow.model.playlistId,
                                            playlistRow.model.name, playlistRow.model.url, playlistRow.model.type,
                                            playlistRow.model.username, playlistRow.model.password)
                                    }
                                }

                                IconButton {
                                    glyph: Mdi.trash
                                    danger: true
                                    glyphColor: Theme.danger
                                    tooltip: qsTr("Delete")
                                    onClicked: {
                                        root.pendingDeleteId = playlistRow.model.playlistId
                                        root.pendingDeleteName = playlistRow.model.name
                                        deleteDialog.open()
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── Onglet Reglages ──
            Flickable {
                contentHeight: settingsColumn.implicitHeight + Theme.spacingXl * 2
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: AppScrollBar {}

                ColumnLayout {
                    id: settingsColumn
                    x: Theme.spacingXl
                    y: Theme.spacingXl
                    width: Math.min(parent.width - Theme.spacingXl * 2, 900)
                    spacing: Theme.spacingLg

                    // ── Apparence ──
                    SettingsCard {
                        Layout.fillWidth: true
                        glyph: Mdi.themeAuto
                        title: qsTr("Appearance")

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spacingSm

                            Text {
                                Layout.fillWidth: true
                                text: qsTr("Auto follows the local time: light theme from %1:00, dark theme from %2:00.")
                                    .arg(Theme.dayStartHour).arg(Theme.nightStartHour)
                                color: Theme.textMuted
                                font.pixelSize: Theme.fontMd
                                wrapMode: Text.WordWrap
                            }

                            SegmentedControl {
                                options: [
                                    { label: qsTr("Auto"), glyph: Mdi.themeAuto, value: Theme.modeAuto },
                                    { label: qsTr("Light"), glyph: Mdi.themeLight, value: Theme.modeLight },
                                    { label: qsTr("Dark"), glyph: Mdi.themeDark, value: Theme.modeDark }
                                ]
                                currentValue: Theme.mode
                                onSelected: (value) => Theme.mode = value
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Theme.spacingXs
                                visible: Theme.mode === Theme.modeAuto

                                MdiIcon {
                                    glyph: Theme.dark ? Mdi.themeDark : Mdi.themeLight
                                    font.pixelSize: Theme.iconXs
                                    color: Theme.textDim
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: Theme.dark ? qsTr("Currently showing the dark theme")
                                                     : qsTr("Currently showing the light theme")
                                    color: Theme.textDim
                                    font.pixelSize: Theme.fontSm
                                }
                            }
                        }
                    }

                    // ── Base de donnees ──
                    SettingsCard {
                        Layout.fillWidth: true
                        glyph: Mdi.database
                        title: qsTr("Database")

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spacingSm

                            Text {
                                Layout.fillWidth: true
                                text: qsTr("Cached channel data can be cleared without losing your playlists, favorites or settings.")
                                color: Theme.textMuted
                                font.pixelSize: Theme.fontMd
                                wrapMode: Text.WordWrap
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Theme.spacingSm

                                AppButton {
                                    text: qsTr("Clear Cache")
                                    glyph: Mdi.broom
                                    onClicked: DatabaseManager.clearCache(0)
                                }

                                Item { Layout.fillWidth: true }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Theme.spacingXs

                                Text {
                                    text: qsTr("Location:")
                                    color: Theme.textDim
                                    font.pixelSize: Theme.fontSm
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: DatabaseManager.databasePath
                                    color: Theme.textDim
                                    font.pixelSize: Theme.fontSm
                                    wrapMode: Text.WrapAnywhere
                                }
                            }
                        }
                    }

                    // ── Suffixes de qualite ──
                    SettingsCard {
                        id: suffixCard
                        Layout.fillWidth: true
                        glyph: Mdi.label
                        title: qsTr("Quality Suffixes")

                        // Affichage alphabetique ; l'ordre de stockage, lui, est
                        // impose par le C++ (du plus long au plus court).
                        readonly property var sortedSuffixes:
                            ChannelListModel.qualitySuffixes.slice().sort(function(a, b) {
                                return a.toLowerCase().localeCompare(b.toLowerCase())
                            })

                        function addSuffix() {
                            var val = suffixInput.text.trim()
                            if (val.length === 0)
                                return
                            var arr = ChannelListModel.qualitySuffixes
                            arr.push(val)
                            ChannelListModel.qualitySuffixes = arr
                            suffixInput.text = ""
                        }

                        function removeSuffix(value) {
                            ChannelListModel.qualitySuffixes =
                                ChannelListModel.qualitySuffixes.filter(function(s) {
                                    return s !== value
                                })
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spacingSm

                            Text {
                                Layout.fillWidth: true
                                text: qsTr("Suffixes used to detect quality variants of the same channel (HD, FHD, H265…). Remove the ones that do not apply to your playlist, add your own — the change regroups the channels immediately.")
                                color: Theme.textMuted
                                font.pixelSize: Theme.fontMd
                                wrapMode: Text.WordWrap
                            }

                            Flow {
                                Layout.fillWidth: true
                                spacing: Theme.spacingSm
                                visible: suffixCard.sortedSuffixes.length > 0

                                Repeater {
                                    model: suffixCard.sortedSuffixes

                                    delegate: Rectangle {
                                        id: suffixChip

                                        required property string modelData

                                        width: chipRow.implicitWidth + Theme.spacingMd
                                        height: Theme.controlSm
                                        radius: Theme.radiusPill
                                        color: chipHover.hovered ? Theme.surfaceHi : Theme.surfaceAlt
                                        border.width: 1
                                        border.color: chipHover.hovered ? Theme.borderStrong : Theme.border

                                        Behavior on color { ColorAnimation { duration: Theme.durFast } }

                                        HoverHandler { id: chipHover }

                                        Row {
                                            id: chipRow
                                            anchors.centerIn: parent
                                            spacing: Theme.spacingXs

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: suffixChip.modelData
                                                color: Theme.text
                                                font.pixelSize: Theme.fontSm
                                                font.bold: true
                                            }

                                            IconButton {
                                                anchors.verticalCenter: parent.verticalCenter
                                                implicitWidth: Theme.iconMd
                                                implicitHeight: Theme.iconMd
                                                round: true
                                                danger: true
                                                glyph: Mdi.close
                                                glyphSize: Theme.iconXs
                                                glyphColor: Theme.textMuted
                                                tooltip: qsTr("Remove “%1”").arg(suffixChip.modelData)
                                                onClicked: suffixCard.removeSuffix(suffixChip.modelData)
                                            }
                                        }
                                    }
                                }
                            }

                            Text {
                                text: qsTr("No suffix left: channel variants are no longer grouped.")
                                color: Theme.warning
                                font.pixelSize: Theme.fontMd
                                visible: suffixCard.sortedSuffixes.length === 0
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Theme.spacingSm

                                TextField {
                                    id: suffixInput
                                    Layout.fillWidth: true
                                    Layout.maximumWidth: 260
                                    implicitHeight: Theme.controlMd
                                    leftPadding: Theme.spacingMd
                                    placeholderText: qsTr("e.g. HQ, LQ, 4K")
                                    placeholderTextColor: Theme.textDim
                                    color: Theme.text
                                    font.pixelSize: Theme.fontMd
                                    selectByMouse: true
                                    background: Rectangle {
                                        color: Theme.surfaceAlt
                                        radius: Theme.radiusSm
                                        border.color: suffixInput.activeFocus ? Theme.accent : Theme.border
                                        border.width: 1

                                        Behavior on border.color { ColorAnimation { duration: Theme.durFast } }
                                    }
                                    onAccepted: suffixCard.addSuffix()
                                }

                                AppButton {
                                    text: qsTr("Add")
                                    glyph: Mdi.plus
                                    enabled: suffixInput.text.trim().length > 0
                                    onClicked: suffixCard.addSuffix()
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: qsTr("%1 suffixes").arg(suffixCard.sortedSuffixes.length)
                                    color: Theme.textDim
                                    font.pixelSize: Theme.fontSm
                                }

                                AppButton {
                                    text: qsTr("Reset")
                                    glyph: Mdi.restart
                                    variant: AppButton.Ghost
                                    onClicked: ChannelListModel.resetQualitySuffixes()
                                }
                            }
                        }
                    }

                    // ── A propos ──
                    SettingsCard {
                        Layout.fillWidth: true
                        glyph: Mdi.information
                        title: qsTr("About")

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spacingXs

                            Label {
                                text: qsTr("IPTV Player v0.1")
                                color: Theme.text
                                font.pixelSize: Theme.fontMd
                            }

                            Label {
                                text: qsTr("Supports M3U playlists and XTREAM API")
                                color: Theme.textMuted
                                font.pixelSize: Theme.fontMd
                            }

                            Label {
                                text: qsTr("Icons: Material Design Icons (Pictogrammers)")
                                color: Theme.textDim
                                font.pixelSize: Theme.fontSm
                            }
                        }
                    }
                }
            }
        }
    }

    PlaylistDialog {
        id: playlistDialog
        onPlaylistAdded: (name, url, type, username, password) => {
            PlaylistModel.addPlaylist(name, url, type, username, password)
            root.playlistsChanged()
        }
        onPlaylistEdited: (id, name, url, type, username, password) => {
            PlaylistModel.updatePlaylist(id, name, url, type, username, password)
            root.playlistsChanged()
        }
    }

    ConfirmDialog {
        id: deleteDialog
        glyph: Mdi.trash
        title: qsTr("Delete playlist")
        message: qsTr("Delete “%1” and all its channels? This cannot be undone.").arg(root.pendingDeleteName)
        confirmText: qsTr("Delete")
        onConfirmed: {
            PlaylistModel.removePlaylist(root.pendingDeleteId)
            root.pendingDeleteId = -1
            root.playlistsChanged()
        }
    }

    Component.onCompleted: {
        PlaylistModel.refresh()
    }
}

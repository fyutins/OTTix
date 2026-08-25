import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Channel tile. The root fills the whole grid cell; the visible card is inset
// to leave regular gutters.
Item {
    id: delegateRoot

    property string channelName: ""
    property string channelUrl: ""
    property string channelLogo: ""
    property string channelGroup: ""
    property int channelDbId: -1
    property bool isFavorite: false
    property bool showFavoriteIcon: true

    // The favorite button absorbs hover events: without this union the card
    // would lose hover as soon as the star is pointed at, shrink, and the mouse
    // would fall back out of the button - hence an endless flicker.
    readonly property bool hovered: mouseArea.containsMouse || favoriteButton.hovered

    signal playRequested(string name, string url, string logo, string group)
    signal favoriteToggled(int channelDbId)

    implicitWidth: 158
    implicitHeight: 124

    Rectangle {
        id: card
        anchors.fill: parent
        anchors.margins: Theme.spacingXs
        radius: Theme.radiusMd
        color: delegateRoot.hovered ? Theme.surfaceHi : Theme.surfaceAlt
        border.width: 1
        border.color: delegateRoot.hovered ? Theme.accent : Theme.border
        scale: mouseArea.pressed ? 0.97 : (delegateRoot.hovered ? 1.03 : 1.0)

        Behavior on color { ColorAnimation { duration: Theme.durFast } }
        Behavior on border.color { ColorAnimation { duration: Theme.durFast } }
        Behavior on scale {
            NumberAnimation { duration: Theme.durFast; easing.type: Easing.OutCubic }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton

            onClicked: (mouse) => {
                if (mouse.button === Qt.RightButton)
                    contextMenu.popup(mouseArea, mouseX, mouseY)
                else
                    delegateRoot.playRequested(
                        delegateRoot.channelName, delegateRoot.channelUrl,
                        delegateRoot.channelLogo, delegateRoot.channelGroup)
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.spacingSm
            spacing: Theme.spacingXs

            // -- Logo (or fallback pictogram) + playback overlay --
            Rectangle {
                id: logoFrame

                readonly property string logoSource: delegateRoot.channelLogo || ""
                // Backdrop derived from the logo's dominant color (see
                // LogoPalette): a dark logo would be lost on the default dark
                // background, and vice versa. Invalid until the analysis lands.
                property color backdrop: "transparent"
                readonly property bool lightBackdrop: logoFrame.backdrop.a > 0
                                                      && logoFrame.backdrop.hslLightness > 0.5

                function refreshBackdrop() {
                    logoFrame.backdrop = LogoPalette.backdrop(logoFrame.logoSource)
                }

                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 44
                Layout.preferredHeight: 40
                radius: Theme.radiusSm
                color: logoFrame.backdrop.a > 0 ? logoFrame.backdrop : Theme.logoBackdrop

                onLogoSourceChanged: logoFrame.refreshBackdrop()
                Component.onCompleted: logoFrame.refreshBackdrop()

                Behavior on color { ColorAnimation { duration: Theme.durNormal } }

                Connections {
                    target: LogoPalette

                    function onBackdropResolved(source, color) {
                        if (source === logoFrame.logoSource)
                            logoFrame.backdrop = color
                    }
                }

                Image {
                    id: logo
                    anchors.fill: parent
                    anchors.margins: 2
                    fillMode: Image.PreserveAspectFit
                    source: delegateRoot.channelLogo || ""
                    asynchronous: true
                    cache: true
                    opacity: delegateRoot.hovered ? 0.25 : 1.0

                    Behavior on opacity { NumberAnimation { duration: Theme.durFast } }
                }

                MdiIcon {
                    anchors.centerIn: parent
                    visible: logo.status !== Image.Ready
                    glyph: Mdi.television
                    font.pixelSize: Theme.iconLg
                    color: Theme.textDim
                    opacity: delegateRoot.hovered ? 0.25 : 1.0
                }

                MdiIcon {
                    anchors.centerIn: parent
                    visible: delegateRoot.hovered
                    glyph: Mdi.play
                    font.pixelSize: Theme.iconLg
                    // On a light logo-derived backdrop the nominal accent lacks
                    // contrast, so use its pressed variant.
                    color: logoFrame.lightBackdrop ? Theme.accentPressed : Theme.accent
                }
            }

            Item { Layout.fillHeight: true }

            Text {
                Layout.fillWidth: true
                text: delegateRoot.channelName
                color: Theme.text
                font.pixelSize: Theme.fontSm
                maximumLineCount: 2
                wrapMode: Text.WordWrap
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                Layout.fillWidth: true
                text: delegateRoot.channelGroup || ""
                color: Theme.textDim
                font.pixelSize: Theme.fontXs
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                visible: text !== ""
            }
        }

        // -- Favorite: always visible when set, on hover otherwise --
        IconButton {
            id: favoriteButton

            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: Theme.spacingXs
            visible: delegateRoot.showFavoriteIcon
                     && (delegateRoot.isFavorite || delegateRoot.hovered)
            implicitWidth: Theme.controlSm
            implicitHeight: Theme.controlSm
            round: true
            glyph: delegateRoot.isFavorite ? Mdi.star : Mdi.starOutline
            glyphSize: Theme.iconSm
            glyphColor: delegateRoot.isFavorite ? Theme.warning : Theme.textMuted
            tooltip: delegateRoot.isFavorite ? qsTr("Remove from favorites")
                                             : qsTr("Add to favorites")
            onClicked: delegateRoot.favoriteToggled(delegateRoot.channelDbId)
        }
    }

    AppMenu {
        id: contextMenu

        AppMenuItem {
            text: qsTr("Play")
            glyph: Mdi.play
            onTriggered: delegateRoot.playRequested(
                delegateRoot.channelName, delegateRoot.channelUrl,
                delegateRoot.channelLogo, delegateRoot.channelGroup)
        }

        AppMenuItem {
            text: delegateRoot.isFavorite ? qsTr("Remove from Favorites")
                                          : qsTr("Add to Favorites")
            glyph: delegateRoot.isFavorite ? Mdi.star : Mdi.starOutline
            visible: delegateRoot.showFavoriteIcon
            height: visible ? implicitHeight : 0
            onTriggered: delegateRoot.favoriteToggled(delegateRoot.channelDbId)
        }

        MenuSeparator {}

        AppMenuItem {
            text: qsTr("Copy URL")
            glyph: Mdi.copy
            onTriggered: ClipboardHelper.copyText(delegateRoot.channelUrl)
        }

        AppMenuItem {
            text: qsTr("Info")
            glyph: Mdi.information
            onTriggered: infoDialog.open()
        }
    }

    Dialog {
        id: infoDialog
        modal: true
        anchors.centerIn: Overlay.overlay
        width: 460
        padding: Theme.spacingLg
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: Theme.surface
            radius: Theme.radiusMd
            border.width: 1
            border.color: Theme.border
        }

        header: Item {
            implicitHeight: Theme.toolbarHeight

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.spacingLg
                anchors.rightMargin: Theme.spacingSm
                spacing: Theme.spacingSm

                MdiIcon {
                    glyph: Mdi.information
                    font.pixelSize: Theme.iconMd
                    color: Theme.accent
                }

                Text {
                    Layout.fillWidth: true
                    text: delegateRoot.channelName
                    color: Theme.text
                    font.pixelSize: Theme.fontLg
                    font.bold: true
                    elide: Text.ElideRight
                }

                IconButton {
                    glyph: Mdi.close
                    glyphColor: Theme.textMuted
                    onClicked: infoDialog.close()
                }
            }
        }

        contentItem: ColumnLayout {
            spacing: Theme.spacingSm

            Repeater {
                model: [
                    { label: qsTr("Name"), value: delegateRoot.channelName },
                    { label: qsTr("Category"), value: delegateRoot.channelGroup || qsTr("None") },
                    { label: qsTr("URL"), value: delegateRoot.channelUrl }
                ]

                delegate: RowLayout {
                    id: infoRow

                    required property var modelData

                    Layout.fillWidth: true
                    spacing: Theme.spacingSm

                    Text {
                        Layout.preferredWidth: 70
                        Layout.alignment: Qt.AlignTop
                        text: infoRow.modelData.label
                        color: Theme.textDim
                        font.pixelSize: Theme.fontMd
                    }

                    Text {
                        Layout.fillWidth: true
                        text: infoRow.modelData.value
                        color: Theme.text
                        font.pixelSize: Theme.fontMd
                        wrapMode: Text.WrapAnywhere
                    }
                }
            }
        }

        footer: Item {
            implicitHeight: Theme.controlLg + Theme.spacingMd

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.spacingLg
                anchors.rightMargin: Theme.spacingLg
                anchors.bottomMargin: Theme.spacingMd
                spacing: Theme.spacingSm

                Item { Layout.fillWidth: true }

                AppButton {
                    text: qsTr("Copy URL")
                    glyph: Mdi.copy
                    onClicked: ClipboardHelper.copyText(delegateRoot.channelUrl)
                }

                AppButton {
                    text: qsTr("Close")
                    variant: AppButton.Primary
                    onClicked: infoDialog.close()
                }
            }
        }
    }
}

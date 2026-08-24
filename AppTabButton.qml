import QtQuick
import QtQuick.Controls

// Onglet : icone + libelle + compteur optionnel, souligne anime quand actif.
TabButton {
    id: control

    property string glyph: ""
    property string badgeText: ""

    readonly property color fgColor: control.checked ? Theme.accent
                                   : control.hovered ? Theme.text : Theme.textMuted

    // Largeur explicite : TabBar ne redimensionne que les onglets qui n'en
    // fixent pas, ce qui garde ici des onglets compacts.
    width: implicitWidth
    height: parent ? parent.height : Theme.tabBarHeight
    leftPadding: Theme.spacingMd
    rightPadding: Theme.spacingMd
    hoverEnabled: true

    contentItem: Row {
        spacing: Theme.spacingSm

        MdiIcon {
            anchors.verticalCenter: parent.verticalCenter
            visible: control.glyph !== ""
            glyph: control.glyph
            font.pixelSize: Theme.iconSm
            color: control.fgColor

            Behavior on color { ColorAnimation { duration: Theme.durFast } }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: control.text
            font.pixelSize: Theme.fontMd
            font.bold: control.checked
            color: control.fgColor

            Behavior on color { ColorAnimation { duration: Theme.durFast } }
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            visible: control.badgeText !== ""
            implicitWidth: badgeLabel.implicitWidth + Theme.spacingSm
            implicitHeight: 16
            radius: Theme.radiusPill
            color: control.checked ? Theme.accentSoft : Theme.surfaceAlt

            Text {
                id: badgeLabel
                anchors.centerIn: parent
                text: control.badgeText
                font.pixelSize: Theme.fontXs
                font.bold: true
                color: control.checked ? Theme.accent : Theme.textDim
            }
        }
    }

    background: Item {
        Rectangle {
            anchors.fill: parent
            anchors.topMargin: Theme.spacingXs
            anchors.bottomMargin: 3
            radius: Theme.radiusSm
            color: control.hovered && !control.checked ? Theme.hover : "transparent"

            Behavior on color { ColorAnimation { duration: Theme.durFast } }
        }

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width: control.checked ? parent.width - Theme.spacingMd : 0
            height: 2
            radius: 1
            color: Theme.accent

            Behavior on width {
                NumberAnimation { duration: Theme.durNormal; easing.type: Easing.OutCubic }
            }
        }
    }

    HoverHandler { cursorShape: Qt.PointingHandCursor }
}

import QtQuick
import QtQuick.Controls

// Bouton icone unique. Trois apparences :
//   - par defaut       : fond transparent, survol clair (barres et pages)
//   - `tinted`         : pastille translucide claire (par-dessus la video)
//   - `tinted` + `dark`: pastille sombre (controles centraux du player)
AbstractButton {
    id: control

    property string glyph: ""
    property int glyphSize: Theme.iconMd
    property color glyphColor: Theme.text
    property color checkedColor: Theme.accent
    property bool round: false
    property bool tinted: false
    property bool dark: false
    property bool danger: false
    property string tooltip: ""

    readonly property color idleBg: control.tinted
        ? (control.dark ? Theme.glassDark : Theme.glass)
        : "transparent"
    readonly property color hoverBg: control.danger
        ? Theme.dangerSoft
        : (control.tinted ? (control.dark ? Theme.glassDarkHover : Theme.glassHover)
                          : Theme.hover)
    readonly property color pressBg: control.tinted ? Theme.glassPressed : Theme.pressed

    implicitWidth: Theme.controlMd
    implicitHeight: Theme.controlMd
    padding: 0
    hoverEnabled: true
    opacity: enabled ? 1.0 : 0.35
    scale: control.down ? 0.9 : 1.0

    Behavior on scale {
        NumberAnimation { duration: Theme.durFast; easing.type: Easing.OutCubic }
    }

    background: Rectangle {
        radius: control.round ? height / 2 : Theme.radiusSm
        color: !control.enabled ? control.idleBg
             : control.down ? control.pressBg
             : control.hovered ? control.hoverBg
             : (control.checked ? Theme.accentSoft : control.idleBg)
        border.width: control.checked || (control.tinted && control.dark) ? 1 : 0
        border.color: control.checked ? control.checkedColor : Theme.glass

        Behavior on color { ColorAnimation { duration: Theme.durFast } }
    }

    contentItem: MdiIcon {
        glyph: control.glyph
        font.pixelSize: control.glyphSize
        color: control.checked ? control.checkedColor
             : control.danger ? Theme.danger
             : control.glyphColor

        Behavior on color { ColorAnimation { duration: Theme.durFast } }
    }

    HoverHandler {
        enabled: control.enabled
        cursorShape: Qt.PointingHandCursor
    }

    Tip {
        visible: control.hovered && control.tooltip !== ""
        text: control.tooltip
    }
}

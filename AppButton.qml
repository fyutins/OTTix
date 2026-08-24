import QtQuick
import QtQuick.Controls

// Bouton texte (avec icone optionnelle) du design system.
//   AppButton { text: qsTr("Add"); variant: AppButton.Primary; glyph: Mdi.plus }
Button {
    id: control

    enum Variant {
        Secondary,
        Primary,
        Ghost,
        Danger
    }

    property int variant: AppButton.Secondary
    property string glyph: ""

    readonly property color bgColor: {
        if (!control.enabled)
            return control.variant === AppButton.Primary ? Theme.surfaceAlt : "transparent"
        switch (control.variant) {
        case AppButton.Primary:
            return control.down ? Theme.accentPressed
                 : control.hovered ? Theme.accentHover : Theme.accent
        case AppButton.Danger:
            return control.down || control.hovered ? Theme.dangerSoft : "transparent"
        case AppButton.Ghost:
            return control.down ? Theme.pressed
                 : control.hovered ? Theme.hover : "transparent"
        default:
            return control.down ? Theme.surfaceHi
                 : control.hovered ? Theme.surfaceHi : Theme.surfaceAlt
        }
    }

    readonly property color fgColor: {
        if (!control.enabled)
            return Theme.textDim
        switch (control.variant) {
        case AppButton.Primary:
            return Theme.textOnAccent
        case AppButton.Danger:
            return Theme.danger
        case AppButton.Ghost:
            return control.hovered ? Theme.text : Theme.textMuted
        default:
            return Theme.text
        }
    }

    readonly property color lineColor: {
        if (control.variant === AppButton.Danger)
            return control.enabled ? Theme.danger : Theme.border
        if (control.variant === AppButton.Secondary)
            return control.hovered ? Theme.borderStrong : Theme.border
        return "transparent"
    }

    implicitHeight: Theme.controlMd
    leftPadding: Theme.spacingMd
    rightPadding: Theme.spacingMd
    hoverEnabled: true
    opacity: enabled ? 1.0 : 0.55
    font.pixelSize: Theme.fontMd

    background: Rectangle {
        radius: Theme.radiusSm
        color: control.bgColor
        border.width: control.lineColor === "transparent" ? 0 : 1
        border.color: control.lineColor

        Behavior on color { ColorAnimation { duration: Theme.durFast } }
    }

    contentItem: Row {
        spacing: control.glyph !== "" ? Theme.spacingSm : 0

        MdiIcon {
            anchors.verticalCenter: parent.verticalCenter
            visible: control.glyph !== ""
            glyph: control.glyph
            font.pixelSize: Theme.iconSm
            color: control.fgColor
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: control.text
            font: control.font
            color: control.fgColor

            Behavior on color { ColorAnimation { duration: Theme.durFast } }
        }
    }

    HoverHandler {
        enabled: control.enabled
        cursorShape: Qt.PointingHandCursor
    }
}

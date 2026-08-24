import QtQuick
import QtQuick.Layouts

// Etat vide d'une liste : icone estompee + message (+ detail optionnel).
ColumnLayout {
    id: control

    property string glyph: ""
    property string title: ""
    property string subtitle: ""

    spacing: Theme.spacingSm

    MdiIcon {
        Layout.alignment: Qt.AlignHCenter
        glyph: control.glyph
        font.pixelSize: 48
        color: Theme.surfaceHi
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: control.title
        color: Theme.textMuted
        font.pixelSize: Theme.fontLg
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        visible: control.subtitle !== ""
        text: control.subtitle
        color: Theme.textDim
        font.pixelSize: Theme.fontMd
    }
}

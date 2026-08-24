import QtQuick

// Icone Material Design Icons. `glyph` prend une valeur du singleton Mdi
// (ex. MdiIcon { glyph: Mdi.refresh }).
Text {
    id: control

    property string glyph: ""

    text: control.glyph
    font.family: Mdi.family
    font.pixelSize: Theme.iconMd
    color: Theme.text
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
}

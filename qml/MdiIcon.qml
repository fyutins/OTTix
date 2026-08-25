import QtQuick

// Material Design Icons icon. `glyph` takes a value from the Mdi singleton
// (e.g. MdiIcon { glyph: Mdi.refresh }).
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

pragma ComponentBehavior: Bound
import QtQuick

// Icone de disposition du lecteur : un carre par ecran, poses comme les slots
// le sont reellement (deux ecrans cote a cote, le troisieme sur toute la
// largeur). Dessinee plutot que prise dans la fonte MDI : les icones de
// disposition de MDI melangent des motifs heterogenes (square, split, quilt,
// grid) et les quatre ne se lisent pas comme une famille.
//
// Purement geometrique : la couleur et la taille viennent de l'appelant.
//   ScreenLayoutIcon { screens: 3; size: Theme.iconSm; color: Theme.text }
Item {
    id: root

    property int screens: 1
    property color color: "white"
    property real size: 18

    implicitWidth: root.size
    implicitHeight: root.size

    readonly property real stroke: Math.max(1, Math.round(root.size / 14))
    readonly property real gap: Math.max(2, Math.round(root.size / 7))

    // Une cellule par ecran : x, y, largeur, hauteur en fraction de l'icone.
    readonly property var cells: {
        switch (root.screens) {
        case 2: return [[0, 0, 0.5, 1], [0.5, 0, 0.5, 1]]
        case 3: return [[0, 0, 0.5, 0.5], [0.5, 0, 0.5, 0.5], [0, 0.5, 1, 0.5]]
        case 4: return [[0, 0, 0.5, 0.5], [0.5, 0, 0.5, 0.5],
                        [0, 0.5, 0.5, 0.5], [0.5, 0.5, 0.5, 0.5]]
        default: return [[0, 0, 1, 1]]
        }
    }

    // Demi-gouttiere retiree de chaque cote interieur : les carres touchent les
    // bords de l'icone et sont separes de `gap` entre eux. Arrondi au pixel
    // pour que les traits restent nets aux petites tailles.
    function startPx(fraction) {
        return Math.round(fraction * root.size + (fraction > 0 ? root.gap / 2 : 0))
    }

    function endPx(fraction) {
        return Math.round(fraction * root.size - (fraction < 1 ? root.gap / 2 : 0))
    }

    // Les carres sont dessines dans un carre de `size` centre : un Control
    // etire son contentItem sur toute la zone disponible, la geometrie ne peut
    // donc pas etre calee sur la racine.
    Item {
        anchors.centerIn: parent
        width: root.size
        height: root.size

        Repeater {
            model: root.cells

            delegate: Rectangle {
                id: cell

                required property var modelData

                x: root.startPx(cell.modelData[0])
                y: root.startPx(cell.modelData[1])
                width: root.endPx(cell.modelData[0] + cell.modelData[2]) - cell.x
                height: root.endPx(cell.modelData[1] + cell.modelData[3]) - cell.y
                radius: root.stroke
                color: "transparent"
                border.width: root.stroke
                border.color: root.color
                antialiasing: true
            }
        }
    }
}

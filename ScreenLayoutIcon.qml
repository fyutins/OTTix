pragma ComponentBehavior: Bound
import QtQuick

// Player layout icon: one square per screen, laid out the way the slots really
// are (two screens side by side, the third across the full width). Drawn rather
// than taken from the MDI font: the MDI layout icons mix heterogeneous motifs
// (square, split, quilt, grid) and the four do not read as one family.
//
// Purely geometric: color and size come from the caller.
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

    // One cell per screen: x, y, width, height as a fraction of the icon.
    readonly property var cells: {
        switch (root.screens) {
        case 2: return [[0, 0, 0.5, 1], [0.5, 0, 0.5, 1]]
        case 3: return [[0, 0, 0.5, 0.5], [0.5, 0, 0.5, 0.5], [0, 0.5, 1, 0.5]]
        case 4: return [[0, 0, 0.5, 0.5], [0.5, 0, 0.5, 0.5],
                        [0, 0.5, 0.5, 0.5], [0.5, 0.5, 0.5, 0.5]]
        default: return [[0, 0, 1, 1]]
        }
    }

    // Half a gutter removed from each inner side: the squares touch the icon
    // edges and are `gap` apart from each other. Rounded to the pixel so the
    // strokes stay crisp at small sizes.
    function startPx(fraction) {
        return Math.round(fraction * root.size + (fraction > 0 ? root.gap / 2 : 0))
    }

    function endPx(fraction) {
        return Math.round(fraction * root.size - (fraction < 1 ? root.gap / 2 : 0))
    }

    // The squares are drawn inside a centered `size` square: a Control stretches
    // its contentItem over the whole available area, so the geometry cannot be
    // anchored to the root.
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

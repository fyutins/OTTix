import QtQuick
import QtQuick.Controls

// Barre d'onglets du design system : fond de surface, filet de separation bas,
// onglets compacts alignes a gauche (cf. AppTabButton, qui fixe sa propre
// largeur pour empecher TabBar de repartir l'espace a parts egales).
TabBar {
    id: control

    implicitHeight: Theme.tabBarHeight
    leftPadding: Theme.spacingSm
    rightPadding: Theme.spacingSm
    spacing: Theme.spacingXs

    background: Rectangle {
        color: Theme.surface

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: Theme.border
        }
    }
}

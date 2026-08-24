pragma Singleton
import QtQuick

// Design system de l'application : toutes les couleurs, tailles, rayons et
// durees d'animation sont declarees ici. Aucun literal de couleur ne doit
// subsister dans les autres fichiers QML.
QtObject {
    id: theme

    // ── Surfaces ──────────────────────────────────────────────────────────
    // Echelle d'elevation : plus l'element est "haut", plus la surface est claire.
    readonly property color bg: "#0f1320"          // fond de l'application
    readonly property color surface: "#161c2c"     // barres, cartes
    readonly property color surfaceAlt: "#1e2740"  // champs, tuiles
    readonly property color surfaceHi: "#28324f"   // survol, selection
    readonly property color border: "#2b3757"
    readonly property color borderStrong: "#3d4c76"

    // ── Accent ────────────────────────────────────────────────────────────
    readonly property color accent: "#4c8dff"
    readonly property color accentHover: "#6ea6ff"
    readonly property color accentPressed: "#3a76dd"
    readonly property color accentSoft: Qt.rgba(0.30, 0.55, 1.0, 0.18)
    readonly property color textOnAccent: "#ffffff"

    // ── Texte ─────────────────────────────────────────────────────────────
    readonly property color text: "#e6e9f2"
    readonly property color textMuted: "#98a2bd"
    readonly property color textDim: "#69748f"

    // ── Statuts ───────────────────────────────────────────────────────────
    readonly property color danger: "#ef5f5f"
    readonly property color dangerSoft: Qt.rgba(0.94, 0.37, 0.37, 0.18)
    readonly property color success: "#4ec98a"
    readonly property color warning: "#f0b45e"
    readonly property color live: "#e5484d"

    // ── Survol / appui sur surface sombre ────────────────────────────────
    readonly property color hover: Qt.rgba(1, 1, 1, 0.07)
    readonly property color pressed: Qt.rgba(1, 1, 1, 0.13)

    // ── Calques poses sur la video ───────────────────────────────────────
    readonly property color scrim: Qt.rgba(0, 0, 0, 0.55)
    readonly property color scrimStrong: Qt.rgba(0, 0, 0, 0.8)
    readonly property color glass: Qt.rgba(1, 1, 1, 0.12)
    readonly property color glassHover: Qt.rgba(1, 1, 1, 0.22)
    readonly property color glassPressed: Qt.rgba(1, 1, 1, 0.3)
    readonly property color glassDark: Qt.rgba(0, 0, 0, 0.55)
    readonly property color glassDarkHover: Qt.rgba(0, 0, 0, 0.75)

    // ── Rayons ────────────────────────────────────────────────────────────
    readonly property int radiusSm: 6
    readonly property int radiusMd: 10
    readonly property int radiusLg: 14
    readonly property int radiusPill: 999

    // ── Espacements (grille de 4) ────────────────────────────────────────
    readonly property int spacingXs: 4
    readonly property int spacingSm: 8
    readonly property int spacingMd: 12
    readonly property int spacingLg: 16
    readonly property int spacingXl: 24

    // ── Typographie ──────────────────────────────────────────────────────
    readonly property int fontXs: 10
    readonly property int fontSm: 11
    readonly property int fontMd: 13
    readonly property int fontLg: 15
    readonly property int fontXl: 18

    // ── Tailles de controle ──────────────────────────────────────────────
    readonly property int controlXs: 24
    readonly property int controlSm: 28
    readonly property int controlMd: 34
    readonly property int controlLg: 40
    readonly property int iconXs: 12
    readonly property int iconSm: 15
    readonly property int iconMd: 18
    readonly property int iconLg: 22
    readonly property int iconXl: 28

    // ── Hauteurs de reperes ──────────────────────────────────────────────
    readonly property int toolbarHeight: 48
    readonly property int tabBarHeight: 42

    // ── Animations ───────────────────────────────────────────────────────
    readonly property int durFast: 120
    readonly property int durNormal: 200
    readonly property int durSlow: 300
}

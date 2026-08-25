pragma Singleton
import QtQuick
import QtCore

// The application design system: every color, size, radius and animation
// duration is declared here. No color literal may remain in the other QML files.
//
// Two palettes (light / dark) expose the same tokens; QML files always read
// `Theme.<token>`, never the palette directly. The mode is persisted and
// defaults to "Auto": light from `dayStartHour` to `nightStartHour`, dark the
// rest of the time (local time).
QtObject {
    id: theme

    // -- Appearance mode --
    readonly property int modeAuto: 0
    readonly property int modeLight: 1
    readonly property int modeDark: 2

    property int mode: theme.modeAuto

    readonly property int dayStartHour: 7
    readonly property int nightStartHour: 19

    // Recomputed every minute so the switch happens without a restart.
    property bool autoDark: true

    readonly property bool dark: theme.mode === theme.modeDark
                                 || (theme.mode === theme.modeAuto && theme.autoDark)

    function updateAutoDark() {
        var h = new Date().getHours()
        theme.autoDark = h < theme.dayStartHour || h >= theme.nightStartHour
    }

    property Timer autoTimer: Timer {
        interval: 60000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: theme.updateAutoDark()
    }

    property Settings settings: Settings {
        category: "Appearance"
        property alias themeMode: theme.mode
    }

    // -- Palettes --
    component Palette: QtObject {
        // Surfaces, from the lowest to the highest elevation
        property color bg
        property color surface
        property color surfaceAlt
        property color surfaceHi
        property color border
        property color borderStrong

        // Accent
        property color accent
        property color accentHover
        property color accentPressed
        property color accentSoft
        property color textOnAccent

        // Text
        property color text
        property color textMuted
        property color textDim

        // Status
        property color danger
        property color dangerSoft
        property color success
        property color warning
        property color live

        // Hover / press on a surface
        property color hover
        property color pressed
    }

    readonly property Palette darkPalette: Palette {
        bg: "#0f1320"
        surface: "#161c2c"
        surfaceAlt: "#1e2740"
        surfaceHi: "#28324f"
        border: "#2b3757"
        borderStrong: "#3d4c76"

        accent: "#4c8dff"
        accentHover: "#6ea6ff"
        accentPressed: "#3a76dd"
        accentSoft: Qt.rgba(0.30, 0.55, 1.0, 0.18)
        textOnAccent: "#ffffff"

        text: "#e6e9f2"
        textMuted: "#98a2bd"
        textDim: "#69748f"

        danger: "#ef5f5f"
        dangerSoft: Qt.rgba(0.94, 0.37, 0.37, 0.18)
        success: "#4ec98a"
        warning: "#f0b45e"
        live: "#e5484d"

        hover: Qt.rgba(1, 1, 1, 0.07)
        pressed: Qt.rgba(1, 1, 1, 0.13)
    }

    readonly property Palette lightPalette: Palette {
        bg: "#f2f5fa"
        surface: "#ffffff"
        surfaceAlt: "#e9edf5"
        surfaceHi: "#dbe2ee"
        border: "#d3dae6"
        borderStrong: "#b0bccf"

        accent: "#2f6fed"
        accentHover: "#4a83f0"
        accentPressed: "#2559c9"
        accentSoft: Qt.rgba(0.18, 0.44, 0.93, 0.14)
        textOnAccent: "#ffffff"

        text: "#161a23"
        textMuted: "#59637a"
        textDim: "#8a94a8"

        danger: "#d0433f"
        dangerSoft: Qt.rgba(0.82, 0.26, 0.25, 0.14)
        success: "#1f8f5f"
        warning: "#c67f18"
        live: "#d0342c"

        hover: Qt.rgba(0, 0, 0, 0.05)
        pressed: Qt.rgba(0, 0, 0, 0.10)
    }

    readonly property Palette palette: theme.dark ? theme.darkPalette : theme.lightPalette

    // -- Color tokens (always read through Theme.<token>) --
    readonly property color bg: theme.palette.bg
    readonly property color surface: theme.palette.surface
    readonly property color surfaceAlt: theme.palette.surfaceAlt
    readonly property color surfaceHi: theme.palette.surfaceHi
    readonly property color border: theme.palette.border
    readonly property color borderStrong: theme.palette.borderStrong

    readonly property color accent: theme.palette.accent
    readonly property color accentHover: theme.palette.accentHover
    readonly property color accentPressed: theme.palette.accentPressed
    readonly property color accentSoft: theme.palette.accentSoft
    readonly property color textOnAccent: theme.palette.textOnAccent

    readonly property color text: theme.palette.text
    readonly property color textMuted: theme.palette.textMuted
    readonly property color textDim: theme.palette.textDim

    readonly property color danger: theme.palette.danger
    readonly property color dangerSoft: theme.palette.dangerSoft
    readonly property color success: theme.palette.success
    readonly property color warning: theme.palette.warning
    readonly property color live: theme.palette.live

    readonly property color hover: theme.palette.hover
    readonly property color pressed: theme.palette.pressed

    // -- Mode-independent tokens --
    // The playback area stays dark in both themes, so the layers laid over the
    // video and the text sitting on them do not change.
    readonly property color videoBg: "#000000"
    readonly property color scrim: Qt.rgba(0, 0, 0, 0.55)
    readonly property color scrimStrong: Qt.rgba(0, 0, 0, 0.8)
    readonly property color glass: Qt.rgba(1, 1, 1, 0.12)
    readonly property color glassHover: Qt.rgba(1, 1, 1, 0.22)
    readonly property color glassPressed: Qt.rgba(1, 1, 1, 0.3)
    readonly property color glassDark: Qt.rgba(0, 0, 0, 0.55)
    readonly property color glassDarkHover: Qt.rgba(0, 0, 0, 0.75)
    readonly property color scrimText: "#f2f4f8"
    readonly property color scrimTextMuted: "#c3cad8"
    readonly property color scrimTextDim: "#8b93a5"

    // Default channel logo backdrop: most logos are drawn for a dark background
    // and would vanish on a light tile. Logos whose dominant color comes close
    // to it get a backdrop derived from that color (see LogoPalette), this token
    // staying the fallback.
    readonly property color logoBackdrop: "#1b2133"

    // -- Radii --
    readonly property int radiusSm: 6
    readonly property int radiusMd: 10
    readonly property int radiusLg: 14
    readonly property int radiusPill: 999

    // -- Spacing (4 px grid) --
    readonly property int spacingXs: 4
    readonly property int spacingSm: 8
    readonly property int spacingMd: 12
    readonly property int spacingLg: 16
    readonly property int spacingXl: 24

    // -- Typography --
    readonly property int fontXs: 10
    readonly property int fontSm: 11
    readonly property int fontMd: 13
    readonly property int fontLg: 15
    readonly property int fontXl: 18

    // -- Control sizes --
    readonly property int controlXs: 24
    readonly property int controlSm: 28
    readonly property int controlMd: 34
    readonly property int controlLg: 40
    readonly property int iconXs: 12
    readonly property int iconSm: 15
    readonly property int iconMd: 18
    readonly property int iconLg: 22
    readonly property int iconXl: 28

    // -- Landmark heights --
    readonly property int toolbarHeight: 48
    readonly property int tabBarHeight: 42

    // -- Animations --
    readonly property int durFast: 120
    readonly property int durNormal: 200
    readonly property int durSlow: 300
}

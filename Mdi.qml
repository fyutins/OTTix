pragma Singleton
import QtQuick

// Jeu d'icones unique de l'application : Material Design Icons (v7.4.47).
// La fonte est embarquee dans le module QML (fonts/, cf. CMakeLists.txt) et
// chargee une seule fois ici.
//
// Les points de code MDI sont hors du plan multilingue de base (> 0xFFFF) :
// ils ne peuvent pas s'ecrire en litteral "\uXXXX", d'ou String.fromCodePoint.
// Pour ajouter une icone : chercher son nom sur pictogrammers.com/library/mdi,
// relever le point de code et l'ajouter ci-dessous par ordre thematique.
QtObject {
    id: mdi

    property FontLoader loader: FontLoader {
        source: Qt.resolvedUrl("fonts/materialdesignicons-webfont.ttf")
    }

    readonly property string family: mdi.loader.status === FontLoader.Ready
                                     ? mdi.loader.name
                                     : "Material Design Icons"

    // ── Navigation ────────────────────────────────────────────────────────
    readonly property string arrowLeft: String.fromCodePoint(0xF004D)
    readonly property string chevronLeft: String.fromCodePoint(0xF0141)
    readonly property string chevronRight: String.fromCodePoint(0xF0142)
    readonly property string chevronUp: String.fromCodePoint(0xF0143)
    readonly property string chevronDown: String.fromCodePoint(0xF0140)
    readonly property string close: String.fromCodePoint(0xF0156)
    readonly property string closeCircle: String.fromCodePoint(0xF0159)
    readonly property string menu: String.fromCodePoint(0xF035C)
    readonly property string dotsVertical: String.fromCodePoint(0xF01D9)
    readonly property string openInNew: String.fromCodePoint(0xF03CC)

    // ── Onglets / sections ────────────────────────────────────────────────
    readonly property string star: String.fromCodePoint(0xF04CE)
    readonly property string starOutline: String.fromCodePoint(0xF04D2)
    readonly property string television: String.fromCodePoint(0xF07F4)
    readonly property string remoteTv: String.fromCodePoint(0xF0EC5)
    readonly property string televisionGuide: String.fromCodePoint(0xF0503)
    readonly property string televisionOff: String.fromCodePoint(0xF083B)
    readonly property string folderMultiple: String.fromCodePoint(0xF0255)
    readonly property string history: String.fromCodePoint(0xF02DA)
    readonly property string playlistPlay: String.fromCodePoint(0xF0411)
    readonly property string cogOutline: String.fromCodePoint(0xF08BB)

    // ── Apparence ─────────────────────────────────────────────────────────
    readonly property string themeAuto: String.fromCodePoint(0xF050E)   // theme-light-dark
    readonly property string themeLight: String.fromCodePoint(0xF05A8)  // white-balance-sunny
    readonly property string themeDark: String.fromCodePoint(0xF0594)   // weather-night

    // ── Lecture ───────────────────────────────────────────────────────────
    readonly property string play: String.fromCodePoint(0xF040A)
    readonly property string pause: String.fromCodePoint(0xF03E4)
    readonly property string skipPrevious: String.fromCodePoint(0xF04AE)
    readonly property string skipNext: String.fromCodePoint(0xF04AD)
    readonly property string rewind15: String.fromCodePoint(0xF1946)
    readonly property string fastForward15: String.fromCodePoint(0xF193A)
    readonly property string volumeHigh: String.fromCodePoint(0xF057E)
    readonly property string volumeMedium: String.fromCodePoint(0xF0580)
    readonly property string volumeOff: String.fromCodePoint(0xF0581)
    readonly property string accessPoint: String.fromCodePoint(0xF0003)
    readonly property string highDefinition: String.fromCodePoint(0xF07CF)
    readonly property string fullscreen: String.fromCodePoint(0xF0293)
    readonly property string fullscreenExit: String.fromCodePoint(0xF0294)

    // ── Actions ───────────────────────────────────────────────────────────
    readonly property string refresh: String.fromCodePoint(0xF0450)
    readonly property string sync: String.fromCodePoint(0xF04E6)
    readonly property string restart: String.fromCodePoint(0xF0709)
    readonly property string plus: String.fromCodePoint(0xF0415)
    readonly property string plusCircle: String.fromCodePoint(0xF0419)
    readonly property string pencil: String.fromCodePoint(0xF0CB6)
    readonly property string trash: String.fromCodePoint(0xF0A7A)
    readonly property string download: String.fromCodePoint(0xF0B7D)
    readonly property string copy: String.fromCodePoint(0xF018F)
    readonly property string check: String.fromCodePoint(0xF012C)
    readonly property string checkCircle: String.fromCodePoint(0xF05E1)
    readonly property string broom: String.fromCodePoint(0xF00E2)

    // ── Recherche / filtres ───────────────────────────────────────────────
    readonly property string magnify: String.fromCodePoint(0xF0349)
    readonly property string magnifyClose: String.fromCodePoint(0xF0980)
    readonly property string textSearch: String.fromCodePoint(0xF13B8)
    readonly property string filter: String.fromCodePoint(0xF0236)
    readonly property string label: String.fromCodePoint(0xF0316)

    // ── Etats / informations ──────────────────────────────────────────────
    readonly property string clock: String.fromCodePoint(0xF0150)
    readonly property string information: String.fromCodePoint(0xF02FD)
    readonly property string alert: String.fromCodePoint(0xF05D6)
    readonly property string help: String.fromCodePoint(0xF0625)
    readonly property string database: String.fromCodePoint(0xF1632)
    readonly property string tune: String.fromCodePoint(0xF1542)
    readonly property string link: String.fromCodePoint(0xF0339)
    readonly property string account: String.fromCodePoint(0xF0013)
    readonly property string key: String.fromCodePoint(0xF0DD6)
    readonly property string earth: String.fromCodePoint(0xF01E7)
    readonly property string server: String.fromCodePoint(0xF048D)
    readonly property string imageOff: String.fromCodePoint(0xF082B)
}

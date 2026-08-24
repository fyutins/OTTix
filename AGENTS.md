# IPTV Player

## Description
Application Qt 6 / QML avec backend C++ pour lire des flux IPTV (M3U / XTREAM Codes) via libmpv.

## Structure

```
IptvPlayer/
├── Main.qml              # Fenêtre principale — navigation + player overlay
├── PlayerPage.qml        # Vue plein écran du player (multiplex, contrôles, close+nav)
├── PlayerSlot.qml        # Zone player individuelle (multiplex)
├── ChannelListPage.qml   # Toutes les chaînes avec recherche
├── GroupsPage.qml        # Navigation par groupe avec drill-down
├── FavoritesPage.qml     # Chaînes favorites
├── ChannelDelegate.qml   # Tuile de chaîne dans la grille
├── ChannelSearchPopup.qml# Popup de navigation dans les chaînes depuis le player
├── AdminPage.qml         # Page admin (Playlists + Settings)
├── PlaylistDialog.qml    # Dialogue d'ajout / édition de playlist
├── HistoryPage.qml       # Historique de lecture
│
│   # ── Design system (composants partages) ──
├── Theme.qml             # Singleton : couleurs, espacements, typo, durees
├── Mdi.qml               # Singleton : fonte + points de code Material Design Icons
├── MdiIcon.qml           # Icone MDI (Text specialise)
├── IconButton.qml        # Bouton icone (plat / pastille claire / pastille sombre)
├── AppButton.qml         # Bouton texte : Primary / Secondary / Ghost / Danger
├── AppTabBar.qml         # Barre d'onglets (filet bas)
├── AppTabButton.qml      # Onglet : icone + libelle + compteur + souligne anime
├── AppComboBox.qml       # Liste deroulante
├── AppMenu.qml           # Menu contextuel
├── AppMenuItem.qml       # Entree de menu (coche, icone, sous-menu)
├── AppScrollBar.qml      # Barre de defilement discrete
├── SearchField.qml       # Champ de recherche (loupe + effacement)
├── SettingsCard.qml      # Carte de reglages (en-tete icone + titre)
├── ConfirmDialog.qml     # Confirmation d'action destructive
├── EmptyState.qml        # Etat vide (icone + message)
├── Tip.qml               # Infobulle
│
├── fonts/                # materialdesignicons-webfont.ttf (+ NOTICE.md)
├── PLAN.md               # Plan de refonte ergonomique
├── CMakeLists.txt        # Build CMake + Qt6
├── AGENTS.md             # Ce fichier
└── src/
    ├── main.cpp          # Point d'entrée C++, registrations QML
    ├── database/         # SQLite (DatabaseManager)
    ├── loader/           # PlaylistLoader (M3U + Xtream)
    ├── models/           # ChannelListModel, PlaylistModel
    ├── parser/           # M3UParser
    ├── player/           # MpvObject, MpvRenderer (libmpv OpenGL)
    ├── utils/            # ClipboardHelper, SleepInhibitor, ChannelGrouper,
    │                     # Logging (catégories), LogUtils (masquage d'URL)
    └── xtream/           # XtreamApi
```

## Navigation

```
TabBar:  [★ Favorites] [📺 All Channels] [🗂 Groups] [🕘 History]
Toolbar: [logo] IPTV Player · [playlist active |⟳] · « Updated 3 min ago »
         ................................... ⚙️ → AdminPage (Playlists + Settings)
```

Le selecteur de playlist et son bouton de rafraichissement forment un groupe
accole (`AppComboBox.attachedRight` + `IconButton.framed`/`attachedLeft`), suivi
de l'etat de la derniere synchronisation reussie (`DatabaseManager.lastSync()`,
mis en forme par `Main.formatLastSync()` et rafraichi chaque minute).

Raccourcis : `F11` plein ecran · `Ctrl+F` focus recherche de l'onglet courant ·
`Espace` play/pause · `←`/`→` chaine precedente/suivante · `Echap` sortie du
plein ecran ou annulation du mode selection.

## Architecture UI

- **Navigation** visible par défaut (showPlayer = false)
- **PlayerPage** overlay plein écran quand showPlayer = true
  - [X] close → stopPlayback(), retour à la navigation
  - [≡] navigate → ChannelSearchPopup
- **ChannelSearchPopup** : popup modal pour chercher/changer de chaîne en mode player
- **GroupsPage** : deux états — liste des groupes → drill-down vers les chaînes d'un groupe

## Commandes

### Build (MinGW)
```powershell
Set-Location "build\Desktop_Qt_6_11_0_MinGW_64_bit-Debug"
cmake --build .
```

### Build (MSYS — nécessite `jom` dans le PATH)
```powershell
$env:Path = "C:\Qt\Tools\QtCreator\bin\jom;" + $env:Path
Set-Location "build\Desktop_x86_windows_msys_pe_64bit-Debug"
cmake --build .
```

### Rebuild complet
```powershell
Get-Process appIptvPlayer -ErrorAction SilentlyContinue | Stop-Process -Force
Set-Location "build\Desktop_Qt_6_11_0_MinGW_64_bit-Debug"
cmake --build .
```

### Lancer l'application
```powershell
& "build\Desktop_Qt_6_11_0_MinGW_64_bit-Debug\appIptvPlayer.exe"
```

### Killer le process
```powershell
Get-Process appIptvPlayer -ErrorAction SilentlyContinue | Stop-Process -Force
```

## Linux (Fedora 44)

Prérequis : `sudo dnf install gcc-c++ mpv-devel ninja-build` (Qt via l'installateur officiel dans `~/opt/Qt`, CMake/Ninja dans `~/opt/Qt/Tools`).

```bash
export PATH="$HOME/opt/Qt/Tools/Ninja:$HOME/opt/Qt/Tools/CMake/bin:$PATH"
cmake -B build-linux -G Ninja -DCMAKE_PREFIX_PATH="$HOME/opt/Qt/6.11.2/gcc_64" -DCMAKE_BUILD_TYPE=Debug
cmake --build build-linux
```

### Lancer l'application
```bash
./build-linux/appIptvPlayer
```

Notes :
- mpv est trouvé via pkg-config (libmpv système)
- `setlocale(LC_NUMERIC, "C")` est appliqué dans main.cpp sous Q_OS_UNIX — obligatoire pour libmpv avec une locale fr
- Kit Qt Creator : « Desktop Qt 6.11.2 » (auto-détecté), ouvrir directement le CMakeLists.txt

## Qt Creator

Le **seul** fichier de projet est `CMakeLists.txt` : « File > Open File or Project… » →
sélectionner `CMakeLists.txt`, choisir le kit *Desktop Qt 6.11.2*, puis Configure Project.

Ne **jamais** générer en parallèle un projet qmake (`.pro`) ni un projet générique
(`.creator` / `.files` / `.includes` / `.config`) : Qt Creator lance alors `make all`
à la racine, où il n'existe aucun Makefile → `No rule to make target 'all'. Stop.`

Deux réglages CMake existent pour l'IDE :
- `CMAKE_EXPORT_COMPILE_COMMANDS` → `compile_commands.json` pour clangd (indexation C++)
- `QT_QML_GENERATE_QMLLS_INI` → `.qmlls.ini` à la racine des sources, qui pointe qmlls
  vers le dossier de build (résolution des imports QML dans l'éditeur). Le fichier est
  régénéré à chaque build et ignoré par git ; il porte le chemin du **dernier** dossier
  de build configuré.

## Chargement des chaînes (DB-first)

Au démarrage, `Main.qml` affiche **immédiatement** les chaînes déjà en base
(`ChannelListModel.setChannels(playlistId)`) : l'application est utilisable hors
ligne et sans attendre le réseau. Le retéléchargement n'a lieu que si
`DatabaseManager.needsRefresh(id, 24)` est vrai (playlist vide ou dernière
synchro > 24 h), ou sur clic du bouton ⟳ de la barre d'outils. Pendant un
refresh, les chaînes affichées restent celles de la base ; un échec réseau
n'est donc pas bloquant.

`PlaylistLoader` horodate chaque synchro réussie (`markPlaylistSynced`) et
parse le M3U **hors du thread GUI** (`M3UParser::parseBuffer` + QtConcurrent) ;
l'écriture en base reste sur le thread principal (QSqlDatabase n'est pas
partageable entre threads).

## Base de données

Deux tables distinctes pour les données non-chaînes :

- `cache` : données regénérables, purgées par « Clear Cache » (`clearCache`)
- `settings` : réglages utilisateur (ex. `quality_suffixes`, horodatage de
  synchro par playlist) — **jamais** purgés. Une migration automatique déplace
  les anciennes clefs de `cache` vers `settings`.

L'historique de lecture est plafonné aux 500 dernières entrées.

## Suffixes de qualité

`quality_suffixes` contient la **liste complète** des suffixes servant à
regrouper les variantes d'une même chaîne (HD, FHD, H265, VOSTFR…), entièrement
éditable dans Administration > Settings > Quality Suffixes : l'utilisateur peut
retirer les suffixes fournis par défaut aussi bien qu'en ajouter, et « Reset »
revient à `ChannelGrouper::defaultSuffixes()`.

Le regroupement utilise `ChannelGrouper::buildPatternFromList()` avec cette
liste **telle quelle** — surtout pas `buildPattern()`, qui y réinjecterait les
suffixes par défaut et rendrait toute suppression sans effet.
`normalizeSuffixes()` nettoie, dédoublonne (insensible à la casse) et trie du
plus long au plus court : « FULLHD » doit être testé avant « HD ».

Au premier démarrage la liste est semée avec les valeurs par défaut, en y
reprenant l'ancien réglage `custom_suffixes` (qui ne contenait que les ajouts).

## Logs

Toutes les traces passent par des catégories (`src/utils/Logging.h`), limitées
à Warning par défaut. Pour activer :

```bash
QT_LOGGING_RULES="iptv.*.debug=true" ./build-linux/appIptvPlayer
QT_LOGGING_RULES="iptv.perf.debug=true;iptv.mpv.debug=true" ./build-linux/appIptvPlayer
```

Catégories : `iptv.db`, `iptv.model`, `iptv.loader`, `iptv.xtream`, `iptv.mpv`,
`iptv.render`, `iptv.perf`.

Les URLs Xtream portent les identifiants (`/live/<user>/<password>/<id>.ts`) :
toute URL journalisée doit passer par `LogUtils::scrubUrl()`.

## Architecture clé

- **MpvObject** : `QQuickFramebufferObject` wrapping libmpv, un handle mpv par instance
  - Le handle est un `std::shared_ptr` partagé avec `MpvRenderer` : libmpv impose
    de libérer le `mpv_render_context` (détruit avec le renderer, sur le thread de
    rendu) **avant** le handle. Le dernier des deux qui meurt le détruit.
  - Le renderer garde l'item dans un `QPointer` (il peut survivre à l'item).
- Plusieurs `MpvObject` peuvent coexister (multiplex 1-4 écrans)
- **Audio** : un seul slot démuté à la fois (`muted: !isActiveAudio`)
- **ChannelListModel** : singleton C++ (QAbstractListModel), filtré par texte/groupe
- **Pick mode** : clic sur `+` → `pendingPickSlot` → sélection dans ChannelSearchPopup
- **Layout multiplex** :
  - Mode 1 : 1 écran plein
  - Mode 2 : 2 écrans côte à côte
  - Mode 3 : 2 en haut, 1 en bas centré
  - Mode 4 : 2×2
- **MultiplexMode/ActiveAudioSlot** : propriétés dans Main.qml (source de vérité), synchronisées avec PlayerPage via signaux

## Enregistrement des types QML

Tous les types C++ exposés à QML sont enregistrés de manière **déclarative**, via
`QML_ELEMENT` / `QML_SINGLETON` dans les en-têtes — pas de `qmlRegisterType*` dans
`main.cpp`. C'est ce qui rend les types visibles pour l'éditeur et pour `qmllint`.

Ils appartiennent tous au module QML `IptvPlayer` (celui de `qt_add_qml_module`), donc
les `.qml` du module y accèdent **sans import** (`DatabaseManager`, `ChannelListModel`,
`PlaylistModel`, `PlaylistLoader`, `MpvObject`, `ClipboardHelper`, `SleepInhibitor`).

Pour ajouter un type : `QML_ELEMENT` (+ `QML_SINGLETON` pour un singleton) dans le
`.h`, et ajouter le `.h`/`.cpp` aux sources de `appIptvPlayer`. Un singleton adossé à
une instance C++ existante fournit `static T *create(QQmlEngine *, QJSEngine *)` et
appelle `QJSEngine::setObjectOwnership(..., CppOwnership)` (cf. `DatabaseManager`).

Le fichier de registration généré inclut les en-têtes **par leur seul nom de fichier** :
tout nouveau sous-dossier de `src/` doit être ajouté à `target_include_directories()`.

## Veille système

`SleepInhibitor` inhibe la mise en veille pendant la lecture :
`SetThreadExecutionState` sous Windows, `org.freedesktop.ScreenSaver` via D-Bus
sous Linux (nécessite `Qt6::DBus`, détecté par CMake → `HAS_DBUS`).

## Design system

Tous les styles passent par deux singletons QML ; **aucun literal de couleur,
d'espacement ou de taille de police ne doit apparaitre ailleurs**.

### `Theme.qml`
**Deux palettes** (`darkPalette` / `lightPalette`) exposant les memes jetons ;
les fichiers QML lisent toujours `Theme.<jeton>`, jamais la palette. Le mode
vit dans `Theme.mode` (`modeAuto` / `modeLight` / `modeDark`), est persiste via
`QtCore.Settings` (categorie `Appearance`) et se regle dans Administration >
Settings > Appearance. En mode auto, un `Timer` d'une minute reevalue l'heure
locale : theme clair de `dayStartHour` (7 h) a `nightStartHour` (19 h), sombre
ensuite.

Les jetons **independants du mode** couvrent la zone de lecture, qui reste
sombre dans les deux themes : `videoBg`, `scrim*`, `glass*`, `scrimText`,
`scrimTextMuted`, `scrimTextDim` (tout texte pose sur la video) et
`logoBackdrop` (fond des logos de chaines, souvent dessines pour du sombre).
Un calque pose sur la video ne doit donc jamais utiliser `Theme.text`.

Jetons regroupes par role : surfaces (`bg` → `surface` → `surfaceAlt` →
`surfaceHi`, `border`/`borderStrong`), accent (`accent`, `accentHover`,
`accentPressed`, `accentSoft`, `textOnAccent`), texte (`text`, `textMuted`,
`textDim`), statuts (`danger`, `success`, `warning`, `live`), survol/appui
(`hover`, `pressed`), calques poses sur la video (`scrim`, `scrimStrong`,
`glass*`), rayons (`radiusSm/Md/Lg/Pill`), espacements (`spacingXs` → `spacingXl`,
grille de 4), typo (`fontXs` → `fontXl`), tailles de controle (`controlXs` →
`controlLg`, `iconXs` → `iconXl`) et durees (`durFast`, `durNormal`, `durSlow`).

Un nom de propriete ne doit **jamais** commencer par `on` + majuscule : QML le
lit comme un gestionnaire de signal (d'ou `textOnAccent` et non `onAccent`).

### `Mdi.qml` — icones
Jeu d'icones unique : Material Design Icons v7.4.47, fonte embarquee dans le
module QML (`fonts/materialdesignicons-webfont.ttf`, cf. `RESOURCES` du
`qt_add_qml_module`) et chargee une seule fois par le `FontLoader` du singleton.

Les points de code MDI sont > 0xFFFF : ils s'ecrivent `String.fromCodePoint(0xF0450)`
et **pas** `"\uF0450"`. Pour ajouter une icone : relever le point de code sur
[pictogrammers.com/library/mdi](https://pictogrammers.com/library/mdi) et
l'ajouter dans la section thematique correspondante de `Mdi.qml`.

Usage : `MdiIcon { glyph: Mdi.refresh }`, `IconButton { glyph: Mdi.cogOutline }`,
`AppButton { glyph: Mdi.plus }`.

### Composants
- `IconButton` : `glyph`, `tooltip`, `round`, `checkable`, `danger`, plus
  `tinted` (pastille claire sur la video) et `tinted` + `dark` (pastille sombre
  des controles centraux du player). Survol, appui (leger retrait d'echelle) et
  etat coche sont geres par le composant — ne jamais empiler une `MouseArea`
  dans un bouton.
- `AppButton` : `variant: AppButton.Primary | Secondary | Ghost | Danger`.
- `SegmentedControl` : options exclusives dans un meme boitier (`options`,
  `currentValue`, signal `selected`).
- `AppTabBar` / `AppTabButton` : onglets compacts alignes a gauche.
  `AppTabButton` fixe `width: implicitWidth` : c'est ce qui empeche `TabBar` de
  repartir la largeur a parts egales.
- Popups poses sur la video (`ChannelSearchPopup`, variantes de qualite, infos) :
  `parent: Overlay.overlay`, position calculee puis **bornee a la fenetre**
  (cf. `qualityPopup.reposition()` dans `PlayerSlot.qml`). Leur hauteur doit etre
  deduite du modele (nombre de lignes × hauteur de ligne) et non du contenu
  rendu, sinon le premier positionnement se fait sur une hauteur encore nulle.

## Convention QML

- `qsTr()` pour les textes affichés
- Contrôles par player dans `PlayerSlot.qml` (barre haute, play/pause centré, `+` en dessous)
- Contrôles globaux dans `PlayerPage.qml` (mode selector + volume)
- Auto-hide des contrôles après 3s d'inactivité
- **`qmllint` doit rester à zéro warning** (`cmake --build build-linux --target all_qmllint`) :
  - accès toujours qualifiés par un id (`root.x`, `window.x`)
  - délégués : `required property var model` / `required property int index`
    plutôt que l'injection implicite, et `pragma ComponentBehavior: Bound`
  - dans un Layout : `Layout.preferredWidth/Height`, jamais `width`/`height`
- `ChannelListModel` est **partagé** par les onglets : chaque page réapplique son
  propre filtre via `activate()` quand elle redevient visible
- Le filtre texte multi-tokens est unique : `ChannelListModel.matchesFilter()`

## Volume

- **Binding** : `PlayerSlot → MpvObject.volume` courbe puissance `^1.1` pour compenser la perception logarithmique
- **Curseur** dans `PlayerPage.qml`, id `volumeSlider`, largeur 130px, `stepSize: 1`, `value: 100` (statique, pas de binding pour éviter le verrouillage)
- **Bouton muet** à sa gauche : `PlayerPage.toggleMute()` mémorise le niveau dans `lastVolume`
- Les 4 PlayerSlot lient `globalVolume` directement à `volumeSlider.value` (pas d'intermédiaire PlayerPage.globalVolume)
- **Persistance** : `QtCore.Settings` dans `PlayerPage.qml`, alias sur `volumeSlider.value`

## Overlays

- **PlayerSlot** : `controlsOpacity` et `overlayActive` (défaut `false`). `showControls()` → `controlsOpacity=1, overlayActive=true`, timer 3s redémarré. Timer → `controlsOpacity=0, overlayActive=false` + cooldown 500ms.
- **Top bar (PlayerPage)** : `opacity: slotN.overlayActive || ... ? 1.0 : 0.0` — binding direct sur `overlayActive` des 4 slots. Visible dès qu'au moins un slot a son overlay actif.
- **Hover** : `onPositionChanged` avec garde `controlsOpacity < 0.5` pour éviter le cycle de réaffichage permanent (onPositionChanged qui spam à cause de la souris/vidéo).
- **Double-clic** : `onDoubleClicked` dans la hoverArea de chaque PlayerSlot → signal `doubleClickRequested()` → `PlayerPage.toggleFullscreenRequested()` → `Main.qml` toggle `Window.FullScreen`.

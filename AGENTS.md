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
TabBar: [Favorites] [All Channels] [Groups] [History]
Toolbar: ⟳ refresh playlist · ⚙️ → AdminPage (Playlists + Settings)
```

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
- `settings` : réglages utilisateur (ex. `custom_suffixes`, horodatage de
  synchro par playlist) — **jamais** purgés. Une migration automatique déplace
  les anciennes clefs de `cache` vers `settings`.

L'historique de lecture est plafonné aux 500 dernières entrées.

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

## Convention QML

- Palette sombre : `#1a1a2e` fond, `#16213e` cartes, `#0f3460` accent, `#e0e0e0` texte
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
- Les 4 PlayerSlot lient `globalVolume` directement à `volumeSlider.value` (pas d'intermédiaire PlayerPage.globalVolume)
- **Persistance** : `QtCore.Settings` dans `PlayerPage.qml`, alias sur `volumeSlider.value`

## Overlays

- **PlayerSlot** : `controlsOpacity` et `overlayActive` (défaut `false`). `showControls()` → `controlsOpacity=1, overlayActive=true`, timer 3s redémarré. Timer → `controlsOpacity=0, overlayActive=false` + cooldown 500ms.
- **Top bar (PlayerPage)** : `opacity: slotN.overlayActive || ... ? 1.0 : 0.0` — binding direct sur `overlayActive` des 4 slots. Visible dès qu'au moins un slot a son overlay actif.
- **Hover** : `onPositionChanged` avec garde `controlsOpacity < 0.5` pour éviter le cycle de réaffichage permanent (onPositionChanged qui spam à cause de la souris/vidéo).
- **Double-clic** : `onDoubleClicked` dans la hoverArea de chaque PlayerSlot → signal `doubleClickRequested()` → `PlayerPage.toggleFullscreenRequested()` → `Main.qml` toggle `Window.FullScreen`.

# OTTix

## Description
Application Qt 6 / QML avec backend C++ pour lire des flux IPTV (M3U / XTREAM Codes) via libmpv.

## Structure

```
OTTix/
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
    │                     # LogoPalette (fond des logos), Logging (catégories),
    │                     # LogUtils (masquage d'URL)
    └── xtream/           # XtreamApi
```

## Navigation

```
TabBar:  [★ Favorites] [📺 All Channels] [🗂 Groups] [🕘 History]
Toolbar: [logo] OTTix · [playlist active |⟳] · « Updated 3 min ago »
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
Get-Process appOTTix -ErrorAction SilentlyContinue | Stop-Process -Force
Set-Location "build\Desktop_Qt_6_11_0_MinGW_64_bit-Debug"
cmake --build .
```

### Lancer l'application
```powershell
& "build\Desktop_Qt_6_11_0_MinGW_64_bit-Debug\appOTTix.exe"
```

### Killer le process
```powershell
Get-Process appOTTix -ErrorAction SilentlyContinue | Stop-Process -Force
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
./build-linux/appOTTix
```

Notes :
- mpv est trouvé via pkg-config (libmpv système)
- `setlocale(LC_NUMERIC, "C")` est appliqué dans main.cpp sous Q_OS_UNIX — obligatoire pour libmpv avec une locale fr
- Kit Qt Creator : « Desktop Qt 6.11.2 » (auto-détecté), ouvrir directement le CMakeLists.txt

## Packaging et distribution

Tout vit dans `packaging/` ; les workflows GitHub Actions dans `.github/workflows/`.

| Cible | Format | Fichiers |
|---|---|---|
| Windows | Installateur Inno Setup + zip portable | `packaging/windows/` |
| Linux | Bundle Flatpak (runtime KDE 6.11) | `packaging/flatpak/`, `packaging/linux/` |

L'identifiant d'application est `io.github.fyutins.OTTix` : il nomme le
`.desktop`, le metainfo AppStream, l'icône et l'app-id Flatpak. Le changer
impose de renommer les quatre.

La version des artefacts vient du tag git : le workflow `Release` passe
`-DOTTIX_VERSION=x.y.z`, qui alimente `project(VERSION)`, la ressource
`.rc` Windows et l'installateur. Ne pas coder la version en dur ailleurs.

### Windows

`cmake --install <build> --prefix dist` produit **le dossier complet** :
`install(CODE ...)` appelle `windeployqt --no-opengl-sw --compiler-runtime
--qmldir <sources>`, et `-DMPV_RUNTIME_DLL=<chemin>` ajoute `libmpv-2.dll`.
`--no-opengl-sw` est obligatoire : l'OpenGL logiciel (`opengl32sw.dll`) fige la
fenêtre quand on la déplace pendant une lecture mpv.

En CI, libmpv vient des builds shinchiro (`.github/scripts/fetch-libmpv.ps1`,
paquet `mpv-dev-x86_64`), et le compilateur est MinGW 13.1.0 — celui dont
dépend le paquet Qt `win64_mingw`.

La CI Windows est figée sur **Qt 6.10.3**, pas 6.11.2 : le dépôt Qt a changé
d'arborescence pour 6.11 sous Windows (un sous-dossier par architecture,
`qt6_6112/qt6_6112_mingw/`) et aqtinstall 3.3.0 cherche encore
`qt6_6112/qt6_6112/`. Linux n'est pas touché. À repasser en 6.11 quand
aqtinstall suivra — d'ici là, ne pas utiliser d'API Qt postérieure à 6.10.

L'installateur s'installe par défaut par utilisateur (`PrivilegesRequired=lowest`,
donc sans élévation) et **conserve** `%LOCALAPPDATA%\OTTix` à la
désinstallation (playlists, favoris, historique).

### Linux / Flatpak

Le runtime `org.kde.Platform//6.11` fournit Qt 6.11 et ffmpeg : rien de tout
cela n'est bundlé. Seul mpv est compilé, avec ses dépendances absentes du
runtime (libplacebo, libass, libXpresent, uchardet) — chaîne alignée sur le
manifeste de Haruna, à re-synchroniser quand mpv monte de version.

```bash
sudo dnf install flatpak-builder
flatpak install --user -y flathub org.kde.Platform//6.11 org.kde.Sdk//6.11
flatpak-builder --user --force-clean --install build-flatpak-out \
    packaging/flatpak/io.github.fyutins.OTTix.yml
flatpak run io.github.fyutins.OTTix
```

Sans `flatpak-builder` natif, il existe la version flatpak — mais elle ne voit
pas l'installation utilisateur (son `XDG_DATA_HOME` est redirigé vers
`~/.var/app/`), d'où le `FLATPAK_USER_DIR` explicite :

```bash
flatpak install --user -y flathub org.flatpak.Builder
flatpak run --env=FLATPAK_USER_DIR="$HOME/.local/share/flatpak" \
    --command=flatpak-builder org.flatpak.Builder \
    --user --disable-rofiles-fuse --force-clean \
    --state-dir build-flatpak-state --repo build-flatpak-repo \
    build-flatpak-out packaging/flatpak/io.github.fyutins.OTTix.yml
```

Le linter Flathub se lance de la même façon :
`flatpak run --command=flatpak-builder-lint org.flatpak.Builder manifest <manifeste>`.

Le manifeste construit **le dossier de travail** (`type: dir`), pas un tag git :
il packageera les modifications non committées.

### Publier une version

```bash
git tag -a v0.2.0 -m "v0.2.0" && git push origin v0.2.0
```

Le workflow `Release` construit les trois artefacts et crée la release GitHub.
Penser à ajouter un `<release>` dans
`packaging/linux/io.github.fyutins.OTTix.metainfo.xml` (AppStream) avant
de taguer.

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

La base vit dans `QStandardPaths::AppLocalDataLocation`, soit
`~/.local/share/OTTix/OTTix/iptv_player.db` et
`%LOCALAPPDATA%\OTTix\OTTix\iptv_player.db`. Ce chemin découle de
`setOrganizationName` / `setApplicationName` : le renommage IptvPlayer → OTTix
l'a déplacé, les installations antérieures gardent leurs données sous
`…/IptvPlayer/IptvPlayer/`.

Deux tables distinctes pour les données non-chaînes :

- `cache` : données regénérables, purgées par « Clear Cache » (`clearCache`)
- `settings` : réglages utilisateur (ex. `quality_suffixes`, horodatage de
  synchro par playlist) — **jamais** purgés. Une migration automatique déplace
  les anciennes clefs de `cache` vers `settings`.

L'historique de lecture est plafonné aux 500 dernières entrées.

## Fond des logos de chaînes

Un fond uni unique rend illisible tout logo peint dans une teinte proche.
`LogoPalette` (singleton QML, `src/utils/LogoPalette.cpp`) analyse donc chaque
logo et renvoie le fond à poser derrière lui :

- histogramme grossier (12 teintes × 4 niveaux de clarté + une classe
  achromatique), pixels quasi transparents ignorés, pixels saturés pondérés :
  la couleur retenue est celle qu'on garde en tête d'un logo ;
- **logo détouré** (peu de pixels opaques) : ses pixels se posent directement
  sur le fond, donc fond contrasté — sombre si le logo est clair, clair sinon.
  La bascule se fait sur la **luminance relative WCAG** (seuil 0,18, point où
  les deux fonds candidats donnent le même rapport de contraste), et non sur la
  clarté HSL, qui se trompe sur les couleurs vives ;
- **logo plein** (> 92 % de pixels opaques) : le fond ne dépasse qu'en liseré,
  on l'accorde alors au logo (même teinte, plus sombre) ;
- **glyphes clairs sans teinte** — le cas le plus courant — : couleur invalide,
  l'appelant garde `Theme.logoBackdrop`.

La résolution est asynchrone (`backdrop()` renvoie une couleur invalide, puis
`backdropResolved` est émis), plafonnée à 4 requêtes simultanées, et le
résultat est persisté dans la table `cache` sous le préfixe `logo_bg1:` —
**à incrémenter dès que la dérivation change**, sinon les anciens fonds restent
servis. Un échec réseau n'est pas mémorisé.

Côté QML, `ChannelDelegate` lit `LogoPalette.backdrop(url)` puis écoute
`backdropResolved` (les délégués sont recyclés : le fond est réévalué à chaque
changement de `channelLogo`).

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
QT_LOGGING_RULES="iptv.*.debug=true" ./build-linux/appOTTix
QT_LOGGING_RULES="iptv.perf.debug=true;iptv.mpv.debug=true" ./build-linux/appOTTix
```

Catégories : `iptv.db`, `iptv.model`, `iptv.loader`, `iptv.xtream`, `iptv.mpv`,
`iptv.render`, `iptv.perf`, `iptv.logo`.

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

Ils appartiennent tous au module QML `OTTix` (celui de `qt_add_qml_module`), donc
les `.qml` du module y accèdent **sans import** (`DatabaseManager`, `ChannelListModel`,
`PlaylistModel`, `PlaylistLoader`, `MpvObject`, `ClipboardHelper`, `SleepInhibitor`).

Pour ajouter un type : `QML_ELEMENT` (+ `QML_SINGLETON` pour un singleton) dans le
`.h`, et ajouter le `.h`/`.cpp` aux sources de `appOTTix`. Un singleton adossé à
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
`logoBackdrop` (fond **par defaut** des logos de chaines : le fond reel est
derive du logo lui-meme, cf. « Fond des logos de chaînes »).
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

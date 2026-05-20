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
├── AdminDialog.qml       # Dialog admin (Playlists + Settings)
├── PlaylistDialog.qml    # Dialogue d'ajout de playlist
├── SettingsPage.qml      # Placeholder (utilisé via AdminDialog)
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
    ├── utils/            # ClipboardHelper
    └── xtream/           # XtreamApi
```

## Navigation

```
TabBar: [All Channels] [Groups] [Favorites]
Admin: ⚙️ button in toolbar → AdminDialog (Playlists + Settings)
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

## Architecture clé

- **MpvObject** : `QQuickFramebufferObject` wrapping libmpv, un handle mpv par instance
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

## Convention QML

- Palette sombre : `#1a1a2e` fond, `#16213e` cartes, `#0f3460` accent, `#e0e0e0` texte
- `qsTr()` pour les textes affichés
- Contrôles par player dans `PlayerSlot.qml` (barre haute, play/pause centré, `+` en dessous)
- Contrôles globaux dans `PlayerPage.qml` (mode selector + volume)
- Auto-hide des contrôles après 3s d'inactivité

## Volume

- **Binding** : `PlayerSlot → MpvObject.volume` courbe puissance `^1.1` pour compenser la perception logarithmique
- **Curseur** dans `PlayerPage.qml`, id `volumeSlider`, largeur 130px, `stepSize: 1`, `value: 100` (statique, pas de binding pour éviter le verrouillage)
- Les 4 PlayerSlot lient `globalVolume` directement à `volumeSlider.value` (pas d'intermédiaire PlayerPage.globalVolume)
- **Persistance** : `QtCore.Settings` dans `PlayerPage.qml`, alias sur `volumeSlider.value`

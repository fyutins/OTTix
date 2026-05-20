# IPTV Player

## Description
Application Qt 6 / QML avec backend C++ pour lire des flux IPTV (M3U / XTREAM Codes) via libmpv.

## Structure

```
IptvPlayer/
├── Main.qml              # Fenêtre principale + multiplex
├── PlayerSlot.qml        # Zone player individuelle (multiplex)
├── ChannelDelegate.qml   # Tuile de chaîne dans la grille
├── ChannelListPage.qml   # Liste des chaînes avec recherche/filtre
├── FavoritesPage.qml     # Chaînes favorites
├── PlayerPage.qml        # Placeholder
├── PlaylistDialog.qml    # Dialogue d'ajout de playlist
├── SettingsPage.qml      # Paramètres
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
- **Pick mode** : clic sur `+` → `pendingPickSlot` → sélection dans la liste des chaînes
- **Layout multiplex** : 
  - Mode 1 : 1 écran plein
  - Mode 2 : 2 écrans côte à côte
  - Mode 3 : 2 en haut, 1 en bas centré
  - Mode 4 : 2×2

## Convention QML

- Palette sombre : `#1a1a2e` fond, `#16213e` cartes, `#0f3460` accent, `#e0e0e0` texte
- `qsTr()` pour les textes affichés
- Contrôles par player dans `PlayerSlot.qml` (barre haute, play/pause centré, `+` en dessous)
- Contrôles globaux dans `Main.qml` (mode selector + volume)
- Auto-hide des contrôles après 3s d'inactivité

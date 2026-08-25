# OTTix

Qt 6 / QML application with a C++ backend that plays IPTV streams (M3U / Xtream
Codes) through libmpv.

## Structure

```
OTTix/
├── Main.qml              # Main window — navigation + player overlay
├── PlayerPage.qml        # Fullscreen player view (multiplex, controls, close+nav)
├── PlayerSlot.qml        # Single player pane (multiplex)
├── ChannelListPage.qml   # All channels, with search
├── GroupsPage.qml        # Group browser with drill-down
├── FavoritesPage.qml     # Favorite channels
├── HistoryPage.qml       # Watch history
├── AdminPage.qml         # Admin page (Playlists + Settings)
├── PlaylistDialog.qml    # Add / edit a playlist
├── ChannelSearchPopup.qml# Channel picker opened from the player
├── ChannelGrid.qml, GroupGrid.qml, ChannelDelegate.qml
├── ChannelSearchBar.qml, GroupSearchBar.qml
│
│   # ── Design system ──
├── Theme.qml             # Singleton: colors, spacing, typography, durations
├── Mdi.qml               # Singleton: Material Design Icons font + code points
├── MdiIcon.qml, IconButton.qml, AppButton.qml, SegmentedControl.qml
├── AppTabBar.qml, AppTabButton.qml, AppComboBox.qml, AppScrollBar.qml
├── AppMenu.qml, AppMenuItem.qml, SearchField.qml, SettingsCard.qml
├── ConfirmDialog.qml, EmptyState.qml, Tip.qml, ScreenLayoutIcon.qml
│
├── fonts/                # materialdesignicons-webfont.ttf (+ NOTICE.md)
├── packaging/            # Windows installer + Flatpak manifest
├── CMakeLists.txt
└── src/
    ├── main.cpp          # C++ entry point
    ├── database/         # SQLite (DatabaseManager)
    ├── loader/           # PlaylistLoader (M3U + Xtream)
    ├── models/           # ChannelListModel, PlaylistModel
    ├── parser/           # M3UParser
    ├── player/           # MpvObject, MpvRenderer (libmpv OpenGL)
    ├── utils/            # ClipboardHelper, SleepInhibitor, ChannelGrouper,
    │                     # LogoPalette, Logging, LogUtils
    └── xtream/           # XtreamApi
```

## UI

```
TabBar:  [★ Favorites] [📺 All Channels] [🗂 Groups] [🕘 History]
Toolbar: [logo] OTTix · [active playlist |⟳] · "Updated 3 min ago"
         ................................... ⚙️ → AdminPage
```

- Navigation is visible by default (`showPlayer = false`); **PlayerPage** is a
  fullscreen overlay when `showPlayer = true` — `[X]` stops playback and returns,
  `[≡]` opens **ChannelSearchPopup** to switch channel without leaving the player.
- **GroupsPage** has two states: group list → drill-down into one group.
- The playlist selector and its refresh button form one attached group
  (`AppComboBox.attachedRight` + `IconButton.framed`/`attachedLeft`), followed by
  the last successful sync (`DatabaseManager.lastSync()`, formatted by
  `Main.formatLastSync()`, refreshed every minute).
- Shortcuts: `F11` fullscreen · `Ctrl+F` focus the current tab's search ·
  `Space` play/pause · `←`/`→` previous/next channel · `Esc` leave fullscreen or
  cancel selection mode.

## Build (Linux, Fedora 44)

Prerequisites: `sudo dnf install gcc-c++ mpv-devel ninja-build` (Qt from the
official installer in `~/opt/Qt`, CMake/Ninja under `~/opt/Qt/Tools`).

```bash
export PATH="$HOME/opt/Qt/Tools/Ninja:$HOME/opt/Qt/Tools/CMake/bin:$PATH"
cmake -B build-linux -G Ninja -DCMAKE_PREFIX_PATH="$HOME/opt/Qt/6.11.2/gcc_64" -DCMAKE_BUILD_TYPE=Debug
cmake --build build-linux
./build-linux/appOTTix
```

mpv is found through pkg-config (system libmpv). `setlocale(LC_NUMERIC, "C")` is
applied in `main.cpp` under `Q_OS_UNIX` — required for libmpv under a French locale.

## Packaging

Everything lives in `packaging/`; the GitHub Actions workflows in `.github/workflows/`.

| Target | Format | Files |
|---|---|---|
| Windows | Inno Setup installer + portable zip | `packaging/windows/` |
| Linux | Flatpak bundle (KDE 6.11 runtime) | `packaging/flatpak/`, `packaging/linux/` |

The application id `io.github.fyutins.OTTix` names the `.desktop` file, the
AppStream metainfo, the icon and the Flatpak app-id — renaming means renaming all four.

Artifact versions come from the git tag: the `Release` workflow passes
`-DOTTIX_VERSION=x.y.z`, which feeds `project(VERSION)`, the Windows `.rc`
resource and the installer. Never hard-code the version anywhere else.

### Windows

`cmake --install <build> --prefix dist` produces the complete folder:
`install(CODE ...)` runs `windeployqt --no-opengl-sw --compiler-runtime --qmldir
<sources>`, and `-DMPV_RUNTIME_DLL=<path>` adds `libmpv-2.dll`. `--no-opengl-sw`
is mandatory: software OpenGL (`opengl32sw.dll`) freezes the window when it is
moved during mpv playback.

In CI, libmpv comes from the shinchiro builds
(`.github/scripts/fetch-libmpv.ps1`, package `mpv-dev-x86_64`), and the compiler
is MinGW 13.1.0 — the one the Qt `win64_mingw` package depends on.

Windows CI is pinned to **Qt 6.10.3**, not 6.11.2: the Qt repository changed its
layout for 6.11 on Windows (one subfolder per architecture,
`qt6_6112/qt6_6112_mingw/`) and aqtinstall 3.3.0 still looks for
`qt6_6112/qt6_6112/`. Linux is unaffected. Move back to 6.11 once aqtinstall
catches up — until then, do not use Qt APIs newer than 6.10.

The installer is per-user by default (`PrivilegesRequired=lowest`, no elevation)
and **keeps** `%LOCALAPPDATA%\OTTix` on uninstall (playlists, favorites, history).

### Linux / Flatpak

The `org.kde.Platform//6.11` runtime provides Qt 6.11 and ffmpeg, so neither is
bundled. Only mpv is built, along with the dependencies missing from the runtime
(libplacebo, libass, libXpresent, uchardet) — aligned with Haruna's manifest,
to re-sync whenever mpv is bumped.

```bash
sudo dnf install flatpak-builder
flatpak install --user -y flathub org.kde.Platform//6.11 org.kde.Sdk//6.11
flatpak-builder --user --force-clean --install build-flatpak-out \
    packaging/flatpak/io.github.fyutins.OTTix.yml
flatpak run io.github.fyutins.OTTix
```

Without a native `flatpak-builder`, the flatpak'd one works but does not see the
user installation (its `XDG_DATA_HOME` is redirected to `~/.var/app/`), hence the
explicit `FLATPAK_USER_DIR`:

```bash
flatpak install --user -y flathub org.flatpak.Builder
flatpak run --env=FLATPAK_USER_DIR="$HOME/.local/share/flatpak" \
    --command=flatpak-builder org.flatpak.Builder \
    --user --disable-rofiles-fuse --force-clean \
    --state-dir build-flatpak-state --repo build-flatpak-repo \
    build-flatpak-out packaging/flatpak/io.github.fyutins.OTTix.yml
```

The Flathub linter runs the same way:
`flatpak run --command=flatpak-builder-lint org.flatpak.Builder manifest <manifest>`.

The manifest builds **the working directory** (`type: dir`), not a git tag: it
packages uncommitted changes.

### Releasing

```bash
git tag -a v0.2.0 -m "v0.2.0" && git push origin v0.2.0
```

The `Release` workflow builds the three artifacts and creates the GitHub release.
Add a `<release>` entry to
`packaging/linux/io.github.fyutins.OTTix.metainfo.xml` before tagging.

## Channel loading (DB-first)

On startup `Main.qml` shows the channels already in the database
(`ChannelListModel.setChannels(playlistId)`), so the app is usable offline and
without waiting on the network. A re-download happens only when
`DatabaseManager.needsRefresh(id, 24)` is true (empty playlist or last sync older
than 24 h), or on the toolbar ⟳ button. During a refresh the displayed channels
stay the ones from the database, so a network failure is never blocking.

`PlaylistLoader` timestamps every successful sync (`markPlaylistSynced`) and
parses M3U **off the GUI thread** (`M3UParser::parseBuffer` + QtConcurrent);
database writes stay on the main thread (QSqlDatabase is not shareable between
threads).

## Database

The database lives in `QStandardPaths::AppLocalDataLocation`:
`~/.local/share/OTTix/OTTix/iptv_player.db` and
`%LOCALAPPDATA%\OTTix\OTTix\iptv_player.db`. That path derives from
`setOrganizationName` / `setApplicationName`; the IptvPlayer → OTTix rename moved
it, so older installs keep their data under `…/IptvPlayer/IptvPlayer/`.

Two separate tables hold non-channel data:

- `cache`: regenerable data, purged by "Clear Cache" (`clearCache`)
- `settings`: user settings (e.g. `quality_suffixes`, per-playlist sync
  timestamps) — **never** purged. A one-time migration moves old keys from
  `cache` to `settings`.

Watch history is capped at the last 500 entries.

## Quality suffixes

`quality_suffixes` holds the **complete** list of suffixes used to group variants
of the same channel (HD, FHD, H265, VOSTFR…), fully editable in
Administration > Settings > Quality Suffixes: the user can remove the built-in
suffixes as well as add new ones, and "Reset" restores
`ChannelGrouper::defaultSuffixes()`.

Grouping uses `ChannelGrouper::buildPatternFromList()` with that list **as-is** —
never `buildPattern()`, which would re-inject the defaults and make removals
ineffective. `normalizeSuffixes()` trims, de-duplicates (case-insensitively) and
sorts longest first: "FULLHD" must be tested before "HD".

On first start the list is seeded with the defaults plus the old
`custom_suffixes` setting (which only held the additions).

## Logs

All traces go through categories (`src/utils/Logging.h`), capped at Warning by
default:

```bash
QT_LOGGING_RULES="iptv.*.debug=true" ./build-linux/appOTTix
QT_LOGGING_RULES="iptv.perf.debug=true;iptv.mpv.debug=true" ./build-linux/appOTTix
```

Categories: `iptv.db`, `iptv.model`, `iptv.loader`, `iptv.xtream`, `iptv.mpv`,
`iptv.render`, `iptv.perf`, `iptv.logo`.

Xtream URLs carry credentials (`/live/<user>/<password>/<id>.ts`): every logged
URL must go through `LogUtils::scrubUrl()`.

## Player architecture

- **MpvObject**: `QQuickFramebufferObject` wrapping libmpv, one mpv handle per instance.
  - The handle is a `std::shared_ptr` shared with `MpvRenderer`: libmpv requires
    the `mpv_render_context` (destroyed with the renderer, on the render thread)
    to be freed **before** the handle. Whichever of the two dies last destroys it.
  - The renderer holds the item in a `QPointer` (it can outlive the item).
- Several `MpvObject` can coexist (1–4 screen multiplex).
- **Audio**: exactly one slot unmuted at a time (`muted: !isActiveAudio`).
- **ChannelListModel**: C++ singleton (QAbstractListModel), filtered by text/group.
- **Pick mode**: click `+` → `pendingPickSlot` → pick in ChannelSearchPopup.
- **Multiplex layouts**: 1 = full screen · 2 = side by side · 3 = two on top, one
  centered below · 4 = 2×2.
- **MultiplexMode/ActiveAudioSlot**: properties in `Main.qml` (source of truth),
  synchronized with PlayerPage through signals.

## QML type registration

Every C++ type exposed to QML is registered **declaratively**, via `QML_ELEMENT` /
`QML_SINGLETON` in the headers — no `qmlRegisterType*` in `main.cpp`. That is what
makes the types visible to the editor and to `qmllint`.

They all belong to the `OTTix` QML module (the one from `qt_add_qml_module`), so
the module's `.qml` files reach them **without an import** (`DatabaseManager`,
`ChannelListModel`, `PlaylistModel`, `PlaylistLoader`, `MpvObject`,
`ClipboardHelper`, `SleepInhibitor`).

To add a type: `QML_ELEMENT` (+ `QML_SINGLETON` for a singleton) in the `.h`, then
add the `.h`/`.cpp` to the `appOTTix` sources. A singleton backed by an existing
C++ instance provides `static T *create(QQmlEngine *, QJSEngine *)` and calls
`QJSEngine::setObjectOwnership(..., CppOwnership)` (see `DatabaseManager`).

The generated registration file includes headers **by file name only**: every new
subfolder of `src/` must be added to `target_include_directories()`.

## System sleep

`SleepInhibitor` blocks sleep during playback: `SetThreadExecutionState` on
Windows, `org.freedesktop.ScreenSaver` over D-Bus on Linux (needs `Qt6::DBus`,
detected by CMake → `HAS_DBUS`).

## Design system

All styling goes through two QML singletons; **no color, spacing or font-size
literal may appear anywhere else**.

### `Theme.qml`

Two palettes (`darkPalette` / `lightPalette`) expose the same tokens; QML files
always read `Theme.<token>`, never the palette. The mode lives in `Theme.mode`
(`modeAuto` / `modeLight` / `modeDark`), is persisted through `QtCore.Settings`
(`Appearance` category) and is set in Administration > Settings > Appearance. In
auto mode a one-minute `Timer` re-evaluates local time: light theme from
`dayStartHour` (7 am) to `nightStartHour` (7 pm), dark afterwards.

Mode-independent tokens cover the playback area, which stays dark in both themes:
`videoBg`, `scrim*`, `glass*`, `scrimText`, `scrimTextMuted`, `scrimTextDim` (any
text laid over the video) and `logoBackdrop` (default channel-logo backdrop; the
real one is derived from the logo itself by `LogoPalette`). A layer over the video
must therefore never use `Theme.text`.

Tokens by role: surfaces (`bg` → `surface` → `surfaceAlt` → `surfaceHi`,
`border`/`borderStrong`), accent (`accent`, `accentHover`, `accentPressed`,
`accentSoft`, `textOnAccent`), text (`text`, `textMuted`, `textDim`), status
(`danger`, `success`, `warning`, `live`), hover/press (`hover`, `pressed`), video
overlays (`scrim`, `scrimStrong`, `glass*`), radii (`radiusSm/Md/Lg/Pill`),
spacing (`spacingXs` → `spacingXl`, 4 px grid), typography (`fontXs` → `fontXl`),
control sizes (`controlXs` → `controlLg`, `iconXs` → `iconXl`) and durations
(`durFast`, `durNormal`, `durSlow`).

A property name must **never** start with `on` + uppercase: QML reads that as a
signal handler (hence `textOnAccent`, not `onAccent`).

### `Mdi.qml` — icons

One icon set: Material Design Icons v7.4.47, font embedded in the QML module
(`fonts/materialdesignicons-webfont.ttf`, see `RESOURCES` in
`qt_add_qml_module`) and loaded once by the singleton's `FontLoader`.

MDI code points are > 0xFFFF: write them as `String.fromCodePoint(0xF0450)`, **not**
`"\uF0450"`. To add an icon, look up its code point on
[pictogrammers.com/library/mdi](https://pictogrammers.com/library/mdi) and add it
to the matching section of `Mdi.qml`.

Usage: `MdiIcon { glyph: Mdi.refresh }`, `IconButton { glyph: Mdi.cogOutline }`,
`AppButton { glyph: Mdi.plus }`.

### Components

- `IconButton`: `glyph`, `tooltip`, `round`, `checkable`, `danger`, plus `tinted`
  (light pill over the video) and `tinted` + `dark` (dark pill for the player's
  central controls). Hover, press (slight scale-down) and checked state are handled
  by the component — never stack a `MouseArea` inside a button.
- `AppButton`: `variant: AppButton.Primary | Secondary | Ghost | Danger`.
- `SegmentedControl`: exclusive options in a single box (`options`, `currentValue`,
  `selected` signal).
- `AppTabBar` / `AppTabButton`: compact left-aligned tabs. `AppTabButton` sets
  `width: implicitWidth`, which is what stops `TabBar` from splitting the width evenly.
- Popups over the video (`ChannelSearchPopup`, quality variants, info):
  `parent: Overlay.overlay`, position computed then **clamped to the window** (see
  `qualityPopup.reposition()` in `PlayerSlot.qml`). Their height must be derived
  from the model (row count × row height), not from the rendered content, otherwise
  the first positioning runs against a still-zero height.

## QML conventions

- `qsTr()` for displayed text.
- Per-player controls in `PlayerSlot.qml` (top bar, centered play/pause, `+` below);
  global controls in `PlayerPage.qml` (mode selector + volume).
- Controls auto-hide after 3 s of inactivity.
- **`qmllint` must stay at zero warnings** (`cmake --build build-linux --target all_qmllint`):
  - always qualify access with an id (`root.x`, `window.x`)
  - delegates: `required property var model` / `required property int index` rather
    than implicit injection, plus `pragma ComponentBehavior: Bound`
  - inside a Layout: `Layout.preferredWidth/Height`, never `width`/`height`
- `ChannelListModel` is **shared** across tabs: each page re-applies its own filter
  via `activate()` when it becomes visible again.
- The multi-token text filter has a single implementation:
  `ChannelListModel.matchesFilter()`.

## Volume

- **Binding**: `PlayerSlot → MpvObject.volume` with a `^1.1` power curve to offset
  logarithmic perception.
- **Slider** in `PlayerPage.qml`, id `volumeSlider`, 130 px wide, `stepSize: 1`,
  `value: 100` (static, no binding, to avoid locking it).
- **Mute button** to its left: `PlayerPage.toggleMute()` stores the level in `lastVolume`.
- The 4 PlayerSlots bind `globalVolume` straight to `volumeSlider.value` (no
  `PlayerPage.globalVolume` middleman).
- **Persistence**: `QtCore.Settings` in `PlayerPage.qml`, aliased on `volumeSlider.value`.

## Overlays

- **PlayerSlot**: `controlsOpacity` and `overlayActive` (default `false`).
  `showControls()` → `controlsOpacity=1, overlayActive=true`, 3 s timer restarted.
  Timer → `controlsOpacity=0, overlayActive=false` + 500 ms cooldown.
- **Top bar (PlayerPage)**: `opacity: slotN.overlayActive || ... ? 1.0 : 0.0` —
  bound directly to the 4 slots' `overlayActive`; visible as soon as one slot's
  overlay is active.
- **Hover**: `onPositionChanged` guarded by `controlsOpacity < 0.5`, otherwise the
  event spam from mouse/video re-triggers the show cycle forever.
- **Double click**: `onDoubleClicked` in each PlayerSlot's hoverArea → signal
  `doubleClickRequested()` → `PlayerPage.toggleFullscreenRequested()` → `Main.qml`
  toggles `Window.FullScreen`.

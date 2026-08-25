# OTTix

A Qt 6 / QML IPTV player with a C++ backend, playing M3U and Xtream Codes
streams through libmpv. Multiplex up to four channels at once, browse by
group, keep favorites and history, and pick up right where you left off
thanks to offline, database-first channel loading.

![CI](https://github.com/fyutins/OTTix/actions/workflows/ci.yml/badge.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

## Features

- M3U playlists (file or URL) and Xtream Codes accounts
- Multiplex playback: up to 4 simultaneous streams, several layouts
- Automatic grouping of channel variants by quality (SD, HD, FHD, 4K…),
  fully user-editable
- Favorites, watch history, instant multi-token search
- Offline-first: channels load from the local database immediately, refresh
  in the background
- Light/dark/auto theme, hardware decoding via libmpv
- Sleep inhibited on both platforms during playback

## Screenshots

_Coming soon._

## Prerequisites

- [Qt 6.10+](https://www.qt.io/download-qt-installer) (Quick, QuickControls2,
  Sql, Network, OpenGL, Concurrent)
- CMake 3.16+ and Ninja
- A C++ compiler (MinGW on Windows, GCC/Clang on Linux)
- [libmpv](https://mpv.io/) development files

### Linux (Fedora)

```bash
sudo dnf install gcc-c++ mpv-devel ninja-build
```

Qt itself is expected under `~/opt/Qt` (official Qt installer), with
CMake/Ninja under `~/opt/Qt/Tools`; adjust the `CMAKE_PREFIX_PATH` below if
your Qt install lives elsewhere.

### Windows

Install Qt (MinGW toolchain, `win64_mingw`) and CMake/Ninja through the
[Qt Online Installer](https://www.qt.io/download-qt-installer). libmpv is
not bundled with Qt: grab a `mpv-dev-x86_64` build from
[shinchiro/mpv-winbuild-cmake](https://github.com/shinchiro/mpv-winbuild-cmake/releases)
(the same source `mpv.io` distributes) and extract it somewhere CMake can
point to.

## Building

### Linux

```bash
export PATH="$HOME/opt/Qt/Tools/Ninja:$HOME/opt/Qt/Tools/CMake/bin:$PATH"
cmake -B build-linux -G Ninja \
    -DCMAKE_PREFIX_PATH="$HOME/opt/Qt/6.11.2/gcc_64" \
    -DCMAKE_BUILD_TYPE=Debug
cmake --build build-linux
./build-linux/appOTTix
```

libmpv is found through pkg-config (system package).

### Windows

```powershell
cmake -S . -B build -G Ninja `
    -DCMAKE_BUILD_TYPE=Release `
    -DMPV_INCLUDE_DIR="<mpv>\include" `
    -DMPV_LIBRARY="<mpv>\libmpv.dll.a" `
    -DMPV_RUNTIME_DLL="<mpv>\libmpv-2.dll"
cmake --build build
```

Run `cmake --install build --prefix dist` to produce a redistributable
folder (bundles the Qt runtime via `windeployqt` and libmpv).

## Packaging

Release artifacts are built by the [`Release`](.github/workflows/release.yml)
workflow, triggered by pushing a `vX.Y.Z` tag:

| Target | Format |
|---|---|
| Windows | Inno Setup installer + portable zip |
| Linux | Flatpak bundle (`org.kde.Platform//6.11` runtime) |

Manifests and installer scripts live in [`packaging/`](packaging/). See
[`AGENTS.md`](AGENTS.md) for build internals, architecture notes, and the
project's conventions.

## License

OTTix is licensed under the [MIT License](LICENSE).

## Contributing

Issues and pull requests are welcome. Before sending a PR, make sure
`cmake --build <build-dir> --target all_qmllint` reports zero warnings —
this is enforced in CI.

cmake_minimum_required(VERSION 3.16)

# Version of the published artifacts: CI derives it from the git tag
# (cmake -DOTTIX_VERSION=1.2.3). Used for the Windows version number
# (.rc resource + installer) and for the macOS bundle.
set(OTTIX_VERSION "0.1.0" CACHE STRING "Application version (x.y.z)")

project(OTTix VERSION ${OTTIX_VERSION} LANGUAGES CXX)

# Reverse-DNS identifier: names the .desktop / metainfo / icon files on Linux,
# and the app-id of the Flatpak package. Must stay identical everywhere.
set(OTTIX_APP_ID "io.github.fyutins.OTTix")

include(GNUInstallDirs)

set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_AUTOMOC ON)

# Qt Creator / clangd: correct C++ index (compile_commands.json)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

find_package(Qt6 REQUIRED COMPONENTS Quick QuickControls2 Sql Network OpenGL Concurrent)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")
find_package(PkgConfig QUIET)
if(PkgConfig_FOUND)
    pkg_check_modules(MPV IMPORTED_TARGET mpv)
endif()

if(MPV_FOUND)
    set(MPV_LIBRARY PkgConfig::MPV)
    set(MPV_INCLUDE_DIR "")
    message(STATUS "Found mpv via pkg-config")
else()
    if(WIN32)
        set(MPV_PATHS
            "C:/tools/mpv"
            "C:/Program Files/mpv"
            "C:/msys64/mingw64"
            "C:/msys64/ucrt64"
            "C:/msys64/clang64"
        )
    else()
        set(MPV_PATHS
            /usr
            /usr/local
            /opt/local
        )
    endif()

    find_path(MPV_INCLUDE_DIR
        NAMES mpv/client.h
        PATHS ${MPV_PATHS}
        PATH_SUFFIXES include include/mpv
    )
    find_library(MPV_LIBRARY
        NAMES mpv mpv.dll libmpv libmpv.dll.a mpv-2.dll
        PATHS ${MPV_PATHS}
        PATH_SUFFIXES lib lib/mpv
    )
    if(MPV_INCLUDE_DIR AND MPV_LIBRARY)
        message(STATUS "Found mpv: ${MPV_LIBRARY}")
    else()
        message(WARNING "mpv not found! Install libmpv from https://mpv.io/ or set MPV_DIR cmake variable.")
    endif()
endif()

qt_standard_project_setup(REQUIRES 6.10)

# Qt Creator / qmlls: generates .qmlls.ini at the source root so the QML editor
# finds the modules generated in the build folder.
# Must be set BEFORE qt_add_qml_module().
set(QT_QML_GENERATE_QMLLS_INI ON)

qt_add_executable(appOTTix
    src/main.cpp
    src/database/DatabaseManager.h
    src/database/DatabaseManager.cpp
    src/parser/M3UParser.h
    src/parser/M3UParser.cpp
    src/xtream/XtreamApi.h
    src/xtream/XtreamApi.cpp
    src/player/MpvObject.h
    src/player/MpvObject.cpp
    src/player/MpvRenderer.h
    src/player/MpvRenderer.cpp
    src/models/ChannelListModel.h
    src/models/ChannelListModel.cpp
    src/models/PlaylistModel.h
    src/models/PlaylistModel.cpp
    src/loader/PlaylistLoader.h
    src/loader/PlaylistLoader.cpp
    src/utils/ClipboardHelper.h
    src/utils/ClipboardHelper.cpp
    src/utils/LogUtils.h
    src/utils/LogUtils.cpp
    src/utils/Logging.h
    src/utils/Logging.cpp
    src/utils/SleepInhibitor.h
    src/utils/SleepInhibitor.cpp
    src/utils/ChannelGrouper.h
    src/utils/ChannelGrouper.cpp
    src/utils/LogoPalette.h
    src/utils/LogoPalette.cpp
)

# The generated QML registration file (appottix_qmltyperegistrations.cpp)
# includes headers by file name only, so every subfolder of src/ must be on the
# include path.
target_include_directories(appOTTix PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${CMAKE_CURRENT_SOURCE_DIR}/src/database
    ${CMAKE_CURRENT_SOURCE_DIR}/src/loader
    ${CMAKE_CURRENT_SOURCE_DIR}/src/models
    ${CMAKE_CURRENT_SOURCE_DIR}/src/parser
    ${CMAKE_CURRENT_SOURCE_DIR}/src/player
    ${CMAKE_CURRENT_SOURCE_DIR}/src/utils
    ${CMAKE_CURRENT_SOURCE_DIR}/src/xtream
)

# Design system QML singletons (style tokens + icon set).
# Must come before qt_add_qml_module().
set_source_files_properties(qml/Theme.qml qml/Mdi.qml
    PROPERTIES QT_QML_SINGLETON_TYPE TRUE
)

qt_add_qml_module(appOTTix
    URI OTTix
    VERSION 1.0
    QML_FILES
        qml/Main.qml
        qml/AdminPage.qml
        qml/AppButton.qml
        qml/AppComboBox.qml
        qml/AppMenu.qml
        qml/AppMenuItem.qml
        qml/AppScrollBar.qml
        qml/AppTabBar.qml
        qml/AppTabButton.qml
        qml/ChannelDelegate.qml
        qml/ChannelGrid.qml
        qml/ChannelListPage.qml
        qml/ChannelSearchBar.qml
        qml/ChannelSearchPopup.qml
        qml/ConfirmDialog.qml
        qml/EmptyState.qml
        qml/FavoritesPage.qml
        qml/GroupGrid.qml
        qml/GroupSearchBar.qml
        qml/GroupsPage.qml
        qml/HistoryPage.qml
        qml/IconButton.qml
        qml/Mdi.qml
        qml/MdiIcon.qml
        qml/PlayerPage.qml
        qml/PlayerSlot.qml
        qml/PlaylistDialog.qml
        qml/ScreenLayoutIcon.qml
        qml/SearchField.qml
        qml/SegmentedControl.qml
        qml/SettingsCard.qml
        qml/Theme.qml
        qml/Tip.qml
    RESOURCES
        fonts/materialdesignicons-webfont.ttf
)

# Icon and version information embedded in the Windows executable.
# The .rc is generated in the build folder (*.rc files are gitignored).
if(WIN32)
    configure_file(packaging/windows/app.rc.in
                   ${CMAKE_CURRENT_BINARY_DIR}/app.rc @ONLY)
    target_sources(appOTTix PRIVATE ${CMAKE_CURRENT_BINARY_DIR}/app.rc)
endif()

set_target_properties(appOTTix PROPERTIES
    MACOSX_BUNDLE_GUI_IDENTIFIER io.github.fyutins.OTTix
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appOTTix
    PRIVATE Qt6::Quick Qt6::QuickControls2 Qt6::Sql Qt6::Network Qt6::OpenGL Qt6::Concurrent
)

# Sleep inhibition on Linux: org.freedesktop.ScreenSaver over D-Bus.
if(UNIX AND NOT APPLE)
    find_package(Qt6 QUIET COMPONENTS DBus)
    if(Qt6DBus_FOUND)
        target_link_libraries(appOTTix PRIVATE Qt6::DBus)
        target_compile_definitions(appOTTix PRIVATE HAS_DBUS)
        message(STATUS "D-Bus screensaver inhibition enabled")
    else()
        message(STATUS "Qt6 DBus not found - screensaver inhibition disabled")
    endif()
endif()

if(MPV_INCLUDE_DIR)
    target_include_directories(appOTTix PRIVATE ${MPV_INCLUDE_DIR})
endif()
if(MPV_LIBRARY)
    target_link_libraries(appOTTix PRIVATE ${MPV_LIBRARY})
    target_compile_definitions(appOTTix PRIVATE HAS_MPV)
    message(STATUS "MPV support enabled")
else()
    target_compile_definitions(appOTTix PRIVATE HAS_MPV=0)
    message(STATUS "MPV support disabled - MpvObject will be a stub")
endif()

# --- Installation / deployment --------------------------------------------
#
# Linux  : "cmake --install" lays down the binary, the .desktop, the icon and the
#          AppStream metainfo; Qt comes from the KDE runtime (Flatpak), nothing
#          is bundled.
# Windows: everything is flattened next to the executable, then windeployqt
#          completes the tree (Qt DLLs, plugins, qml/). The result is directly
#          the source folder for the Inno Setup installer.

if(WIN32)
    install(TARGETS appOTTix RUNTIME DESTINATION .)

    get_target_property(_qt_qmake_executable Qt6::qmake IMPORTED_LOCATION)
    get_filename_component(_qt_bin_dir "${_qt_qmake_executable}" DIRECTORY)
    find_program(WINDEPLOYQT_EXECUTABLE windeployqt HINTS "${_qt_bin_dir}")

    if(NOT WINDEPLOYQT_EXECUTABLE)
        message(FATAL_ERROR "windeployqt not found in ${_qt_bin_dir}")
    endif()

    # --no-opengl-sw: software OpenGL rendering (opengl32sw.dll) freezes the
    # window when it is moved during mpv playback, so force the system OpenGL.
    install(CODE "
        message(STATUS \"windeployqt: \${CMAKE_INSTALL_PREFIX}\")
        execute_process(
            COMMAND \"${WINDEPLOYQT_EXECUTABLE}\"
                    --no-opengl-sw
                    --compiler-runtime
                    --qmldir \"${CMAKE_CURRENT_SOURCE_DIR}\"
                    \"\${CMAKE_INSTALL_PREFIX}/appOTTix.exe\"
            RESULT_VARIABLE _windeployqt_result
        )
        if(NOT _windeployqt_result EQUAL 0)
            message(FATAL_ERROR \"windeployqt failed (\${_windeployqt_result})\")
        endif()
    ")

    # libmpv is not deployed by windeployqt: CI passes the path of the DLL
    # extracted from the mpv-dev package (-DMPV_RUNTIME_DLL=...).
    set(MPV_RUNTIME_DLL "" CACHE FILEPATH "libmpv-2.dll to include in the Windows package")
    if(MPV_RUNTIME_DLL)
        install(FILES "${MPV_RUNTIME_DLL}" DESTINATION .)
    else()
        message(WARNING "MPV_RUNTIME_DLL not set: libmpv-2.dll will not be installed")
    endif()

elseif(APPLE)
    install(TARGETS appOTTix
        BUNDLE DESTINATION .
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    )

else()
    install(TARGETS appOTTix RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})

    install(FILES packaging/linux/${OTTIX_APP_ID}.desktop
            DESTINATION ${CMAKE_INSTALL_DATADIR}/applications)
    install(FILES packaging/linux/${OTTIX_APP_ID}.metainfo.xml
            DESTINATION ${CMAKE_INSTALL_DATADIR}/metainfo)
    install(FILES packaging/icons/${OTTIX_APP_ID}.svg
            DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/scalable/apps)
endif()

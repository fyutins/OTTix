cmake_minimum_required(VERSION 3.16)

# Version des artefacts publies : la CI la derive du tag git
# (cmake -DOTTIX_VERSION=1.2.3). Sert au numero de version Windows
# (ressource .rc + installateur) et au bundle macOS.
set(OTTIX_VERSION "0.1.0" CACHE STRING "Version de l'application (x.y.z)")

project(OTTix VERSION ${OTTIX_VERSION} LANGUAGES CXX)

# Identifiant reverse-DNS : nom des fichiers .desktop / metainfo / icone sous
# Linux, et app-id du paquet Flatpak. Doit rester identique partout.
set(OTTIX_APP_ID "io.github.fyutins.OTTix")

include(GNUInstallDirs)

set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_AUTOMOC ON)

# Qt Creator / clangd : index C++ correct (compile_commands.json)
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

# Qt Creator / qmlls : genere .qmlls.ini a la racine des sources pour que
# l'editeur QML retrouve les modules generes dans le dossier de build.
# Doit etre positionne AVANT qt_add_qml_module().
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

# Le fichier de registration QML genere (appottix_qmltyperegistrations.cpp)
# inclut les en-tetes par leur seul nom de fichier : chaque sous-dossier de src/
# doit donc etre dans le include path.
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

# Singletons QML du design system (jetons de style + jeu d'icones).
# Doit preceder qt_add_qml_module().
set_source_files_properties(Theme.qml Mdi.qml
    PROPERTIES QT_QML_SINGLETON_TYPE TRUE
)

qt_add_qml_module(appOTTix
    URI OTTix
    VERSION 1.0
    QML_FILES
        Main.qml
        AdminPage.qml
        AppButton.qml
        AppComboBox.qml
        AppMenu.qml
        AppMenuItem.qml
        AppScrollBar.qml
        AppTabBar.qml
        AppTabButton.qml
        ChannelDelegate.qml
        ChannelGrid.qml
        ChannelListPage.qml
        ChannelSearchBar.qml
        ChannelSearchPopup.qml
        ConfirmDialog.qml
        EmptyState.qml
        FavoritesPage.qml
        GroupGrid.qml
        GroupSearchBar.qml
        GroupsPage.qml
        HistoryPage.qml
        IconButton.qml
        Mdi.qml
        MdiIcon.qml
        PlayerPage.qml
        PlayerSlot.qml
        PlaylistDialog.qml
        ScreenLayoutIcon.qml
        SearchField.qml
        SegmentedControl.qml
        SettingsCard.qml
        Theme.qml
        Tip.qml
    RESOURCES
        fonts/materialdesignicons-webfont.ttf
)

# Icone et informations de version embarquees dans l'executable Windows.
# Le .rc est genere dans le dossier de build (les *.rc sont ignores par git).
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

# Inhibition de la veille sous Linux : org.freedesktop.ScreenSaver via D-Bus.
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

# --- Installation / deploiement ------------------------------------------
#
# Linux   : "cmake --install" pose le binaire, le .desktop, l'icone et le
#           metainfo AppStream ; Qt vient du runtime KDE (Flatpak), rien n'est
#           bundle.
# Windows : tout est mis a plat a cote de l'executable, puis windeployqt
#           complete l'arborescence (DLL Qt, plugins, qml/). Le resultat est
#           directement le dossier source de l'installateur Inno Setup.

if(WIN32)
    install(TARGETS appOTTix RUNTIME DESTINATION .)

    get_target_property(_qt_qmake_executable Qt6::qmake IMPORTED_LOCATION)
    get_filename_component(_qt_bin_dir "${_qt_qmake_executable}" DIRECTORY)
    find_program(WINDEPLOYQT_EXECUTABLE windeployqt HINTS "${_qt_bin_dir}")

    if(NOT WINDEPLOYQT_EXECUTABLE)
        message(FATAL_ERROR "windeployqt introuvable dans ${_qt_bin_dir}")
    endif()

    # --no-opengl-sw : le rendu OpenGL logiciel (opengl32sw.dll) fige la
    # fenetre quand on la deplace pendant une lecture mpv. On force l'OpenGL
    # du systeme.
    install(CODE "
        message(STATUS \"windeployqt : \${CMAKE_INSTALL_PREFIX}\")
        execute_process(
            COMMAND \"${WINDEPLOYQT_EXECUTABLE}\"
                    --no-opengl-sw
                    --compiler-runtime
                    --qmldir \"${CMAKE_CURRENT_SOURCE_DIR}\"
                    \"\${CMAKE_INSTALL_PREFIX}/appOTTix.exe\"
            RESULT_VARIABLE _windeployqt_result
        )
        if(NOT _windeployqt_result EQUAL 0)
            message(FATAL_ERROR \"windeployqt a echoue (\${_windeployqt_result})\")
        endif()
    ")

    # libmpv n'est pas deployee par windeployqt : la CI passe le chemin de la
    # DLL extraite du paquet mpv-dev (-DMPV_RUNTIME_DLL=...).
    set(MPV_RUNTIME_DLL "" CACHE FILEPATH "libmpv-2.dll a inclure dans le paquet Windows")
    if(MPV_RUNTIME_DLL)
        install(FILES "${MPV_RUNTIME_DLL}" DESTINATION .)
    else()
        message(WARNING "MPV_RUNTIME_DLL non defini : libmpv-2.dll ne sera pas installee")
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

cmake_minimum_required(VERSION 3.16)

project(IptvPlayer VERSION 0.1 LANGUAGES CXX)

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

qt_add_executable(appIptvPlayer
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
)

# Le fichier de registration QML genere (appiptvplayer_qmltyperegistrations.cpp)
# inclut les en-tetes par leur seul nom de fichier : chaque sous-dossier de src/
# doit donc etre dans le include path.
target_include_directories(appIptvPlayer PRIVATE
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

qt_add_qml_module(appIptvPlayer
    URI IptvPlayer
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

set_target_properties(appIptvPlayer PROPERTIES
    MACOSX_BUNDLE_GUI_IDENTIFIER com.iptvplayer.app
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appIptvPlayer
    PRIVATE Qt6::Quick Qt6::QuickControls2 Qt6::Sql Qt6::Network Qt6::OpenGL Qt6::Concurrent
)

# Inhibition de la veille sous Linux : org.freedesktop.ScreenSaver via D-Bus.
if(UNIX AND NOT APPLE)
    find_package(Qt6 QUIET COMPONENTS DBus)
    if(Qt6DBus_FOUND)
        target_link_libraries(appIptvPlayer PRIVATE Qt6::DBus)
        target_compile_definitions(appIptvPlayer PRIVATE HAS_DBUS)
        message(STATUS "D-Bus screensaver inhibition enabled")
    else()
        message(STATUS "Qt6 DBus not found - screensaver inhibition disabled")
    endif()
endif()

if(MPV_INCLUDE_DIR)
    target_include_directories(appIptvPlayer PRIVATE ${MPV_INCLUDE_DIR})
endif()
if(MPV_LIBRARY)
    target_link_libraries(appIptvPlayer PRIVATE ${MPV_LIBRARY})
    target_compile_definitions(appIptvPlayer PRIVATE HAS_MPV)
    message(STATUS "MPV support enabled")
else()
    target_compile_definitions(appIptvPlayer PRIVATE HAS_MPV=0)
    message(STATUS "MPV support disabled - MpvObject will be a stub")
endif()

install(TARGETS appIptvPlayer
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

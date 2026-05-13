cmake_minimum_required(VERSION 3.16)

project(IptvPlayer VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Quick QuickControls2 Sql Network OpenGL)

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
)

target_include_directories(appIptvPlayer PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)

qt_add_qml_module(appIptvPlayer
    URI IptvPlayer
    VERSION 1.0
    QML_FILES
        Main.qml
        ChannelListPage.qml
        FavoritesPage.qml
        PlayerPage.qml
        PlaylistDialog.qml
        SettingsPage.qml
)

set_target_properties(appIptvPlayer PROPERTIES
    MACOSX_BUNDLE_GUI_IDENTIFIER com.iptvplayer.app
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appIptvPlayer
    PRIVATE Qt6::Quick Qt6::QuickControls2 Qt6::Sql Qt6::Network Qt6::OpenGL
)

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

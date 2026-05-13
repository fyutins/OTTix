#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QSGRendererInterface>
#include <QDir>

#include "database/DatabaseManager.h"
#include "models/PlaylistModel.h"
#include "models/ChannelListModel.h"
#include "loader/PlaylistLoader.h"
#include "player/MpvObject.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setOrganizationName("IptvPlayer");
    app.setApplicationName("IptvPlayer");

    // Force OpenGL backend — QQuickFramebufferObject requires it
    qputenv("QSG_RHI_BACKEND", "opengl");
    qDebug() << "[MAIN] QSG_RHI_BACKEND=opengl set, current:" << qEnvironmentVariable("QSG_RHI_BACKEND");

    QQuickStyle::setStyle("Basic");

    qDebug() << "[MAIN] Starting IptvPlayer, Qt version:" << qVersion();

    // Initialize database
    if (!DatabaseManager::instance().initialize()) {
        qCritical("[MAIN] Failed to initialize database");
        return -1;
    }
    qDebug() << "[MAIN] Database initialized successfully";

    qmlRegisterType<MpvObject>("IptvPlayer.Player", 1, 0, "MpvObject");
    qmlRegisterType<PlaylistLoader>("IptvPlayer.Loader", 1, 0, "PlaylistLoader");

    qmlRegisterSingletonType<PlaylistModel>("IptvPlayer.Models", 1, 0, "PlaylistModel",
        [](QQmlEngine *, QJSEngine *) -> QObject * {
            return new PlaylistModel();
        });

    qmlRegisterSingletonType<ChannelListModel>("IptvPlayer.Models", 1, 0, "ChannelListModel",
        [](QQmlEngine *, QJSEngine *) -> QObject * {
            return new ChannelListModel();
        });

    // Register DatabaseManager as a singleton for QML use
    qmlRegisterSingletonType<DatabaseManager>("IptvPlayer.Database", 1, 0, "DatabaseManager",
        [](QQmlEngine *, QJSEngine *) -> QObject * {
            return &DatabaseManager::instance();
        });

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    engine.loadFromModule("IptvPlayer", "Main");

    return QCoreApplication::exec();
}

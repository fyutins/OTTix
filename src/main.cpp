#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QSGRendererInterface>
#include <QDir>
#include <QDateTime>
#include <QFile>
#include <QTextStream>

#ifdef Q_OS_UNIX
#include <locale.h>
#endif

#include "database/DatabaseManager.h"
#include "models/PlaylistModel.h"
#include "models/ChannelListModel.h"
#include "loader/PlaylistLoader.h"
#include "player/MpvObject.h"
#include "utils/ClipboardHelper.h"
#include "utils/SleepInhibitor.h"

#ifdef Q_OS_WIN
#include <windows.h>
#include <dbghelp.h>
#include <signal.h>

// -- Crash handler (Windows SEH) --

static QString crashLogPath()
{
    return QDir::toNativeSeparators(
        QCoreApplication::applicationDirPath() + "/crash.log");
}

static QString dumpPath()
{
    return QDir::toNativeSeparators(
        QCoreApplication::applicationDirPath() + "/crash.dmp");
}

static void logCrash(const char *context, unsigned long code, void *addr,
                     void **stack, USHORT frames)
{
    QString path = crashLogPath();
    QFile f(path);
    if (!f.open(QIODevice::Append | QIODevice::Text))
        return;
    QTextStream out(&f);

    QString ts = QDateTime::currentDateTime().toString("yyyy-MM-dd hh:mm:ss.zzz");
    out << "\n=== " << ts << " [" << context << "] ===\n";
    out << "Exception code: 0x" << QString::number(code, 16) << "\n";
    out << "Address: " << addr << "\n";
    out << "Stack (" << frames << " frames):\n";
    for (USHORT i = 0; i < frames; i++)
        out << "  #" << i << " " << stack[i] << "\n";
    out << "========================\n";
    f.close();

    qCritical().noquote()
        << "=== CRASH [" << context << "] ==="
        << "code=0x" << QString::number(code, 16)
        << "addr=" << addr;
    USHORT maxFrames = qMin<USHORT>(frames, 32);
    for (USHORT i = 0; i < maxFrames; i++)
        qCritical().noquote() << QString("  #%1 %2").arg(i).arg(
            QString::number(reinterpret_cast<quintptr>(stack[i]), 16));
}

static void writeMinidump(EXCEPTION_POINTERS *ep)
{
    HMODULE h = LoadLibraryW(L"dbghelp.dll");
    if (!h) return;

    typedef BOOL (WINAPI *MiniDumpWriteDumpFunc)(
        HANDLE, DWORD, HANDLE, MINIDUMP_TYPE,
        PMINIDUMP_EXCEPTION_INFORMATION,
        PMINIDUMP_USER_STREAM_INFORMATION,
        PMINIDUMP_CALLBACK_INFORMATION);

    auto func = (MiniDumpWriteDumpFunc)GetProcAddress(h, "MiniDumpWriteDump");
    if (!func) { FreeLibrary(h); return; }

    QString path = dumpPath();
    HANDLE file = CreateFileW(reinterpret_cast<const wchar_t *>(path.utf16()),
                              GENERIC_WRITE, 0, NULL,
                              CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    if (file == INVALID_HANDLE_VALUE) { FreeLibrary(h); return; }

    MINIDUMP_EXCEPTION_INFORMATION exInfo;
    exInfo.ThreadId = GetCurrentThreadId();
    exInfo.ExceptionPointers = ep;
    exInfo.ClientPointers = FALSE;

    func(GetCurrentProcess(), GetCurrentProcessId(), file,
         MiniDumpNormal, &exInfo, NULL, NULL);
    CloseHandle(file);
    FreeLibrary(h);
    qInfo() << "Minidump written to" << path;
}

static LONG WINAPI sehHandler(EXCEPTION_POINTERS *ep)
{
    void *stack[64];
    USHORT frames = CaptureStackBackTrace(0, 64, stack, NULL);
    logCrash("SEH", ep->ExceptionRecord->ExceptionCode,
             ep->ExceptionRecord->ExceptionAddress, stack, frames);
    writeMinidump(ep);
    return EXCEPTION_CONTINUE_SEARCH;
}

static void signalHandler(int sig)
{
    void *stack[64];
    USHORT frames = CaptureStackBackTrace(1, 64, stack, NULL);
    logCrash("SIGNAL", static_cast<unsigned long>(sig), nullptr, stack, frames);

    _exit(sig);
}

static void installCrashHandlers()
{
    SetUnhandledExceptionFilter(sehHandler);
    signal(SIGSEGV, signalHandler);
    signal(SIGABRT, signalHandler);
    signal(SIGFPE, signalHandler);
    signal(SIGILL, signalHandler);
}

// -- Qt message handler --

static QtMessageHandler originalMsgHandler = nullptr;
static QFile *msgLogFile = nullptr;

static void msgHandler(QtMsgType type, const QMessageLogContext &ctx, const QString &msg)
{
    if (msgLogFile && msgLogFile->isOpen()) {
        QTextStream out(msgLogFile);
        QString ts = QDateTime::currentDateTime().toString("hh:mm:ss.zzz");
        QString line = ts;
        switch (type) {
        case QtDebugMsg:    line += " [D] "; break;
        case QtWarningMsg:  line += " [W] "; break;
        case QtCriticalMsg: line += " [C] "; break;
        case QtFatalMsg:    line += " [F] "; break;
        case QtInfoMsg:     line += " [I] "; break;
        }
        if (ctx.file && ctx.line > 0)
            line += QString("%1:%2 ").arg(ctx.file).arg(ctx.line);
        line += msg + "\n";
        out << line;
        out.flush();
    }

    if (type == QtFatalMsg) {
        void *stack[64];
        USHORT frames = CaptureStackBackTrace(1, 64, stack, NULL);
        logCrash("QFATAL", 0, nullptr, stack, frames);
    }

    if (originalMsgHandler)
        originalMsgHandler(type, ctx, msg);
}

static void installMsgHandler()
{
    QString logPath = QDir::toNativeSeparators(
        QCoreApplication::applicationDirPath() + "/iptvplayer.log");
    msgLogFile = new QFile(logPath);
    if (msgLogFile->open(QIODevice::Append | QIODevice::Text)) {
        QTextStream out(msgLogFile);
        out << "\n=== Session started "
            << QDateTime::currentDateTime().toString(Qt::ISODate) << " ===\n";
        out.flush();
    }
    originalMsgHandler = qInstallMessageHandler(msgHandler);
    qInfo() << "[MAIN] Logging to" << logPath;
}

#endif // Q_OS_WIN

int main(int argc, char *argv[])
{
#ifdef Q_OS_WIN
    installCrashHandlers();
#endif

    QGuiApplication app(argc, argv);
    app.setOrganizationName("IptvPlayer");
    app.setApplicationName("IptvPlayer");

#ifdef Q_OS_UNIX
    // libmpv requires LC_NUMERIC=C (breaks with e.g. fr_FR.UTF-8)
    setlocale(LC_NUMERIC, "C");
#endif

#ifdef Q_OS_WIN
    installMsgHandler();
#endif

    // Force OpenGL backend — QQuickFramebufferObject requires it
    qputenv("QSG_RHI_BACKEND", "opengl");
    qputenv("QSG_INFO", "1");
    qDebug() << "[MAIN] QSG_RHI_BACKEND=opengl set, current:" << qEnvironmentVariable("QSG_RHI_BACKEND");

    QQuickStyle::setStyle("Basic");

    qDebug() << "[MAIN] Starting IptvPlayer, Qt version:" << qVersion();

    // Initialize database
    if (!DatabaseManager::instance().initialize()) {
        qCritical("[MAIN] Failed to initialize database");
        return -1;
    }
    qDebug() << "[MAIN] Database initialized successfully";

    // Les types QML sont enregistres de maniere declarative (QML_ELEMENT /
    // QML_SINGLETON dans les en-tetes) et exposes par le module QML "IptvPlayer".

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

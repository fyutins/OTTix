#include "SleepInhibitor.h"
#include "Logging.h"

#ifdef Q_OS_WIN
#include <windows.h>
#endif

#ifdef HAS_DBUS
#include <QDBusConnection>
#include <QDBusInterface>
#include <QDBusReply>
#endif

#include <QGuiApplication>

SleepInhibitor::SleepInhibitor(QObject *parent)
    : QObject(parent)
{
    // Windows exige un rappel periodique de SetThreadExecutionState.
    m_refreshTimer.setInterval(30000);
    connect(&m_refreshTimer, &QTimer::timeout, this, &SleepInhibitor::applyState);
}

SleepInhibitor::~SleepInhibitor()
{
    disable();
}

void SleepInhibitor::applyState()
{
#ifdef Q_OS_WIN
    DWORD flags = ES_CONTINUOUS | ES_SYSTEM_REQUIRED | ES_DISPLAY_REQUIRED;
    if (SetThreadExecutionState(flags) == 0)
        qCWarning(logMpv) << "[SLEEP] SetThreadExecutionState failed";
#endif
}

void SleepInhibitor::enable()
{
    if (m_inhibited)
        return;

#ifdef Q_OS_WIN
    qCDebug(logMpv) << "[SLEEP] Inhibiting system sleep";
    applyState();
    m_refreshTimer.start();
    m_inhibited = true;
#elif defined(HAS_DBUS)
    QDBusInterface screenSaver(QStringLiteral("org.freedesktop.ScreenSaver"),
                               QStringLiteral("/org/freedesktop/ScreenSaver"),
                               QStringLiteral("org.freedesktop.ScreenSaver"),
                               QDBusConnection::sessionBus());
    if (!screenSaver.isValid()) {
        qCWarning(logMpv) << "[SLEEP] org.freedesktop.ScreenSaver unavailable:"
                          << screenSaver.lastError().message();
        return;
    }

    QDBusReply<quint32> reply = screenSaver.call(QStringLiteral("Inhibit"),
                                                 QGuiApplication::applicationName(),
                                                 QStringLiteral("Playing video"));
    if (!reply.isValid()) {
        qCWarning(logMpv) << "[SLEEP] Inhibit failed:" << reply.error().message();
        return;
    }

    m_cookie = reply.value();
    m_inhibited = true;
    qCDebug(logMpv) << "[SLEEP] Screensaver inhibited, cookie" << m_cookie;
#else
    qCDebug(logMpv) << "[SLEEP] Inhibiting sleep (stub - plateforme non supportee)";
#endif
}

void SleepInhibitor::disable()
{
    if (!m_inhibited)
        return;

#ifdef Q_OS_WIN
    qCDebug(logMpv) << "[SLEEP] Allowing system sleep";
    m_refreshTimer.stop();
    if (SetThreadExecutionState(ES_CONTINUOUS) == 0)
        qCWarning(logMpv) << "[SLEEP] SetThreadExecutionState(ES_CONTINUOUS) failed";
#elif defined(HAS_DBUS)
    QDBusInterface screenSaver(QStringLiteral("org.freedesktop.ScreenSaver"),
                               QStringLiteral("/org/freedesktop/ScreenSaver"),
                               QStringLiteral("org.freedesktop.ScreenSaver"),
                               QDBusConnection::sessionBus());
    if (screenSaver.isValid())
        screenSaver.call(QStringLiteral("UnInhibit"), m_cookie);
    m_cookie = 0;
    qCDebug(logMpv) << "[SLEEP] Screensaver released";
#endif

    m_inhibited = false;
}

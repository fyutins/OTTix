#include "SleepInhibitor.h"

#ifdef Q_OS_WIN
#include <windows.h>
#endif

#include <QDebug>

SleepInhibitor::SleepInhibitor(QObject *parent)
    : QObject(parent)
{
    m_refreshTimer.setInterval(30000);
    connect(&m_refreshTimer, &QTimer::timeout, this, &SleepInhibitor::applyState);
}

SleepInhibitor::~SleepInhibitor()
{
#ifdef Q_OS_WIN
    if (m_inhibited) {
        SetThreadExecutionState(ES_CONTINUOUS);
    }
#endif
}

void SleepInhibitor::applyState()
{
#ifdef Q_OS_WIN
    DWORD flags = ES_CONTINUOUS | ES_SYSTEM_REQUIRED | ES_DISPLAY_REQUIRED;
    DWORD result = SetThreadExecutionState(flags);
    if (result == 0)
        qWarning() << "[SLEEP] SetThreadExecutionState failed with ES_CONTINUOUS | ES_SYSTEM_REQUIRED | ES_DISPLAY_REQUIRED";
#endif
}

void SleepInhibitor::enable()
{
#ifdef Q_OS_WIN
    if (!m_inhibited) {
        qDebug() << "[SLEEP] Inhibiting system sleep";
        applyState();
        m_inhibited = true;
        m_refreshTimer.start();
    }
#else
    qDebug() << "[SLEEP] Inhibiting sleep (stub - non-Windows)";
#endif
}

void SleepInhibitor::disable()
{
#ifdef Q_OS_WIN
    if (m_inhibited) {
        qDebug() << "[SLEEP] Allowing system sleep";
        m_refreshTimer.stop();
        DWORD result = SetThreadExecutionState(ES_CONTINUOUS);
        if (result == 0)
            qWarning() << "[SLEEP] SetThreadExecutionState(ES_CONTINUOUS) failed";
        m_inhibited = false;
    }
#else
    qDebug() << "[SLEEP] Allowing sleep (stub - non-Windows)";
#endif
}

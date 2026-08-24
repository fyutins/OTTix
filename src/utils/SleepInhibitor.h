#pragma once

#include <QObject>
#include <QtQml/qqmlregistration.h>
#include <QTimer>

class SleepInhibitor : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    explicit SleepInhibitor(QObject *parent = nullptr);
    ~SleepInhibitor() override;

    Q_INVOKABLE void enable();
    Q_INVOKABLE void disable();

private:
    void applyState();

    QTimer m_refreshTimer;
    bool m_inhibited = false;
};

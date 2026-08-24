#pragma once

#include <QObject>
#include <QtQml/qqmlregistration.h>
#include <QClipboard>
#include <QGuiApplication>

class ClipboardHelper : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    explicit ClipboardHelper(QObject *parent = nullptr);

    Q_INVOKABLE void copyText(const QString &text);
};

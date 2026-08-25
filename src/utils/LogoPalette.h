#pragma once

#include <QObject>
#include <QtQml/qqmlregistration.h>
#include <QColor>
#include <QHash>
#include <QQueue>
#include <QSet>
#include <QString>

class QImage;
class QNetworkAccessManager;

// Channel logo backdrop, derived from the dominant color of the logo itself.
//
// A single flat backdrop makes any logo painted in a nearby hue unreadable, so
// the image is analyzed and a backdrop that contrasts with it is returned (dark
// for a light logo, light for a dark one), tinted with the same color so the
// tile stays coherent.
//
// Resolution is asynchronous: `backdrop()` returns an invalid color while the
// answer is unknown (the caller then keeps the theme default) and
// `backdropResolved` is emitted as soon as the analysis completes. Results are
// memoized in RAM and persisted in the `cache` table: on the next start, no logo
// is re-downloaded just for its backdrop.
class LogoPalette : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    explicit LogoPalette(QObject *parent = nullptr);

    // Backdrop to paint behind `source`, or an invalid color when it is not
    // (yet) known. Kicks off the analysis on the first call.
    Q_INVOKABLE QColor backdrop(const QString &source);

    // Pure, stateless analysis: exposed for tests and reuse.
    static QColor backdropOf(const QImage &image);

signals:
    void backdropResolved(const QString &source, const QColor &color);

private:
    void pumpQueue();
    void fetch(const QString &source);
    void resolve(const QString &source, const QColor &color, bool persist);

    QNetworkAccessManager *m_nam = nullptr;
    QHash<QString, QColor> m_backdrops;  // invalid color = theme default
    QSet<QString> m_requested;
    QQueue<QString> m_queue;
    int m_inFlight = 0;
};

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

// Fond des logos de chaines, derive de la couleur dominante du logo lui-meme.
//
// Un fond uni unique rend illisible tout logo peint dans une teinte proche :
// on analyse donc l'image et on renvoie un fond qui contraste avec elle
// (sombre pour un logo clair, clair pour un logo sombre), teinte de la meme
// couleur pour que la tuile reste coherente.
//
// La resolution est asynchrone : `backdrop()` renvoie une couleur invalide
// tant qu'elle n'est pas connue (l'appelant garde alors le fond par defaut du
// theme) et `backdropResolved` est emis des que l'analyse aboutit. Les
// resultats sont memorises en RAM et persistes dans la table `cache` : au
// demarrage suivant, aucun logo n'est retelecharge pour son fond.
class LogoPalette : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    explicit LogoPalette(QObject *parent = nullptr);

    // Fond a appliquer derriere `source`, ou une couleur invalide si elle
    // n'est pas (encore) connue. Declenche l'analyse au premier appel.
    Q_INVOKABLE QColor backdrop(const QString &source);

    // Analyse pure, sans etat : exposee pour les tests et la reutilisation.
    static QColor backdropOf(const QImage &image);

signals:
    void backdropResolved(const QString &source, const QColor &color);

private:
    void pumpQueue();
    void fetch(const QString &source);
    void resolve(const QString &source, const QColor &color, bool persist);

    QNetworkAccessManager *m_nam = nullptr;
    QHash<QString, QColor> m_backdrops;  // couleur invalide = fond par defaut
    QSet<QString> m_requested;
    QQueue<QString> m_queue;
    int m_inFlight = 0;
};

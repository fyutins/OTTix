#pragma once

#include <QQuickFramebufferObject>
#include <functional>

#if HAS_MPV
#include <mpv/client.h>
#include <mpv/render_gl.h>
#include <QMutex>
#include <QQueue>
#endif

class MpvRenderer;

class MpvObject : public QQuickFramebufferObject
{
    Q_OBJECT
    Q_PROPERTY(QString source READ source WRITE setSource NOTIFY sourceChanged)
    Q_PROPERTY(bool playing READ isPlaying NOTIFY playingChanged)
    Q_PROPERTY(double position READ position NOTIFY positionChanged)
    Q_PROPERTY(double duration READ duration NOTIFY durationChanged)
    Q_PROPERTY(int volume READ volume WRITE setVolume NOTIFY volumeChanged)
    Q_PROPERTY(bool muted READ isMuted WRITE setMuted NOTIFY mutedChanged)
    Q_PROPERTY(double playbackSpeed READ playbackSpeed WRITE setPlaybackSpeed NOTIFY playbackSpeedChanged)

public:
    explicit MpvObject(QQuickItem *parent = nullptr);
    ~MpvObject() override;

    QQuickFramebufferObject::Renderer *createRenderer() const override;

    QString source() const { return m_source; }
    void setSource(const QString &source);

    bool isPlaying() const { return m_playing; }
    double position() const { return m_position; }
    double duration() const { return m_duration; }
    int volume() const { return m_volume; }
    bool isMuted() const { return m_muted; }
    double playbackSpeed() const { return m_speed; }

    Q_INVOKABLE void play();
    Q_INVOKABLE void pause();
    Q_INVOKABLE void stop();
    Q_INVOKABLE void seek(double position);
    Q_INVOKABLE void setVolume(int volume);
    Q_INVOKABLE void setMuted(bool muted);
    Q_INVOKABLE void setPlaybackSpeed(double speed);
    Q_INVOKABLE void loadFile(const QString &path);
    Q_INVOKABLE void loadUrl(const QString &url);

    void enqueueCommand(std::function<void(mpv_handle *)> cmd);
    bool dequeueCommand(std::function<void(mpv_handle *)> &cmd);

signals:
    void sourceChanged();
    void playingChanged();
    void positionChanged(double position);
    void durationChanged(double duration);
    void volumeChanged(int volume);
    void mutedChanged(bool muted);
    void playbackSpeedChanged(double speed);
    void errorOccurred(const QString &error);
    void endReached();
    void ready();

private:
    QString m_source;
    bool m_playing = false;
    double m_position = 0.0;
    double m_duration = 0.0;
    int m_volume = 100;
    bool m_muted = false;
    double m_speed = 1.0;

#if HAS_MPV
    mpv_handle *m_mpv = nullptr;
    mutable QMutex m_mutex;
    QQueue<std::function<void(mpv_handle *)>> m_commandQueue;

    static void onMpvWakeup(void *ctx);
    void onMpvEvent(mpv_event *event);
    Q_INVOKABLE void handleMpvEvents();
    void updateProperties();
    friend class MpvRenderer;
#endif
};

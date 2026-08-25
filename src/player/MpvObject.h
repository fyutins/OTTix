#pragma once

#include <QQuickFramebufferObject>
#include <QtQml/qqmlregistration.h>
#include <functional>

#if HAS_MPV
#include <mpv/client.h>
#include <mpv/render_gl.h>
#include <QMutex>
#include <QQueue>
#include <memory>
#endif

class MpvRenderer;

class MpvObject : public QQuickFramebufferObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QString source READ source WRITE setSource NOTIFY sourceChanged)
    Q_PROPERTY(bool playing READ isPlaying NOTIFY playingChanged)
    Q_PROPERTY(double position READ position NOTIFY positionChanged)
    Q_PROPERTY(double duration READ duration NOTIFY durationChanged)
    Q_PROPERTY(double sessionPosition READ sessionPosition NOTIFY sessionPositionChanged)
    Q_PROPERTY(double sessionDuration READ sessionDuration NOTIFY sessionDurationChanged)
    Q_PROPERTY(int volume READ volume WRITE setVolume NOTIFY volumeChanged)
    Q_PROPERTY(bool muted READ isMuted WRITE setMuted NOTIFY mutedChanged)
    Q_PROPERTY(double playbackSpeed READ playbackSpeed WRITE setPlaybackSpeed NOTIFY playbackSpeedChanged)
    Q_PROPERTY(bool loading READ isLoading NOTIFY loadingChanged)
    Q_PROPERTY(QVariantList audioTracks READ audioTracks NOTIFY tracksChanged)
    Q_PROPERTY(QVariantList subtitleTracks READ subtitleTracks NOTIFY tracksChanged)
    Q_PROPERTY(QVariantList videoTracks READ videoTracks NOTIFY tracksChanged)
    Q_PROPERTY(QString hwdec READ hwdec WRITE setHwdec NOTIFY hwdecChanged)

public:
    explicit MpvObject(QQuickItem *parent = nullptr);
    ~MpvObject() override;

    QQuickFramebufferObject::Renderer *createRenderer() const override;

    QString source() const { return m_source; }
    void setSource(const QString &source);

    bool isPlaying() const { return m_playing; }
    bool isLoading() const { return m_loading; }
    QVariantList audioTracks() const { return m_audioTracks; }
    QVariantList subtitleTracks() const { return m_subtitleTracks; }
    QVariantList videoTracks() const { return m_videoTracks; }
    QString hwdec() const { return m_hwdec; }

    double position() const { return m_position; }
    double duration() const { return m_duration; }
    double sessionPosition() const { return m_sessionPosition; }
    double sessionDuration() const { return m_sessionDuration; }
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
    Q_INVOKABLE void clearVideo();
    Q_INVOKABLE void reload();
    Q_INVOKABLE void setAudioTrack(int trackId);
    Q_INVOKABLE void setSubtitleTrack(int trackId);
    Q_INVOKABLE void setVideoTrack(int trackId);
    Q_INVOKABLE void setHwdec(const QString &hwdec);

#if HAS_MPV
    // Command queue replayed by MpvRenderer on the render thread.
    void enqueueCommand(std::function<void(mpv_handle *)> cmd);
    bool dequeueCommand(std::function<void(mpv_handle *)> &cmd);

    // The renderer shares ownership of the handle: libmpv requires the
    // mpv_render_context (destroyed with the renderer, on the render thread) to
    // be freed before the handle. Whichever of the two dies last releases it.
    std::shared_ptr<mpv_handle> mpvHandleRef() const { return m_mpvOwner; }
#endif

signals:
    void sourceChanged();
    void playingChanged();
    void positionChanged(double position);
    void durationChanged(double duration);
    void sessionPositionChanged(double position);
    void sessionDurationChanged(double duration);
    void volumeChanged(int volume);
    void mutedChanged(bool muted);
    void playbackSpeedChanged(double speed);
    void errorOccurred(const QString &error);
    void endReached();
    void ready();
    void loadingChanged();
    void tracksChanged();
    void hwdecChanged();

private:
    QString m_source;
    bool m_playing = false;
    bool m_loading = false;
    double m_position = 0.0;
    double m_duration = 0.0;
    double m_sessionPosition = 0.0;
    double m_sessionDuration = 0.0;
    qint64 m_sessionStartTime = 0;
    qint64 m_lastTickTime = 0;
    int m_sessionTimerId = 0;
    int m_volume = 100;
    bool m_muted = false;
    double m_speed = 1.0;
    QString m_hwdec = "auto";
    bool m_clearFrame = false;
    QVariantList m_audioTracks;
    QVariantList m_subtitleTracks;
    QVariantList m_videoTracks;

#if HAS_MPV
    std::shared_ptr<mpv_handle> m_mpvOwner;
    mpv_handle *m_mpv = nullptr; // non-owning shortcut to m_mpvOwner
    mutable QMutex m_mutex;
    QQueue<std::function<void(mpv_handle *)>> m_commandQueue;

    static void onMpvWakeup(void *ctx);
    void onMpvEvent(mpv_event *event);
    Q_INVOKABLE void handleMpvEvents();
    void updateProperties();
    void updateTrackList();
    void timerEvent(QTimerEvent *event) override;
    friend class MpvRenderer;
#endif
};

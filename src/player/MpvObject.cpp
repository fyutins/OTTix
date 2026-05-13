#include "MpvObject.h"
#include "MpvRenderer.h"

#include <QDebug>

static const char *mpvEventName(mpv_event_id id)
{
    switch (id) {
    case MPV_EVENT_NONE: return "NONE";
    case MPV_EVENT_SHUTDOWN: return "SHUTDOWN";
    case MPV_EVENT_LOG_MESSAGE: return "LOG_MESSAGE";
    case MPV_EVENT_GET_PROPERTY_REPLY: return "GET_PROPERTY_REPLY";
    case MPV_EVENT_SET_PROPERTY_REPLY: return "SET_PROPERTY_REPLY";
    case MPV_EVENT_COMMAND_REPLY: return "COMMAND_REPLY";
    case MPV_EVENT_START_FILE: return "START_FILE";
    case MPV_EVENT_END_FILE: return "END_FILE";
    case MPV_EVENT_FILE_LOADED: return "FILE_LOADED";
    case MPV_EVENT_PLAYBACK_RESTART: return "PLAYBACK_RESTART";
    case MPV_EVENT_SEEK: return "SEEK";
    case MPV_EVENT_VIDEO_RECONFIG: return "VIDEO_RECONFIG";
    case MPV_EVENT_AUDIO_RECONFIG: return "AUDIO_RECONFIG";
    default: return "UNKNOWN";
    }
}

MpvObject::MpvObject(QQuickItem *parent)
    : QQuickFramebufferObject(parent)
{
#if HAS_MPV
    setMirrorVertically(true);

    qDebug() << "[MPV] Creating mpv handle...";
    m_mpv = mpv_create();
    if (!m_mpv) {
        qFatal("[MPV] Failed to create mpv handle");
        return;
    }
    qDebug() << "[MPV] mpv handle created:" << m_mpv;

    mpv_set_option_string(m_mpv, "vo", "libmpv");
    mpv_set_option_string(m_mpv, "hwdec", "auto");
    mpv_set_option_string(m_mpv, "profile", "low-latency");
    mpv_set_option_string(m_mpv, "cache", "yes");
    mpv_set_option_string(m_mpv, "demuxer-max-bytes", "150M");
    mpv_set_option_string(m_mpv, "demuxer-max-back-bytes", "75M");
    mpv_set_option_string(m_mpv, "keepaspect", "yes");
    mpv_set_option_string(m_mpv, "audio-client-name", "IptvPlayer");

    if (mpv_initialize(m_mpv) < 0) {
        qFatal("[MPV] mpv_initialize failed");
        return;
    }
    qDebug() << "[MPV] mpv initialized successfully";

    mpv_set_wakeup_callback(m_mpv, onMpvWakeup, this);
#else
    Q_UNUSED(parent)
#endif
}

MpvObject::~MpvObject()
{
#if HAS_MPV
    qDebug() << "[MPV] Destroying MpvObject";
    if (m_mpv) {
        mpv_command(m_mpv, (const char *[]){"stop", nullptr});
        mpv_terminate_destroy(m_mpv);
    }
#endif
}

QQuickFramebufferObject::Renderer *MpvObject::createRenderer() const
{
#if HAS_MPV
    return new MpvRenderer(const_cast<MpvObject *>(this));
#else
    return new MpvRenderer(nullptr);
#endif
}

void MpvObject::setSource(const QString &source)
{
    qDebug() << "[MPV] setSource:" << source << "(current:" << m_source << ")";
    if (m_source == source) {
        qDebug() << "[MPV] setSource: same source, forcing reload";
        loadUrl(source);
        return;
    }
    m_source = source;
    emit sourceChanged();
    if (!source.isEmpty())
        loadUrl(source);
}

void MpvObject::play()
{
    qDebug() << "[MPV] play()";
#if HAS_MPV
    int flag = 0;
    int r = mpv_set_property(m_mpv, "pause", MPV_FORMAT_FLAG, &flag);
    qDebug() << "[MPV] mpv_set_property(pause=0) returned:" << r;
    if (r < 0) qDebug() << "[MPV] ERROR:" << mpv_error_string(r);
#endif
}

void MpvObject::pause()
{
    qDebug() << "[MPV] pause()";
#if HAS_MPV
    int flag = 1;
    int r = mpv_set_property(m_mpv, "pause", MPV_FORMAT_FLAG, &flag);
    qDebug() << "[MPV] mpv_set_property(pause=1) returned:" << r;
    if (r < 0) qDebug() << "[MPV] ERROR:" << mpv_error_string(r);
#endif
}

void MpvObject::stop()
{
    qDebug() << "[MPV] stop()";
#if HAS_MPV
    int r = mpv_command(m_mpv, (const char *[]){"stop", nullptr});
    qDebug() << "[MPV] mpv_command(stop) returned:" << r;
    if (r < 0) qDebug() << "[MPV] ERROR:" << mpv_error_string(r);
#endif
}

void MpvObject::seek(double position)
{
#if HAS_MPV
    QString cmd = QString::number(position);
    QByteArray ba = cmd.toUtf8();
    const char *args[] = {"seek", ba.constData(), "absolute", nullptr};
    mpv_command(m_mpv, args);
#else
    Q_UNUSED(position)
#endif
}

void MpvObject::setVolume(int volume)
{
    m_volume = qBound(0, volume, 100);
    emit volumeChanged(m_volume);
#if HAS_MPV
    double vol = m_volume;
    mpv_set_property(m_mpv, "volume", MPV_FORMAT_DOUBLE, &vol);
#endif
}

void MpvObject::setMuted(bool muted)
{
    m_muted = muted;
    emit mutedChanged(muted);
#if HAS_MPV
    mpv_set_property(m_mpv, "mute", MPV_FORMAT_FLAG, &muted);
#endif
}

void MpvObject::setPlaybackSpeed(double speed)
{
    m_speed = speed;
    emit playbackSpeedChanged(speed);
#if HAS_MPV
    mpv_set_property(m_mpv, "speed", MPV_FORMAT_DOUBLE, &speed);
#endif
}

void MpvObject::loadFile(const QString &path)
{
    qDebug() << "[MPV] loadFile:" << path;
    m_source = path;
    emit sourceChanged();
#if HAS_MPV
    QByteArray ba = path.toUtf8();
    const char *args[] = {"loadfile", ba.constData(), nullptr};
    int r = mpv_command(m_mpv, args);
    qDebug() << "[MPV] mpv_command(loadfile) returned:" << r;
    if (r < 0) qDebug() << "[MPV] ERROR:" << mpv_error_string(r);
#else
    Q_UNUSED(path)
#endif
}

void MpvObject::loadUrl(const QString &url)
{
    qDebug() << "[MPV] loadUrl:" << url;
    m_source = url;
    emit sourceChanged();
#if HAS_MPV
    QByteArray ba = url.toUtf8();
    const char *args[] = {"loadfile", ba.constData(), nullptr};
    int r = mpv_command(m_mpv, args);
    qDebug() << "[MPV] mpv_command(loadfile) returned:" << r;
    if (r < 0) qDebug() << "[MPV] ERROR:" << mpv_error_string(r);
#else
    Q_UNUSED(url)
#endif
}

void MpvObject::enqueueCommand(std::function<void(mpv_handle *)> cmd)
{
#if HAS_MPV
    QMutexLocker lock(&m_mutex);
    m_commandQueue.enqueue(std::move(cmd));
#else
    Q_UNUSED(cmd)
#endif
}

bool MpvObject::dequeueCommand(std::function<void(mpv_handle *)> &cmd)
{
#if HAS_MPV
    QMutexLocker lock(&m_mutex);
    if (m_commandQueue.isEmpty())
        return false;
    cmd = m_commandQueue.dequeue();
    return true;
#else
    Q_UNUSED(cmd)
    return false;
#endif
}

#if HAS_MPV
void MpvObject::onMpvWakeup(void *ctx)
{
    QMetaObject::invokeMethod(static_cast<MpvObject *>(ctx), "handleMpvEvents",
                              Qt::QueuedConnection);
}

void MpvObject::handleMpvEvents()
{
    qDebug() << "[MPV] handleMpvEvents called";
    if (!m_mpv) {
        qDebug() << "[MPV] handleMpvEvents: m_mpv is null, returning";
        return;
    }

    int count = 0;
    while (m_mpv) {
        mpv_event *event = mpv_wait_event(m_mpv, 0);
        if (event->event_id == MPV_EVENT_NONE)
            break;
        qDebug() << "[MPV] event #" << count << ":" << mpvEventName(event->event_id)
                 << "(id:" << event->event_id << ")";
        onMpvEvent(event);
        count++;
    }
    qDebug() << "[MPV] handleMpvEvents done, processed" << count << "events";
}

void MpvObject::onMpvEvent(mpv_event *event)
{
    switch (event->event_id) {
    case MPV_EVENT_SHUTDOWN:
        qDebug() << "[MPV] SHUTDOWN received";
        break;
    case MPV_EVENT_START_FILE:
        qDebug() << "[MPV] START_FILE - mpv started loading file";
        break;
    case MPV_EVENT_FILE_LOADED:
        qDebug() << "[MPV] FILE_LOADED - file loaded successfully, setting playing=true";
        m_playing = true;
        emit playingChanged();
        emit ready();
        break;
    case MPV_EVENT_PLAYBACK_RESTART:
        qDebug() << "[MPV] PLAYBACK_RESTART - playback started/resumed";
        m_playing = true;
        emit playingChanged();
        break;
    case MPV_EVENT_VIDEO_RECONFIG:
        qDebug() << "[MPV] VIDEO_RECONFIG - video parameters changed";
        break;
    case MPV_EVENT_AUDIO_RECONFIG:
        qDebug() << "[MPV] AUDIO_RECONFIG - audio parameters changed";
        break;
    case MPV_EVENT_END_FILE: {
        m_playing = false;
        emit playingChanged();
        mpv_event_end_file *ef = (mpv_event_end_file *)event->data;
        qDebug() << "[MPV] END_FILE reason:" << ef->reason << "error:" << ef->error;
        if (ef->reason == MPV_END_FILE_REASON_ERROR)
            emit errorOccurred(tr("Playback error: %1").arg(ef->error));
        else
            emit endReached();
        break;
    }
    case MPV_EVENT_PROPERTY_CHANGE: {
        mpv_event_property *prop = (mpv_event_property *)event->data;
        QString val;
        if (prop->data) {
            if (prop->format == MPV_FORMAT_DOUBLE)
                val = QString::number(*(double *)prop->data);
            else if (prop->format == MPV_FORMAT_FLAG)
                val = *(int *)prop->data ? "true" : "false";
            else if (prop->format == MPV_FORMAT_STRING)
                val = *(const char **)prop->data;
            else
                val = "(format:" + QString::number(prop->format) + ")";
        } else {
            val = "(null)";
        }
        qDebug() << "[MPV] PROPERTY_CHANGE:" << prop->name << "=" << val;

        if (strcmp(prop->name, "time-pos") == 0 && prop->format == MPV_FORMAT_DOUBLE && prop->data) {
            m_position = *(double *)prop->data;
            emit positionChanged(m_position);
        } else if (strcmp(prop->name, "duration") == 0 && prop->format == MPV_FORMAT_DOUBLE && prop->data) {
            m_duration = *(double *)prop->data;
            emit durationChanged(m_duration);
        } else if (strcmp(prop->name, "volume") == 0 && prop->format == MPV_FORMAT_DOUBLE && prop->data) {
            m_volume = *(double *)prop->data;
            emit volumeChanged(m_volume);
        } else if (strcmp(prop->name, "mute") == 0 && prop->format == MPV_FORMAT_FLAG && prop->data) {
            m_muted = *(int *)prop->data;
            emit mutedChanged(m_muted);
        } else if (strcmp(prop->name, "pause") == 0 && prop->format == MPV_FORMAT_FLAG && prop->data) {
            m_playing = !*(int *)prop->data;
            qDebug() << "[MPV] pause changed, playing now:" << m_playing;
            emit playingChanged();
        } else if (strcmp(prop->name, "speed") == 0 && prop->format == MPV_FORMAT_DOUBLE && prop->data) {
            m_speed = *(double *)prop->data;
            emit playbackSpeedChanged(m_speed);
        }
        break;
    }
    default:
        qDebug() << "[MPV] Unhandled event:" << mpvEventName(event->event_id);
        break;
    }
}

void MpvObject::updateProperties()
{
    qDebug() << "[MPV] updateProperties: observing properties";
    mpv_observe_property(m_mpv, 0, "time-pos", MPV_FORMAT_DOUBLE);
    mpv_observe_property(m_mpv, 0, "duration", MPV_FORMAT_DOUBLE);
    mpv_observe_property(m_mpv, 0, "volume", MPV_FORMAT_DOUBLE);
    mpv_observe_property(m_mpv, 0, "mute", MPV_FORMAT_FLAG);
    mpv_observe_property(m_mpv, 0, "pause", MPV_FORMAT_FLAG);
    mpv_observe_property(m_mpv, 0, "speed", MPV_FORMAT_DOUBLE);

    double vol = 100;
    mpv_get_property(m_mpv, "volume", MPV_FORMAT_DOUBLE, &vol);
    m_volume = static_cast<int>(vol);
    emit volumeChanged(m_volume);
    qDebug() << "[MPV] Initial volume:" << m_volume;
}
#endif

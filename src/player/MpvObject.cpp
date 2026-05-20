#include "MpvObject.h"
#include "MpvRenderer.h"

#include <QDebug>
#include <QDateTime>
#include <QTimerEvent>

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
    mpv_set_option_string(m_mpv, "hwdec", m_hwdec.toUtf8().constData());
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
    updateProperties();

    m_sessionTimerId = startTimer(250);
#else
    Q_UNUSED(parent)
#endif
}

MpvObject::~MpvObject()
{
#if HAS_MPV
    qDebug() << "[MPV] Destroying MpvObject";
    if (m_mpv) {
        const char *stop_cmd[] = {"stop", nullptr};
        mpv_command(m_mpv, stop_cmd);
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
    m_lastTickTime = QDateTime::currentMSecsSinceEpoch();
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
    const char *stop_cmd[] = {"stop", nullptr};
    int r = mpv_command(m_mpv, stop_cmd);
    qDebug() << "[MPV] mpv_command(stop) returned:" << r;
    if (r < 0) qDebug() << "[MPV] ERROR:" << mpv_error_string(r);
#endif
}

void MpvObject::seek(double position)
{
    qDebug() << "[MPV] seek() called with position =" << position
             << "| sessionDuration =" << m_sessionDuration
             << "| sessionPosition (current) =" << m_sessionPosition
             << "| m_position (mpv time-pos) =" << m_position;
    double sessionTarget = qBound(0.0, position, m_sessionDuration);
    double delta = sessionTarget - m_sessionPosition;
    m_sessionPosition = sessionTarget;
    m_lastTickTime = QDateTime::currentMSecsSinceEpoch();
    emit sessionPositionChanged(sessionTarget);
#if HAS_MPV
    qDebug() << "[MPV] seek -> sessionTarget =" << sessionTarget
             << "| delta (relative) =" << delta;
    QString cmd = QString::number(delta);
    QByteArray ba = cmd.toUtf8();
    const char *args[] = {"seek", ba.constData(), "relative", nullptr};
    int r = mpv_command(m_mpv, args);
    qDebug() << "[MPV] seek mpv_command returned:" << r
             << (r < 0 ? mpv_error_string(r) : "");
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
    int flag = muted ? 1 : 0;
    mpv_set_property(m_mpv, "mute", MPV_FORMAT_FLAG, &flag);
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

void MpvObject::clearVideo()
{
    qDebug() << "[MPV] clearVideo - clearing frame buffer";
    m_clearFrame = true;
}

void MpvObject::reload()
{
    qDebug() << "[MPV] reload() - restarting current stream:" << m_source;
#if HAS_MPV
    if (!m_mpv || m_source.isEmpty())
        return;
    clearVideo();
    const char *stop_cmd[] = {"stop", nullptr};
    mpv_command(m_mpv, stop_cmd);
    QByteArray ba = m_source.toUtf8();
    const char *load_cmd[] = {"loadfile", ba.constData(), nullptr};
    mpv_command(m_mpv, load_cmd);
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
    if (!m_mpv) {
        qDebug() << "[MPV] handleMpvEvents: m_mpv is null, returning";
        return;
    }

    int count = 0;
    while (m_mpv) {
        mpv_event *event = mpv_wait_event(m_mpv, 0);
        if (event->event_id == MPV_EVENT_NONE)
            break;
        onMpvEvent(event);
        count++;
    }
}

void MpvObject::onMpvEvent(mpv_event *event)
{
    switch (event->event_id) {
    case MPV_EVENT_SHUTDOWN:
        qDebug() << "[MPV] SHUTDOWN received";
        break;
    case MPV_EVENT_START_FILE: {
        qDebug() << "[MPV] START_FILE - mpv started loading file";
        m_loading = true;
        emit loadingChanged();
        break;
    }
    case MPV_EVENT_FILE_LOADED: {
        qDebug() << "[MPV] FILE_LOADED - file loaded successfully";
        m_loading = false;
        m_playing = true;
        m_clearFrame = false;
        m_sessionStartTime = QDateTime::currentMSecsSinceEpoch();
        m_sessionPosition = 0.0;
        m_sessionDuration = 0.0;
        m_lastTickTime = m_sessionStartTime;
        emit sessionPositionChanged(0.0);
        emit sessionDurationChanged(0.0);
        emit loadingChanged();
        emit playingChanged();
        emit ready();
        break;
    }

    case MPV_EVENT_PLAYBACK_RESTART:
        qDebug() << "[MPV] PLAYBACK_RESTART - playback started/resumed"
                 << "| m_position =" << m_position
                 << "| sessionPosition =" << m_sessionPosition;
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
        m_loading = false;
        emit playingChanged();
        emit loadingChanged();
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
        } else if (strcmp(prop->name, "track-list") == 0 && prop->format == MPV_FORMAT_NODE) {
            updateTrackList();
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
    mpv_observe_property(m_mpv, 0, "track-list", MPV_FORMAT_NODE);

    double vol = 100;
    mpv_get_property(m_mpv, "volume", MPV_FORMAT_DOUBLE, &vol);
    m_volume = static_cast<int>(vol);
    emit volumeChanged(m_volume);
    qDebug() << "[MPV] Initial volume:" << m_volume;
}

void MpvObject::updateTrackList()
{
    mpv_node node;
    if (mpv_get_property(m_mpv, "track-list", MPV_FORMAT_NODE, &node) < 0)
        return;

    m_audioTracks.clear();
    m_subtitleTracks.clear();
    m_videoTracks.clear();

    if (node.format != MPV_FORMAT_NODE_ARRAY) {
        mpv_free_node_contents(&node);
        return;
    }

    for (int i = 0; i < node.u.list->num; i++) {
        mpv_node *entry = &node.u.list->values[i];
        if (entry->format != MPV_FORMAT_NODE_MAP)
            continue;

        QVariantMap track;
        QString type;
        int id = -1;

        for (int j = 0; j < entry->u.list->num; j++) {
            QString key = entry->u.list->keys[j];
            mpv_node *val = &entry->u.list->values[j];

            if (key == "type" && val->format == MPV_FORMAT_STRING)
                type = val->u.string;
            else if (key == "id" && val->format == MPV_FORMAT_INT64)
                id = val->u.int64;
            else if (key == "selected" && val->format == MPV_FORMAT_FLAG)
                track["selected"] = val->u.flag;
            else if (key == "lang" && val->format == MPV_FORMAT_STRING)
                track["lang"] = QString(val->u.string);
            else if (key == "title" && val->format == MPV_FORMAT_STRING)
                track["title"] = QString(val->u.string);
            else if (key == "default" && val->format == MPV_FORMAT_FLAG)
                track["default"] = val->u.flag;
        }

        track["id"] = id;
        QString label = track.value("title").toString();
        if (label.isEmpty())
            label = track.value("lang").toString();
        if (label.isEmpty())
            label = type + " #" + QString::number(id);
        track["label"] = label;

        if (type == "audio")
            m_audioTracks.append(track);
        else if (type == "sub")
            m_subtitleTracks.append(track);
        else if (type == "video")
            m_videoTracks.append(track);
    }

    mpv_free_node_contents(&node);
    emit tracksChanged();
}

void MpvObject::setAudioTrack(int trackId)
{
    qDebug() << "[MPV] setAudioTrack:" << trackId;
    enqueueCommand([trackId](mpv_handle *mpv) {
        int64_t id = trackId;
        mpv_set_property(mpv, "audio", MPV_FORMAT_INT64, &id);
    });
}

void MpvObject::setSubtitleTrack(int trackId)
{
    qDebug() << "[MPV] setSubtitleTrack:" << trackId;
    enqueueCommand([trackId](mpv_handle *mpv) {
        if (trackId < 0) {
            const char *args[] = {"set", "sub", "no", nullptr};
            mpv_command(mpv, args);
        } else {
            int64_t id = trackId;
            mpv_set_property(mpv, "sub", MPV_FORMAT_INT64, &id);
        }
    });
}

void MpvObject::setVideoTrack(int trackId)
{
    qDebug() << "[MPV] setVideoTrack:" << trackId;
    enqueueCommand([trackId](mpv_handle *mpv) {
        int64_t id = trackId;
        mpv_set_property(mpv, "video", MPV_FORMAT_INT64, &id);
    });
}

void MpvObject::setHwdec(const QString &hwdec)
{
    if (m_hwdec == hwdec)
        return;
    m_hwdec = hwdec;
    emit hwdecChanged();
#if HAS_MPV
    QByteArray ba = hwdec.toUtf8();
    int r = mpv_set_property_string(m_mpv, "hwdec", ba.constData());
    if (r < 0)
        qDebug() << "[MPV] setHwdec error:" << mpv_error_string(r);
#endif
}

void MpvObject::timerEvent(QTimerEvent *event)
{
    if (event->timerId() != m_sessionTimerId || m_sessionStartTime == 0) {
        QQuickFramebufferObject::timerEvent(event);
        return;
    }

    qint64 now = QDateTime::currentMSecsSinceEpoch();

    double newDuration = (now - m_sessionStartTime) / 1000.0;
    if (qAbs(newDuration - m_sessionDuration) > 0.01) {
        m_sessionDuration = newDuration;
        emit sessionDurationChanged(m_sessionDuration);
    }

    if (m_playing) {
        m_sessionPosition += (now - m_lastTickTime) / 1000.0;
        if (m_sessionPosition > m_sessionDuration)
            m_sessionPosition = m_sessionDuration;
        emit sessionPositionChanged(m_sessionPosition);
    }

    m_lastTickTime = now;
}
#endif

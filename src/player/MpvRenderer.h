#pragma once

#include <QQuickFramebufferObject>
#include <QOpenGLFramebufferObject>

#if HAS_MPV
#include <QOpenGLFunctions>
#include <mpv/client.h>
#include <mpv/render_gl.h>
#endif

class MpvObject;

class MpvRenderer : public QQuickFramebufferObject::Renderer
#if HAS_MPV
    , protected QOpenGLFunctions
#endif
{
public:
    explicit MpvRenderer(MpvObject *obj);
    ~MpvRenderer() override;

    QOpenGLFramebufferObject *createFramebufferObject(const QSize &size) override;
    void synchronize(QQuickFramebufferObject *item) override;
    void render() override;

private:
    MpvObject *m_obj;
#if HAS_MPV
    mpv_handle *m_mpv = nullptr;
    mpv_render_context *m_mpvGl = nullptr;
    bool m_initialized = false;
    static void onUpdate(void *ctx);
#endif
};

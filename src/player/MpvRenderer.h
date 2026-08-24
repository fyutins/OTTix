#pragma once

#include <QPointer>
#include <QQuickFramebufferObject>
#include <QOpenGLFramebufferObject>

#if HAS_MPV
#include <QOpenGLFunctions>
#include <mpv/client.h>
#include <mpv/render_gl.h>
#include <memory>
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
    // QPointer : le renderer est detruit par le scene graph, potentiellement
    // apres l'item auquel il appartient.
    QPointer<MpvObject> m_obj;
#if HAS_MPV
    std::shared_ptr<mpv_handle> m_mpvOwner;
    mpv_handle *m_mpv = nullptr;
    mpv_render_context *m_mpvGl = nullptr;
    bool m_initialized = false;
    bool m_clearFrame = false;
    static void onUpdate(void *ctx);
#endif
};

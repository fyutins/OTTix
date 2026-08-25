#include "MpvRenderer.h"
#include "../utils/Logging.h"
#include "MpvObject.h"

#include <QDebug>
#include <QOpenGLContext>
#include <QQuickWindow>
#include <QtGlobal>

MpvRenderer::MpvRenderer(MpvObject *obj)
    : m_obj(obj)
{
    qCDebug(logRender) << "[RENDERER] MpvRenderer created, obj:" << obj;
#if HAS_MPV
    initializeOpenGLFunctions();
#endif
}

MpvRenderer::~MpvRenderer()
{
    qCDebug(logRender) << "[RENDERER] MpvRenderer destroyed";
#if HAS_MPV
    if (m_mpvGl) {
        qCDebug(logRender) << "[RENDERER] Freeing mpv render context";
        mpv_render_context_free(m_mpvGl);
        m_mpvGl = nullptr;
    }
    // The render context must go away before the handle: the shared reference
    // is only released here, once mpv_render_context_free() has run.
    m_mpv = nullptr;
    m_mpvOwner.reset();
#endif
}

QOpenGLFramebufferObject *MpvRenderer::createFramebufferObject(const QSize &size)
{
    return new QOpenGLFramebufferObject(size, QOpenGLFramebufferObject::CombinedDepthStencil);
}

void MpvRenderer::synchronize(QQuickFramebufferObject *item)
{
#if HAS_MPV
    MpvObject *obj = static_cast<MpvObject *>(item);

    if (!m_initialized) {
        qCDebug(logRender) << "[RENDERER] synchronize: first call, initializing mpv render context";
        m_mpvOwner = obj->mpvHandleRef();
        m_mpv = m_mpvOwner.get();
        qCDebug(logRender) << "[RENDERER] mpv handle:" << m_mpv;
        if (!m_mpv)
            return;

        mpv_opengl_init_params gl_init;
        gl_init.get_proc_address = [](void *ctx, const char *name) -> void * {
            QOpenGLContext *glctx = QOpenGLContext::currentContext();
            if (!glctx) {
                qCDebug(logRender) << "[RENDERER] No current OpenGL context!";
                return nullptr;
            }
            void *addr = reinterpret_cast<void *>(glctx->getProcAddress(name));
            qCDebug(logRender) << "[RENDERER] getProcAddress(" << name << ") =" << addr;
            return addr;
        };
        gl_init.get_proc_address_ctx = nullptr;

        mpv_render_param params[] = {
            {MPV_RENDER_PARAM_API_TYPE, (void *)MPV_RENDER_API_TYPE_OPENGL},
            {MPV_RENDER_PARAM_OPENGL_INIT_PARAMS, &gl_init},
            {MPV_RENDER_PARAM_INVALID, nullptr}
        };

        int ret = mpv_render_context_create(&m_mpvGl, m_mpv, params);
        qCDebug(logRender) << "[RENDERER] mpv_render_context_create returned:" << ret;
        if (ret < 0) {
            qCWarning(logRender) << "[RENDERER] Failed to create mpv render context:" << mpv_error_string(ret);
            return;
        }
        qCDebug(logRender) << "[RENDERER] mpv render context created:" << m_mpvGl;

        mpv_render_context_set_update_callback(m_mpvGl, onUpdate, this);
        obj->updateProperties();
        m_initialized = true;
        qCDebug(logRender) << "[RENDERER] Mpv render initialized successfully";
    }

    std::function<void(mpv_handle *)> cmd;
    int cmdCount = 0;
    while (obj->dequeueCommand(cmd)) {
        if (cmd && m_mpv) {
            cmd(m_mpv);
            cmdCount++;
        }
    }
    if (cmdCount > 0)
        qCDebug(logRender) << "[RENDERER] Executed" << cmdCount << "queued commands";

    m_clearFrame = obj->m_clearFrame;
#else
    Q_UNUSED(item)
#endif
}

void MpvRenderer::render()
{
#if HAS_MPV
    if (!m_mpvGl || !m_initialized) {
        static int skip = 0;
        if (++skip % 60 == 0)
            qCDebug(logRender) << "[RENDERER] render skipped: m_mpvGl=" << m_mpvGl << "m_initialized=" << m_initialized;
        return;
    }

    QOpenGLFramebufferObject *fbo = framebufferObject();
    if (!fbo) {
        qCDebug(logRender) << "[RENDERER] No FBO available";
        return;
    }

    fbo->bind();

    if (m_clearFrame) {
        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT);
        fbo->release();
        return;
    }

    qreal dpr = m_obj && m_obj->window() ? m_obj->window()->devicePixelRatio() : 1.0;
    QSize fboSize = fbo->size() / dpr;

    int flip = 1;
    mpv_opengl_fbo mpfbo;
    mpfbo.fbo = static_cast<int>(fbo->handle());
    mpfbo.w = static_cast<int>(fboSize.width());
    mpfbo.h = static_cast<int>(fboSize.height());
    mpfbo.internal_format = 0;

    mpv_render_param params[] = {
        {MPV_RENDER_PARAM_OPENGL_FBO, &mpfbo},
        {MPV_RENDER_PARAM_FLIP_Y, &flip},
        {MPV_RENDER_PARAM_INVALID, nullptr}
    };

    int ret = mpv_render_context_render(m_mpvGl, params);
    if (ret < 0) {
        static int err_skip = 0;
        if (++err_skip % 60 == 0)
            qCDebug(logRender) << "[RENDERER] mpv_render_context_render returned:" << ret << mpv_error_string(ret);
    }
    fbo->release();
#endif
}

#if HAS_MPV
void MpvRenderer::onUpdate(void *ctx)
{
    MpvRenderer *renderer = static_cast<MpvRenderer *>(ctx);
    if (!renderer || !renderer->m_obj)
        return;

    QPointer<MpvObject> obj = renderer->m_obj;
    QMetaObject::invokeMethod(obj, [obj]() {
        if (obj)
            obj->update();
    });
}
#endif

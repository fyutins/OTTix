#pragma once

#include <QLoggingCategory>

// Categories de log de l'application. Toutes sont limitees a Warning par
// defaut : activer au besoin via QT_LOGGING_RULES, par exemple
//   QT_LOGGING_RULES="iptv.*.debug=true"
//   QT_LOGGING_RULES="iptv.mpv.debug=true;iptv.db.debug=true"
Q_DECLARE_LOGGING_CATEGORY(logDb)
Q_DECLARE_LOGGING_CATEGORY(logModel)
Q_DECLARE_LOGGING_CATEGORY(logLoader)
Q_DECLARE_LOGGING_CATEGORY(logXtream)
Q_DECLARE_LOGGING_CATEGORY(logMpv)
Q_DECLARE_LOGGING_CATEGORY(logRender)
Q_DECLARE_LOGGING_CATEGORY(logPerf)

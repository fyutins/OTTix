#pragma once

#include <QLoggingCategory>

// Application log categories. All are capped at Warning by default: enable
// them as needed through QT_LOGGING_RULES, for example
//   QT_LOGGING_RULES="iptv.*.debug=true"
//   QT_LOGGING_RULES="iptv.mpv.debug=true;iptv.db.debug=true"
Q_DECLARE_LOGGING_CATEGORY(logDb)
Q_DECLARE_LOGGING_CATEGORY(logModel)
Q_DECLARE_LOGGING_CATEGORY(logLoader)
Q_DECLARE_LOGGING_CATEGORY(logXtream)
Q_DECLARE_LOGGING_CATEGORY(logMpv)
Q_DECLARE_LOGGING_CATEGORY(logRender)
Q_DECLARE_LOGGING_CATEGORY(logPerf)
Q_DECLARE_LOGGING_CATEGORY(logLogo)

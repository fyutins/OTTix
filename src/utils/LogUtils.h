#pragma once

#include <QString>

namespace LogUtils {

// Masque les identifiants presents dans une URL avant de la journaliser.
// Couvre les credentials Xtream, qui voyagent soit en query string
// (player_api.php?username=...&password=...), soit dans le chemin
// (/live/<user>/<password>/<id>.ts), soit en userinfo (http://user:pass@host).
QString scrubUrl(const QString &url);

} // namespace LogUtils

#pragma once

#include <QString>

namespace LogUtils {

// Masks the credentials carried by a URL before logging it. Covers Xtream
// credentials, which travel either in the query string
// (player_api.php?username=...&password=...), in the path
// (/live/<user>/<password>/<id>.ts), or as userinfo (http://user:pass@host).
QString scrubUrl(const QString &url);

} // namespace LogUtils

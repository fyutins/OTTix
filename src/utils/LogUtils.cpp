#include "LogUtils.h"

#include <QRegularExpression>
#include <QUrl>
#include <QUrlQuery>

namespace {
const QString kMask = QStringLiteral("***");
}

namespace LogUtils {

QString scrubUrl(const QString &url)
{
    if (url.isEmpty())
        return url;

    QUrl u(url);
    if (!u.isValid() || u.scheme().isEmpty())
        return url;

    if (!u.password().isEmpty())
        u.setPassword(kMask);

    if (u.hasQuery()) {
        QUrlQuery query(u);
        bool changed = false;
        for (const QString &key : {QStringLiteral("password"), QStringLiteral("pass")}) {
            if (query.hasQueryItem(key)) {
                query.removeAllQueryItems(key);
                query.addQueryItem(key, kMask);
                changed = true;
            }
        }
        if (changed)
            u.setQuery(query);
    }

    // /live/<user>/<password>/<id>.ext (idem movie, series, timeshift)
    static const QRegularExpression streamPath(
        QStringLiteral("^(/(?:live|movie|series|timeshift)/[^/]+/)[^/]+(/.*)$"),
        QRegularExpression::CaseInsensitiveOption);

    const QString path = u.path();
    QRegularExpressionMatch m = streamPath.match(path);
    if (m.hasMatch())
        u.setPath(m.captured(1) + kMask + m.captured(2));

    return u.toString();
}

} // namespace LogUtils

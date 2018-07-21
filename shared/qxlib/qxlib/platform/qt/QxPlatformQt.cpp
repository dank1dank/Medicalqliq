#include "QxPlatformQt.hpp"
#include <QDir>
#include <QSettings>
#ifdef Q_OS_WIN
#include <QSettings>
#include <QFileInfo>
#else
#include <QProcess>
#endif
#include "qxlib/model/QxSession.hpp"
#include "qxlib/crypto/QxCrypto.hpp"
#include "qxlib/platform/qt/QxPlatformQtHelpers.hpp"
#include "qxlib/util/QxSettings.hpp"
#if defined(QLIQ_STOR_SERVICE) || defined(QLIQ_STOR_MANAGER) || defined(QLIQ_STOR_WEB_SERVICE)
#include "qliqstor/QliqStorUtil.h"
#elif defined(QLIQ_DIRECT_SERVICE) || defined(QLIQ_DIRECT_MANAGER)
#include "qliqdirect/QliqDirectUtil.h"
#else
#include "util/SettingsHelper.h"
#endif
#include "connect/AttachmentManager.h"
#include "sip/QliqSip.hpp"

namespace qx {

struct PlatformQt::Private {
    Crypto *crypto;

    Private() :
        crypto(nullptr)
    {}

    ~Private()
    {
        delete crypto;
    }
};

PlatformQt::PlatformQt() :
    d(new Private)
{}

PlatformQt::~PlatformQt()
{
    delete d;
}

void PlatformQt::setMyUser(const QString &qliqId, const QString &email, const QString &displayName)
{
    qx::Session::instance().setMyQliqId(qx::toStd(qliqId));
    qx::Session::instance().setMyEmail(qx::toStd(email));
    qx::Session::instance().setMyDisplayName(qx::toStd(displayName));
}

void PlatformQt::setDeviceName(const QString &deviceName)
{
    qx::Session::instance().setDeviceName(qx::toStd(deviceName));
}

void PlatformQt::setKeyPair(evp_pkey_st *pubKey, const std::string &publicKeyString, evp_pkey_st *privKey)
{
    if (!d->crypto) {
        d->crypto = new qx::Crypto;
        qx::Crypto::setInstance(d->crypto);
    }

    d->crypto->setKeys(pubKey, publicKeyString, privKey);
}

///////////////////////////////////////////////////////////////////////////////
// Settings
//
struct Settings::Private {
    QSettings s;
};

Settings::Settings() :
    d(new Private)
{}

Settings::~Settings()
{
    delete d;
}

void Settings::setValue(const std::string &key, const std::string &value)
{
    d->s.setValue(qx::toQt(key), qx::toQt(value));
}

std::string Settings::valueAsString(const std::string &key, const std::string &defaultValue) const
{
    const QString& ret = d->s.value(qx::toQt(key), qx::toQt(defaultValue)).toString();
    return qx::toStd(ret);
}

bool Settings::contains(const std::string &key) const
{
    return d->s.contains(qx::toQt(key));
}

void Settings::remove(const std::string& key)
{
    d->s.remove(qx::toQt(key));
}

} // qx

std::string qx_filesystem_temporaryDirPath_impl()
{
    QString tmp = QDir::tempPath();
#ifdef Q_OS_WIN
    tmp = tmp.replace(QChar('/'), QChar('\\'));
#endif
    return qx::toStd(tmp);
}

QString qx_FileInfo_mime_impl_qt(const QString& path)
{
    QString mime;
#ifdef Q_OS_WIN
    QString ext = QFileInfo(path).suffix();
    QString registryPath = QString("HKEY_CLASSES_ROOT\\.%1").arg(ext);
    QSettings settings(registryPath, QSettings::NativeFormat);
    mime = settings.value("Content Type").toString();
#else
    QProcess pMimeChecker;
    pMimeChecker.start(QString("file --mime-type --brief \"%1\"").arg(path));
    pMimeChecker.waitForFinished(5000);

    if (pMimeChecker.exitCode() == 0)
    {
    mime = pMimeChecker.readAllStandardOutput();
    mime = mime.trimmed();
    }
#endif

    if (mime.isEmpty())
        mime = "application/octet-stream";

    return mime;
}

std::string qx_FileInfo_mime_impl(const std::string& path)
{
    return qx_FileInfo_mime_impl_qt(qx::toQt(path)).toStdString();
}

std::string qx_Session_dataDirectoryRootPath_impl()
{
#if defined(QLIQ_STOR_SERVICE) || defined(QLIQ_STOR_MANAGER) || defined(QLIQ_STOR_WEB_SERVICE)
    QString path = QliqStorUtil::dataPathForQliqId("");
#elif defined(QLIQ_DIRECT_SERVICE) || defined(QLIQ_DIRECT_MANAGER)
    QString path = QliqDirectUtil::dataPathForQliqId("");
#else
    QString path = SettingsHelper::dataDirPath("");
#endif
    if (path.endsWith(QChar('/')) || path.endsWith(QChar('\\'))) {
        path.remove(path.size() - 1, 1);
    }
#ifdef Q_OS_WIN
    path = path.replace(QChar('/'), QChar('\\'));
#endif
    return qx::toStd(path);
}

#ifdef QXL_HAS_SIP

std::string qx_sip_last_message_plain_text_body_impl(const std::string& callId)
{
    if (QliqSip::instance()) {
        return QliqSip::instance()->lastMessagePlainTextBody(callId);
    } else {
        return "";
    }
}
#endif // QXL_HAS_SIP

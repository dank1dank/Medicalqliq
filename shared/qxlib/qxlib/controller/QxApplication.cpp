#include "qxlib/controller/QxApplication.hpp"
#include "qxlib/log/sip/QxSipLogRecordDao.hpp"
#include "qxlib/log/web/QxWebLogRecordDao.hpp"
#include "qxlib/log/cn/QxChangeNotificationLogDao.hpp"
#include "qxlib/log/push/QxPushNotificationLogRecordDao.hpp"
#include "qxlib/model/QxSession.hpp"
#include "qxlib/log/QxLog.hpp"
#include "qxlib/util/QxTerminateHandler.hpp"

namespace qx {

Application::Application()
{
    TerminateHandler::install();
}

void Application::onDatabaseOpened()
{
#ifndef QXL_APP_SERVICE
    if (!LogDatabase::isDefaultInstanceOpen()) {
        QXLOG_SUPPORT("logdb is not open, skipping db log rotation", nullptr);
        return;
    }
    // Rotate db logs
    int numberOfSessionsToKeep = 3;
    if (qx::Session::instance().isTesterMode()) {
        numberOfSessionsToKeep = 5;
    }
    QXLOG_SUPPORT("Rotating db logs, keeping last %d sessions", numberOfSessionsToKeep);
    // TODO: redesign the algorithm to decide what to keep, particulary for support accounts
    qx::SipLogRecordDao::keepLastMeaningfulSessions(numberOfSessionsToKeep);
    qx::WebLogRecordDao::keepLastMeaningfulSessions(numberOfSessionsToKeep);
    qx::ChangeNotificationLogDao::keepLastMeaningfulSessions(numberOfSessionsToKeep);
    qx::PushNotificationLogRecordDao::keepLastMeaningfulSessions(numberOfSessionsToKeep);
#endif
}

void Application::onLoggedOut()
{
    qx::Session::instance().reset();
}

} // qx

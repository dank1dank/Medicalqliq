#include "QxChangeNotificationProcessor.hpp"
#include <json/json_fwd.hpp>
#include <json11/json11.hpp>
#include "qxlib/model/QxSession.hpp"
#include "qxlib/dao/QxChangeNotificationDao.hpp"
#ifdef QXL_HAS_CN_LOG
#include "qxlib/log/cn/QxChangeNotificationLogDao.hpp"
#endif // QXL_HAS_CN_LOG
#ifndef NO_GUI
#include "qxlib/web/QxGetPresenceStatusWebService.hpp"
#include "qxlib/web/fax/QxGetFaxContactsWebService.hpp"
#endif

#define STR_SESSION_IS_FINISHING "Session is finishing"

namespace qx {

ChangeNotificationProcessor::ChangeNotificationProcessor(std::string deviceUuid) :
    m_listener(nullptr),
    m_dontLoadNextFromDatabase(false),
    m_deviceUuid(deviceUuid)
{
    Session::instance().addListener(this);
    if (NetworkMonitor::instance()) {
        NetworkMonitor::instance()->addListener(this);
    } else {
        QXLOG_WARN("No NetworkMonitor instance", nullptr);
    }
}

ChangeNotificationProcessor::~ChangeNotificationProcessor()
{
    Session::instance().removeListener(this);
    if (NetworkMonitor::instance()) {
        NetworkMonitor::instance()->removeListener(this);
    }
}

void ChangeNotificationProcessor::onSessionStarted()
{
    QXLOG_SUPPORT("Session started, attempting to process any pending CN", nullptr);
    if (m_dontLoadNextFromDatabase && m_dontLoadNextFromDatabaseReason == STR_SESSION_IS_FINISHING) {
        setDontLoadNextFromDatabase(false, "");
    }
    processOne();
}

void ChangeNotificationProcessor::onSessionFinishing()
{
    if (!m_dontLoadNextFromDatabase) {
        setDontLoadNextFromDatabase(true, STR_SESSION_IS_FINISHING);
    }
}

void ChangeNotificationProcessor::onForegroundStatusChanged(bool isForegroundApp)
{
    if (isForegroundApp) {
        QXLOG_SUPPORT("App became foreground, attempting to process any pending CN", nullptr);
        processOne();
    }
}

void ChangeNotificationProcessor::onNetworkChanged(bool isOnline)
{
    if (isOnline) {
        QXLOG_SUPPORT("Online, attempting to process any pending CN", nullptr);
        processOne();
    }
}

void ChangeNotificationProcessor::onSipMessage(const std::string &jsonMessageString)
{
    int savedId = 0;
    std::vector<ChangeNotification> receivedCNs;

    try {
        auto jsonMessage = nlohmann::json::parse(jsonMessageString);
        const auto& command = jsonMessage["Command"].get<std::string>();
        if (command == "change-notification") {
            QXLOG_SUPPORT("Received CN", nullptr);
            ChangeNotification cn;
            savedId = saveChangeNotification(jsonMessage, &cn);
            if (savedId) {
                receivedCNs.push_back(cn);
            }
        } else if (command == "bulk-cn") {
            auto data = jsonMessage["Data"];
            QXLOG_SUPPORT("Received bulk CN of size %d", data.size());
            receivedCNs.reserve(data.size());
            for (const auto& item: data) {
                try {
                    ChangeNotification cn;
                    int id = saveChangeNotification(item["Message"], &cn);
                    if (id) {
                        if (savedId == 0) {
                            savedId = id;
                        }
                        receivedCNs.push_back(cn);
                    }
                } catch (const std::out_of_range& ex) {
                    QXLOG_ERROR("Invalid 'bulk-cn' item's JSON: %s", ex.what());
                }
            }
        } else {
            // Not a CN message
            return;
        }
    } catch (const std::exception& ex) {
        QXLOG_ERROR("Exception while processing SIP message: %s", ex.what());
        return;
    }

    if (!receivedCNs.empty() && m_dontLoadNextFromDatabase) {
        QXLOG_SUPPORT("Not processing just received CNs because of reason: %s", m_dontLoadNextFromDatabaseReason.c_str());
    } else if (!receivedCNs.empty()) {
        std::vector<ChangeNotification> unprocessedCNs;
        unprocessedCNs.reserve(receivedCNs.size());

        // Process immediately everything with payload
        const char *STR_PROCESSING_CN_WITH_PAYLOAD_FIRST = "Processing CNs with payload first";
        setDontLoadNextFromDatabase(true, STR_PROCESSING_CN_WITH_PAYLOAD_FIRST);
        for (auto cn: receivedCNs) {
            if (cn.hasPayload) {
                QXLOG_SUPPORT("Processing received with payload CN(%d)", cn.databaseId);
                // TODO: if there are many CNs then this CPU bound loop can freeze app
                process(cn);
            } else {
                unprocessedCNs.push_back(cn);
            }
        }
        if (m_dontLoadNextFromDatabaseReason == STR_PROCESSING_CN_WITH_PAYLOAD_FIRST) {
            // Clear the flag only if not set too by some of the just processed CNs
            setDontLoadNextFromDatabase(false, "");
        }

        receivedCNs.swap(unprocessedCNs);
        unprocessedCNs.clear();

        // login credentials, logout has priority
        bool priorityBreak = false;
        const char *STR_PROCESSING_PRIORITY_TYPE_CNS_FIRST = "Processing priority type CNs first";
        setDontLoadNextFromDatabase(true, STR_PROCESSING_PRIORITY_TYPE_CNS_FIRST);
        for (auto cn: receivedCNs) {
            if (cn.subject == "logout" || cn.subject == "login_credentials") {
                QXLOG_SUPPORT("Processing received with priority subject CN(%d, %s)", savedId, cn.subject.c_str());
                process(cn);
                priorityBreak = true;
                break;
            } else {
                unprocessedCNs.push_back(cn);
            }
        }
        if (m_dontLoadNextFromDatabaseReason == STR_PROCESSING_PRIORITY_TYPE_CNS_FIRST) {
            // Clear the flag only if not set too by some of the just processed CNs
            setDontLoadNextFromDatabase(false, "");
        }

        if (!priorityBreak) {
            receivedCNs.swap(unprocessedCNs);
            unprocessedCNs.clear();

            QXLOG_SUPPORT("There are %d unprocessed just received CNs, processing first one from db", receivedCNs.size());
            processOne();
        }
    }
}

void ChangeNotificationProcessor::onProcessingFinished(int databaseId, int networkOrHttpStatus)
{
    QXLOG_SUPPORT("Processing of CN(%d) finished with code: %d", databaseId, networkOrHttpStatus);
    m_outstandingIds.erase(databaseId);

    if (networkOrHttpStatus == 0 || networkOrHttpStatus == 200) {
        ChangeNotificationDao::remove(databaseId);
        if (m_dontLoadNextFromDatabase) {
            QXLOG_SUPPORT("Loading next CN from db is disabled with reason: %s", m_dontLoadNextFromDatabaseReason.c_str());
        } else {
            QXLOG_SUPPORT("Attempting to process any pending CN", nullptr);
            processOne();
        }
    } else {
        ChangeNotificationDao::updateErrorCode(databaseId, networkOrHttpStatus);
    }
}

void ChangeNotificationProcessor::processOne(int sinceId)
{
    std::string where;
    dao::Query q;
    if (!m_outstandingIds.empty()) {
        where = ChangeNotificationDao::columnNames[ChangeNotificationDao::IdColumn] +
            " NOT IN (";
        int i = 0;
        for (int id: m_outstandingIds) {
            if (i++ > 0) {
                where += ", ";
            }
            where += std::to_string(id);
        }
        where += ")";
    }
    if (sinceId > 0) {
        if (!where.empty()) {
            where += " AND ";
        }
        where += ChangeNotificationDao::columnNames[ChangeNotificationDao::IdColumn];
        where += " > ";
        where += std::to_string(sinceId);
    }
    if (!where.empty()) {
        q.appendCustomWhere(where);
    }
    q.appendOrder(ChangeNotificationDao::IdColumn);

    ChangeNotification cn = ChangeNotificationDao::selectOne(q);
    if (cn.isEmpty()) {
        QXLOG_SUPPORT("No pending CNs matching: %s", where.c_str());
    } else {
        process(cn);
    }
}

void ChangeNotificationProcessor::setDontLoadNextFromDatabase(bool dontLoad, const char *reason)
{
    QXLOG_SUPPORT("%s loading of next CN from database because of reason: %s", (dontLoad ? "Disabling" : "Enabling"), reason);
    m_dontLoadNextFromDatabase = dontLoad;
    if (dontLoad) {
        m_dontLoadNextFromDatabaseReason = reason;
    } else {
        m_dontLoadNextFromDatabaseReason = "";
    }
}
    
void ChangeNotificationProcessor::setDeviceUuid(const std::string &deviceUuid)
{
    m_deviceUuid = deviceUuid;
}

void ChangeNotificationProcessor::setListener(ChangeNotificationListener *listener)
{
    m_listener = listener;
}

int ChangeNotificationProcessor::saveChangeNotification(const json &messageJson, ChangeNotification *cn)
{
    int ret = 0;
    try {
        cn->clear();
        cn->subject = messageJson.at("Subject").get<std::string>();
        auto data = messageJson.at("Data");
        if (data.count("qliq_id") > 0) {
            cn->qliqId = data.at("qliq_id").get<std::string>();
        }
        cn->hasPayload = (data.count("payload") > 0);
        cn->json = data.dump();

        bool ignore = false;
        if (!m_deviceUuid.empty() && data.count("device_uuid") > 0) {
            std::string deviceUuid = data.at("device_uuid").get<std::string>();
            if (!deviceUuid.empty() && deviceUuid != m_deviceUuid) {
                QXLOG_WARN("Ignoring CN(%s) for a different device: %s, my device: %s",
                           cn->subject.c_str(), deviceUuid.c_str(), m_deviceUuid.c_str());
                ignore = true;
            }
        }
        if (!ignore) {
            ret = ChangeNotificationDao::insert(cn);
        }
#ifdef QXL_HAS_CN_LOG
        if (LogDatabase::isChangeNotificationEnabled()) {
            if (LogDatabase::isDefaultInstanceOpen()) {
                ChangeNotificationLogRecord r;
                r.session = qxlog::Logger::instance().sessionId();
                r.sequenceId = qxlog::Logger::instance().nextSequenceId();
                r.time = std::time(nullptr);

                r.subject = cn->subject;
                r.qliqId = cn->qliqId;
                r.json = data.dump();

                try {
                    if (r.subject == "presence") {
                        r.feature = data.at("payload").at("presence_status").get<std::string>();
                    } else if (r.subject == "user" || (r.subject.find("group") != std::string::npos)) {
                        r.feature = data.at("operation").get<std::string>();
                    }
                } catch (const std::out_of_range& ex) {
                    QXLOG_ERROR("Error processing CN feature for db log: %s", ex.what());
                }
                ChangeNotificationLogDao::insert(&r, LogDatabase::database());
                m_listener->onChangeNotificationSaved(r.id);

            } else {
                QXLOG_ERROR("Cannot log CN becasue log db is not open", nullptr);
            }
        }
#endif
        return ret;
    } catch (const std::out_of_range& ex) {
        QXLOG_ERROR("Error processing CN json: %s", ex.what());
        return ret;
    }
}

void ChangeNotificationProcessor::process(ChangeNotification &cn)
{
    m_outstandingIds.insert(cn.databaseId);
//        auto data = nlohmann::json::parse(cn.json);
//        data.erase("payload");
//        cn.json = data.dump();
    QXLOG_SUPPORT("Processing CN(%d, %s, %s)", cn.databaseId, cn.subject.c_str(), cn.qliqId.c_str());
#if !defined(NO_GUI) && defined(QXL_DEVICE_PC)
    if (cn.subject == "presence") {
        processPresence(cn);
    } else
#endif
#ifndef NO_GUI
    if (cn.subject == "fax_contacts") {
        processFaxContacts(cn);
    } else
#endif
    if (!m_listener->onChangeNotificationReceived(cn.databaseId, cn.subject, cn.qliqId, cn.json)) {
        // Unsupported CN must be confirmed anyway so it doesn't dangle in db forever
        QXLOG_ERROR("Unsupported CN subject: '%s' marking as finished anyway", cn.subject.c_str());
        onProcessingFinished(cn.databaseId, 0);
    }
}

#ifndef NO_GUI

void ChangeNotificationProcessor::processFaxContacts(ChangeNotification &cn)
{
    const int cnId = cn.databaseId;
    web::GetFaxContactsWebService().call([this,cnId](const web::QliqWebError& error) {
        onProcessingFinished(cnId, error.networkErrorOrHttpStatus);
    });
}

#endif // !NO_GUI

#if !defined(NO_GUI) && defined(QXL_DEVICE_PC)

void ChangeNotificationProcessor::processPresence(ChangeNotification &cn)
{
    if (cn.hasPayload) {
        std::string err;
        auto j11 = json11::Json::parse(cn.json, err);
        qx::Presence presence;
        web::GetPresenceStatusWebService::processPresenceData(j11["payload"], "", &presence);
        onProcessingFinished(cn.databaseId, 0);
    } else {
        int cnId = cn.databaseId;
        web::GetPresenceStatusWebService().call(cn.qliqId, [this,cnId](const web::QliqWebError& error, const Presence& presence) {
            onProcessingFinished(cnId, error.networkErrorOrHttpStatus);
        });
    }
}

#endif // !defined(NO_GUI) && defined(QXL_DEVICE_PC)

bool ChangeNotificationProcessor::OutstandingChangeNotification::isEmpty() const
{
    return subject.empty();
}

void ChangeNotificationProcessor::OutstandingChangeNotification::clear()
{
    subject.clear();
    qliqId.clear();
}

ChangeNotificationListener::~ChangeNotificationListener()
{
}

void ChangeNotificationListener::onChangeNotificationSaved(int)
{
}

} // qx

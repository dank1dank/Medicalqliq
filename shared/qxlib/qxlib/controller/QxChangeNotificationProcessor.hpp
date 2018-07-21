#ifndef QX_CHANGENOTIFICATIONPROCESSOR_HPP
#define QX_CHANGENOTIFICATIONPROCESSOR_HPP
#include <string>
#include <set>
#include "qxlib/model/QxSessionListener.hpp"
#include "qxlib/util/QxNetworkMonitor.hpp"

class json;

namespace qx {

class ChangeNotification;

class ChangeNotificationListener {
public:
    virtual ~ChangeNotificationListener();
    virtual void onChangeNotificationSaved(int databaseId);
    virtual bool onChangeNotificationReceived(int databaseId,
                                              const std::string& subject,
                                              const std::string& qliqId,
                                              const std::string& data) = 0;
};

class ChangeNotificationProcessor : public SessionListener, public NetworkListener
{
public:
    ChangeNotificationProcessor(std::string deviceUuid = std::string());
    virtual ~ChangeNotificationProcessor();

    void onSessionStarted() override;
    void onSessionFinishing() override;
    void onForegroundStatusChanged(bool isForegroundApp) override;
    void onNetworkChanged(bool isOnline) override;
    // TODO:
    // void onTimerTimedOut(int id);

    void setDeviceUuid(const std::string& deviceUuid);
    void setListener(ChangeNotificationListener *listener);

    void onSipMessage(const std::string& json);
    void onProcessingFinished(int databaseId, int networkOrHttpStatus);

    void processOne(int sinceId = 0);
    
    void setDontLoadNextFromDatabase(bool dontLoad, const char *reason);

private:
    int saveChangeNotification(const json& messageJson, ChangeNotification *cn);
    void process(ChangeNotification& cn);
    void processPresence(ChangeNotification& cn);
    void processFaxContacts(ChangeNotification& cn);

    struct OutstandingChangeNotification {
        std::string subject;
        std::string qliqId;

        bool isEmpty() const;
        void clear();
    };

    ChangeNotificationListener *m_listener;
    std::set<int> m_outstandingIds;
    bool m_dontLoadNextFromDatabase;
    std::string m_dontLoadNextFromDatabaseReason;
    std::string m_deviceUuid;
};

} // qx

#endif // QX_CHANGENOTIFICATIONPROCESSOR_HPP

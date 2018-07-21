//
//  QxPlatfromIOS.m
//  qliq
//
//  Created by Adam Sowa on 09/05/16.
//
//

#import "QxPlatfromIOS.h"
#import "QxPlatfromIOSHelpers.h"
#import "DDLog.h"
#import "RestClient.h"
#import "Crypto.h"
#import "UIDevice+UUID.h"
#import "QliqReachability.h"
#import "JSONKit.h"
#import "QliqSip.h"
#include "qxlib/controller/QxApplication.hpp"
#include "qxlib/db/QxDatabase.hpp"
#include "qxlib/db/QxLogDatabase.hpp"
#include "qxlib/model/QxSession.hpp"
#include "qxlib/model/fhir/FhirProcessor.hpp"
#include "qxlib/controller/QxMediaFileManager.hpp"
#define QX_SEARCH_PATIENTS_IMPL_READY
#ifdef QX_SEARCH_PATIENTS_IMPL_READY
#include "qxlib/crypto/QxCrypto.hpp"
#include "qxlib/web/QxWebClient.hpp"
#endif
#include "qxlib/util/QxNetworkMonitor.hpp"
#include "qxlib/log/web/QxWebLogRecordDao.hpp"
#include "qxlib/model/sip/QxSip.hpp"
#include "qxlib/util/QxSettings.hpp"
#include "qxlib/log/push/QxPushNotificationLogRecordDao.hpp"

enum Level {
    TraceLevel = 0,
    DebugLevel,
    InfoLevel,
    WarnLevel,
    SupportLevel,
    ErrorLevel,
    FatalLevel,
    OffLevel
};

DDLogLevel qxlevelToDDLevel(int qxLevel)
{
    switch (qxLevel) {
        case TraceLevel:
            return DDLogLevelAll;
        case DebugLevel:
            return DDLogLevelDebug;
        case InfoLevel:
            return DDLogLevelInfo;
        case WarnLevel:
            return DDLogLevelWarning;
        case SupportLevel: // TODO: check how we implement support level on ios
            return DDLogLevelWarning;
        case ErrorLevel:
            return DDLogLevelError;
        case FatalLevel:
            return DDLogLevelError;
        case OffLevel:
            return DDLogLevelOff;
        default:
            return DDLogLevelError;
    }
}

/*
 #define LOG_FLAG_ERROR      (1 << 0)  // 0...00001
 #define LOG_FLAG_WARN       (1 << 1)  // 0...00010
 #define LOG_FLAG_SUPPORT    (1 << 2)  // 0...00100
 #define LOG_FLAG_INFO       (1 << 3)  // 0...01000
 #define LOG_FLAG_DEBUG      (1 << 4)  // 0...10000
 #define LOG_FLAG_VERBOSE    (1 << 5)  // 0..100000
 */

DDLogFlag qxlevelToDDFlag(int qxLevel)
{
    switch (qxLevel) {
        case TraceLevel:
        case DebugLevel:
        case OffLevel:
            return LOG_FLAG_DEBUG;
        case InfoLevel:
            return LOG_FLAG_INFO;
        case WarnLevel:
            return LOG_FLAG_WARN;
        case SupportLevel:
            return LOG_FLAG_SUPPORT;
        case ErrorLevel:
        case FatalLevel:
        default:
            return LOG_FLAG_ERROR;
    }
}

void qxlog_implementation_log(int qxLevel, const char *file, unsigned int line, const char *format, va_list args)
{
    //DDLogLevel ddLevel = qxlevelToDDLevel(qxLevel);
    DDLogFlag flag = qxlevelToDDFlag(qxLevel);
    NSInteger context = 0;
    BOOL asynchronous = YES;
    const char *function = __FUNCTION__;
    
    [DDLog log:asynchronous
         level:LOG_LEVEL_DEF
          flag:flag
       context:context
          file:file
      function:function
          line:line
           tag:nil
        format:[NSString stringWithUTF8String:format]
          args:args];
}

#ifdef QX_SEARCH_PATIENTS_IMPL_READY

std::string qx_filesystem_temporaryDirPath_impl()
{
    return qx::toStdString(NSTemporaryDirectory());
}

std::string qx_FileInfo_mime_impl(const std::string& path)
{
    // TODO
    return "";
}

std::string qx_Session_dataDirectoryRootPath_impl()
{
    NSString *documentsRootPath =  [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByDeletingLastPathComponent];
    return qx::toStdString([documentsRootPath stringByAppendingString:@"/Documents"]);
}

std::string qx_sip_last_message_plain_text_body_impl(const std::string& callId)
{
    if ([QliqSip sharedQliqSip]) {
        return qx::toStdString([[QliqSip sharedQliqSip] getLastSentMessagePlainTextBody:qx::toNSString(callId)]);
    } else {
        return "";
    }
}

/////////////////////////////////////////////////////////////////////////////////////////
// WebClient
//
namespace qx {
namespace web {

    class WebClientImpl : public WebClient {
public:
    WebClientImpl(RestClient *restClient) :
        m_restClient(restClient)
    {}
    
    void postJsonRequest(ServerType serverType, const std::string& serverPath, const json11::Json& json, JsonCallback callback, const std::string& downloadFilePath = {}, const std::string& downloadUuid = {},  IsCancelledFunction isCancelledFun = {}) override
    {
        NSMutableDictionary *jsonDict = dictWithCommonFields(json);
       
        if (downloadFilePath.empty()) {
            [m_restClient postDataToServer:(WebServerType)serverType path:toNSString(serverPath) jsonToPost:jsonDict onCompletion:^(NSString *responseBody) {
                handlePostJsonResponse(0, "", 200, toStdString(responseBody), callback, isCancelledFun);
            } onError:^(NSError *error) {
                handleError(error, callback, isCancelledFun);
            }];
        } else {
            [m_restClient downloader:(WebServerType)serverType path:toNSString(serverPath) jsonToPost:jsonDict toFile:toNSString(downloadFilePath) onCompletion:^(NSString *responseBody) {
                handlePostJsonResponse(0, "", 200, toStdString(responseBody), callback, isCancelledFun);
            } onError:^(NSError *error) {
                handleError(error, callback, isCancelledFun);
            }];
        }
    }
        
    /// JSON request to any webserver (url based), response is original parsed JSON
    void postJsonRequestToUrl(const std::string& url, const json11::Json& json, const std::map<std::string, std::string>& extraHeaders,
                              JsonCallback callback, IsCancelledFunction isCancelledFun = IsCancelledFunction()) override
    {
        // TODO: implement support for external webservers (non-qliq), this is not used on iphone at this point yet
        DDLogError(@"BUG: Method not yet implemented: WebClientImpl::postJsonRequestToUrl");
    }

    void jsonRequestToUrl(HttpMethod method, const std::string& url, const json11::Json& json, const std::map<std::string, std::string>& extraHeaders,
                          JsonCallback callback, IsCancelledFunction isCancelledFun = IsCancelledFunction()) override
    {
        DDLogError(@"BUG: Method not yet implemented: WebClientImpl::jsonRequestToUrl");
    }
        
    virtual void postMultipartRequest(ServerType serverType, const std::string& serverPath, const json11::Json& json,
                                      const std::string& fileMimeType, const std::string& fileName, const std::string& filePath,
                                      JsonCallback callback, IsCancelledFunction isCancelledFun = IsCancelledFunction()) override
    {
        NSMutableDictionary *jsonDict = dictWithCommonFields(json);
        
        [m_restClient uploader:(WebServerType)serverType path:toNSString(serverPath) jsonToPost:jsonDict filePath:toNSString(filePath) fileName:toNSString(fileName) onCompletion:^(NSString *responseBody) {
            handlePostJsonResponse(0, "", 200, toStdString(responseBody), callback, isCancelledFun);
        } onError:^(NSError *error) {
            handleError(error, callback, isCancelledFun);
        }];
    }
        
    /// Request to any webserver (url based) with a parsed JSON response
    void getJsonUrl(const std::string& url, const std::map<std::string, std::string>& extraHeaders,
                    JsonCallback callback, IsCancelledFunction isCancelledFun = IsCancelledFunction()) override
    {
        // TODO: implement support for external webservers (non-qliq), this is not used on iphone at this point yet
        DDLogError(@"BUG: Method not yet implemented: WebClientImpl::getJsonUrl");
    }
    
private:
    void handleError(NSError *error, const  JsonCallback& callback, const IsCancelledFunction& isCancelledFun)
    {
        int networkCode = (int)error.code;
        int httpStatus = 0;
        if (error.domain == NSURLErrorDomain) {
            networkCode = 0;
            httpStatus = (int)error.code;
        }
        handlePostJsonResponse(networkCode, toStdString(error.localizedDescription), httpStatus, "", callback, isCancelledFun);
    }
    
    NSMutableDictionary *dictWithCommonFields(const json11::Json& json)
    {
        NSMutableDictionary *jsonDict = toNSDictionary(json);
        NSString *username      = [UserSessionService currentUserSession].sipAccountSettings.username;
        NSString *password      = [UserSessionService currentUserSession].sipAccountSettings.password;
        NSString *deviceUUID    = [[UIDevice currentDevice] qliqUUID];
        [jsonDict setObject:username   forKey:@"username"];
        [jsonDict setObject:password   forKey:@"password"];
        [jsonDict setObject:deviceUUID forKey:@"device_uuid"];
        return jsonDict;
    }
        
    RestClient *m_restClient;
};

} // web
    
///////////////////////////////////////////////////////////////////////////////
// Settings
//
struct Settings::Private {
};

Settings::Settings()
{
}

Settings::~Settings()
{
}
    
void Settings::setValue(const std::string &key, const std::string &value)
{
    [[NSUserDefaults standardUserDefaults] setObject:toNSString(value) forKey:toNSString(key)];
}

std::string Settings::valueAsString(const std::string &key, const std::string &defaultValue) const
{
    id value = [[NSUserDefaults standardUserDefaults] objectForKey:toNSString(key)];
    if ([value isKindOfClass:[NSString class]]) {
        NSString *str = (NSString *)value;
        return toStdString(str);
    } else {
        return defaultValue;
    }
}

bool Settings::contains(const std::string &key) const
{
    return ([[NSUserDefaults standardUserDefaults] objectForKey:toNSString(key)] != nil);
}
    
void Settings::remove(const std::string &key)
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:toNSString(key)];
}

} // qx

// Static session objects
namespace {
    QxPlatfromIOS *s_instance = nullptr;
    qx::web::WebClientImpl *s_webClient = nullptr;
    qx::NetworkMonitor *s_networkMonitor = nullptr;
    qx::Application s_application;
} // anon namespace

#endif // #ifdef QX_SEARCH_PATIENTS_IMPL_READY

@interface QxPlatfromIOS()

+ (void) reachabilityChanged:(NSNotification*)notification;
+ (BOOL) openLogDatabase;
+ (int) nextRequestId;

@end

@implementation QxPlatfromIOS

+ (BOOL) openDatabase:(NSString *)path withKey:(NSString *)key
{
    [self closeDatabase];
    bool ret = QxDatabase::openDefaultInstance([path UTF8String], [key UTF8String]);
    if (ret) {
        [self openLogDatabase];
        qx::LogConfig::load();
        s_application.onDatabaseOpened();
    }
    return ret;
}

+ (BOOL) openLogDatabase
{
    if (qx::LogDatabase::instance()) {
        DDLogWarn(@"qx::LogDatabase is already open, deleting existing instance");
        delete qx::LogDatabase::instance();
    }
    
    DDLogSupport(@"Opening qx::LogDatabase");
    qx::LogDatabase *logDb = new qx::LogDatabase();
    bool ret = logDb->openNextToDefaultDatabase();
    if (ret) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
        NSError *error = nil;
        std::vector<std::string> logDbUpdateFiles;
        for (NSString *file in [fileManager contentsOfDirectoryAtPath:resourcePath error:&error]) {
            if ([file hasPrefix:@"database-"] && [file hasSuffix:@".sql"]) {
                logDbUpdateFiles.push_back([[resourcePath stringByAppendingPathComponent:file] UTF8String]);
            }
        }
        ret = logDb->update(logDbUpdateFiles.data(), logDbUpdateFiles.size(), [](const std::string& fileName) -> std::string {
            NSError *error = nil;
            NSString *sql = [[NSString alloc] initWithContentsOfFile:qx::toNSString(fileName) encoding:NSUTF8StringEncoding error:&error];
            return [sql UTF8String];
        });
    }

    return ret;
}

+ (void) closeDatabase
{
    QxDatabase::deleteDefaultInstance();

    if (qx::LogDatabase::instance()) {
        delete qx::LogDatabase::instance();
    }
}

#ifdef QX_SEARCH_PATIENTS_IMPL_READY

+ (void) onUserSessionStarted
{
    DDLogSupport(@"qxlib user session started");
    if (!s_instance) {
        s_instance = [[QxPlatfromIOS alloc] init];
    
        s_networkMonitor = new qx::NetworkMonitor();
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:QliqReachabilityChangedNotification object:nil];
    
        s_webClient = new qx::web::WebClientImpl([RestClient clientForCurrentUser]);
        qx::web::WebClient::setDefaultInstance(s_webClient);
    }
    
    auto crypto = qx::Crypto::instance();
    if (!crypto) {
        crypto = new qx::Crypto();
        qx::Crypto::setInstance(crypto);
    }
    
    auto sip = qx::Sip::instance();
    if (!sip) {
        sip = new qx::Sip();
        // it will setup itself as the instance
    }
    
    QliqUser *myUser = [UserSessionService currentUserSession].user;
    qx::Session& session = qx::Session::instance();
    session.setMyQliqId(qx::toStdString(myUser.qliqId));
    session.setMyEmail(qx::toStdString(myUser.email));
    session.setMyDisplayName(qx::toStdString(myUser.displayName));
    session.setDeviceName(qx::toStdStringAsciiOnly([[UIDevice currentDevice] name]));
    
    session.notifySessionStarted();
    qx::MediaFileManager::onUserSessionStarted();
}

+ (void) onUserSessionFinishing
{
    qx::Session::instance().notifySessionFinishing();
}

+ (void) onUserSessionFinished
{
    DDLogSupport(@"qxlib user session finished");
    qx::web::WebClient::setDefaultInstance(nullptr);
    delete s_webClient;
    s_webClient = nullptr;

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    delete s_networkMonitor;
    s_networkMonitor = nullptr;
    
    delete qx::Sip::instance();
    
    s_instance = nullptr;
    
    // TODO: iPhone does not clear Crypto.m on logout
    // so we must keep it also
//    auto crypto = qx::Crypto::defaultInstance();
//    if (crypto) {
//        qx::Crypto::setDefaultInstance(nullptr);
//        delete crypto;
//    }
}

+ (BOOL) isUserSessionStarted
{
    return (qx::Crypto::instance() != nullptr);
}

+ (void) setMyUser:(QliqUser *)myUser
{
    qx::Session& session = qx::Session::instance();
    session.setMyQliqId(qx::toStdString(myUser.qliqId));
    session.setMyEmail(qx::toStdString(myUser.email));
    session.setMyDisplayName(qx::toStdString(myUser.displayName));
    session.setDeviceName(qx::toStdStringAsciiOnly([[UIDevice currentDevice] name]));
}

+ (void) setKeyPair:(void *)pubKey publicKeyString:(NSString *)publicKeyString privateKey:(void *)privKey
{
    auto crypto = qx::Crypto::instance();
    if (!crypto) {
        crypto = new qx::Crypto();
        qx::Crypto::setInstance(crypto);
    }
    
    crypto->setKeys((evp_pkey_st *)pubKey, qx::toStdString(publicKeyString), (evp_pkey_st *)privKey);
}

#endif // #ifdef QX_SEARCH_PATIENTS_IMPL_READY

+ (BOOL) processFhirAttachment:(NSString *)json
{
    return FhirProcessor::processFhirAttachment([json UTF8String]);
}

+ (void) reachabilityChanged:(NSNotification *)notification
{
    
    BOOL isOnline = [[QliqReachability sharedInstance] restReachable];
    if (s_networkMonitor) {
        s_networkMonitor->notifyNetworkChanged(isOnline);
    }
}

+ (int) maybeLogWebRequestMethod:(NSString *)httpMethod url:(NSString *)url json:(NSDictionary *)jsonDict
{
    int requestId = 0;
    if (qx::LogDatabase::isWebEnabled()) {
        qx::WebLogRecord::HttpMethod qxMethod = qx::WebLogRecord::NoneHttpMethod;
        if ([httpMethod isEqualToString:@"GET"]) {
            qxMethod = qx::WebLogRecord::GetHttpMethod;
        } else if ([httpMethod isEqualToString:@"POST"]) {
            qxMethod = qx::WebLogRecord::PostHttpMethod;
        } else if ([httpMethod isEqualToString:@"PUT"]) {
            qxMethod = qx::WebLogRecord::PutHttpMethod;
        } else if ([httpMethod isEqualToString:@"DELETE"]) {
            qxMethod = qx::WebLogRecord::DeleteHttpMethod;
        }
        int module = 0;
        const char *urlString = [url UTF8String];
        const char *jsonString = [[jsonDict JSONString] UTF8String];
        if (jsonString == nil) {
            jsonString = "";
        }
        
        if (qx::LogDatabase::isDefaultInstanceOpen()) {
            requestId = qx::WebLogRecordDao::insertRequest(module, qxMethod, urlString, jsonString);
        } else {
            requestId = [self nextRequestId];
            qx::WebLogRecordDao::insertRequestToQueue(requestId, module, qxMethod, urlString, jsonString);
        }
    } else {
        // When logdb is disabled we still want unique ids for DDLogSupport entries
        requestId = [self nextRequestId];
    }
    return requestId;
}

+ (void) maybeUpdateWebResponseWithId:(int)requestId duration:(int)duration responseCode:(int)responseCode jsonError:(int)jsonError response:(NSString *)response
{
    if (qx::LogDatabase::isWebEnabled()) {
        const char *responseString = [response UTF8String];
        if (responseString == nil) {
            responseString = "";
        }
        if (qx::LogDatabase::isDefaultInstanceOpen()) {
            qx::WebLogRecordDao::updateResponse(requestId, duration, responseCode, jsonError, responseString);
        } else {
            qx::WebLogRecordDao::updateResponseInQueue(requestId, duration, responseCode, jsonError, responseString);
        }
    }
}

+ (void) maybeUpdateWebResponseJsonErrorWithId:(int)requestId jsonError:(int)jsonError
{
    if (qx::LogDatabase::isWebEnabled()) {
        if (qx::LogDatabase::isDefaultInstanceOpen()) {
            qx::WebLogRecordDao::updateJsonError(requestId, jsonError);
        } else {
            qx::WebLogRecordDao::updateJsonErrorInQueue(requestId, jsonError);
        }
    }
}

+ (int) nextRequestId
{
    @synchronized(self) {
        static int seq = 0;
        return --seq;
    }
}

+ (BOOL) decryptDatabase:(NSString *)encryptedPath to:(NSString *)decryptedPath withKey:(NSString *)key
{
    std::string errorMsg = QxDatabase::decryptDatabaseToPlaintext(qx::toStdString(encryptedPath), qx::toStdString(decryptedPath), qx::toStdString(key));
    return errorMsg.empty();
}

+ (void) savePushNotificationToLogDatabase:(NSDictionary *)apns
{
    NSString *body = [apns JSONString];
    NSString *callId = [apns valueForKey:@"call_id"];
    qx::PushNotificationLogRecordDao::insertToDatabaseOrQueue(qx::toStdString(body), qx::toStdString(callId));
}

@end

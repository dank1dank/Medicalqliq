#include <jni.h>
#include <string>
#include <iostream>
#include <stdexcept>
#include <android/log.h>
#include "qxlib/log/QxLog.hpp"
#include "qxlib/web/QxWebClient.hpp"
#include "qxlib/model/QxSession.hpp"
#include "qxlib/crypto/QxCrypto.hpp"
#include "qxlib/db/QxDatabase.hpp"
#include "qxlib/util/QxNetworkMonitor.hpp"
#include "qxlib/util/QxTerminateHandler.hpp"

#define APPNAME "qxlib"

namespace {
    JavaVM *s_jvm = nullptr;

JNIEnv *getJavaEnv()
{
    JNIEnv *env = nullptr;
    if (s_jvm) {
        int status = s_jvm->GetEnv((void **) &env, JNI_VERSION_1_6);
        if (status == JNI_EDETACHED) {
            if (s_jvm->AttachCurrentThread(&env, NULL) != 0) {
                std::cerr << "Failed to attach" << std::endl;
            }
        }
    } else {
        __android_log_print(ANDROID_LOG_FATAL, APPNAME, "getJavaEnv() s_jvm is null");
    }

    return env;
}

void clearAndLogJvmException(JNIEnv *env, const char *javaMethodName)
{
    jboolean flag = env->ExceptionCheck();
    if (flag == JNI_TRUE) {
        __android_log_print(ANDROID_LOG_FATAL, APPNAME, "Exception occured while calling %s", javaMethodName);
        env->ExceptionDescribe();
        env->ExceptionClear();
    }
}

} // namespace

////////////////////////////////////////////////////////////////////////////////////////////////////
// Logging
//
#define LOGV() __android_log_print(ANDROID_LOG_VERBOSE, APPNAME, "My Log", 1);
#define NDK_LOG_E(fmt, ...) __android_log_print(ANDROID_LOG_ERROR, APPNAME, fmt, args);
#define NDK_LOG_F(fmt, ...) __android_log_print(ANDROID_LOG_FATAL, APPNAME, fmt, args);

namespace {
    jclass s_com_qliqsoft_utils_LogClass = nullptr;
    jmethodID s_qliqsoft_utils_log_LogMethod = nullptr;

void resolveQliqsoftJavaLogger(JNIEnv *env)
{
    jclass cls = env->FindClass("com/qliqsoft/utils/Log");
    if (!cls) {
        __android_log_write(ANDROID_LOG_ERROR, APPNAME, "Could not find the com.qliqsoft.utils.Log class");
    } else {
        s_com_qliqsoft_utils_LogClass = reinterpret_cast<jclass>(env->NewGlobalRef(cls));

        s_qliqsoft_utils_log_LogMethod = env->GetStaticMethodID(cls, "qxlibLog", "(ILjava/lang/String;)V");
        if (!s_qliqsoft_utils_log_LogMethod) {
            __android_log_write(ANDROID_LOG_ERROR, APPNAME, "Could not find the \"static void qxlibLog(int priority, String message)\" method");
        } else {
            __android_log_write(ANDROID_LOG_INFO, APPNAME, "Resolved com.qliqsoft.utils.Log logger");
        }
    }

    clearAndLogJvmException(env, "resolveQliqsoftJavaLogger");
}

int qxLogLevelToAndroidLogLevel(int qxLevel)
{
    int androidPriority = ANDROID_LOG_DEFAULT;
    switch (qxLevel) {
        case qxlog::TraceLevel:
            androidPriority = ANDROID_LOG_VERBOSE;
            break;
        case qxlog::DebugLevel:
            androidPriority = ANDROID_LOG_DEBUG;
            break;
        case qxlog::InfoLevel:
            androidPriority = ANDROID_LOG_INFO;
            break;
        case qxlog::WarnLevel:
            androidPriority = ANDROID_LOG_WARN;
            break;
        case qxlog::SupportLevel:
            androidPriority = ANDROID_LOG_INFO;
            break;
        case qxlog::ErrorLevel:
            androidPriority = ANDROID_LOG_ERROR;
            break;
        case qxlog::FatalLevel:
            androidPriority = ANDROID_LOG_FATAL;
            break;
        case qxlog::OffLevel:
            androidPriority = ANDROID_LOG_SILENT;
            break;
    }
    return androidPriority;
}

void qxlog_implementation_qliqsoft(int qxLevel, const char *file, unsigned int line, const char *format, va_list args)
{
//    __android_log_write(ANDROID_LOG_DEBUG, APPNAME, "qxlog_implementation_qliqsoft() entered");
    auto env = getJavaEnv();

    char buffer[256] = {0};
    int ret = vsnprintf(buffer, sizeof(buffer), format, args);
    if (ret < 0) {
        snprintf(buffer, sizeof(buffer), "vsnprintf error for format: \"%s\"", format);
    }

    std::string message;
    message.reserve(strlen(file) + 12 + strlen(buffer));
    message.append(file);
    message.push_back(':');
    message.append(std::to_string(line));
    message.push_back(' ');
    message.append(buffer);

    jstring jmessage = env->NewStringUTF(message.c_str());
    int level = qxLogLevelToAndroidLogLevel(qxLevel);

    env->CallStaticVoidMethod(s_com_qliqsoft_utils_LogClass, s_qliqsoft_utils_log_LogMethod, level, jmessage);
    clearAndLogJvmException(env, "com.qliqsoft.utils.Log.qxlibLog(int priority, String message)");
//    __android_log_write(ANDROID_LOG_DEBUG, APPNAME, "qxlog_implementation_qliqsoft() exited");
}

void qxlog_implementation_logcat(int qxLevel, const char *file, unsigned int line, const char *format, va_list args)
{
    std::string finalFormat;
    finalFormat.reserve(std::strlen(format) + strlen(file) + 10);
    finalFormat.append(file);
    finalFormat.push_back(':');
    finalFormat.append(std::to_string(line));
    finalFormat.push_back(' ');
    finalFormat.append(format);

    int androidPriority = qxLogLevelToAndroidLogLevel(qxLevel);

    __android_log_vprint(androidPriority, APPNAME, finalFormat.c_str(), args);
}

} // namespace

void qxlog_implementation_log(int qxLevel, const char *file, unsigned int line, const char *format, va_list args)
{
    if (s_qliqsoft_utils_log_LogMethod) {
        qxlog_implementation_qliqsoft(qxLevel, file, line, format, args);
    } else {
        qxlog_implementation_logcat(qxLevel, file, line, format, args);
    }
}

/////////////////////////////////////////////////////////////////////////////////////////
// WebClient
//
namespace qx {
    namespace web {

        class WebClientImpl : public WebClient {
        public:
            WebClientImpl(JNIEnv *env, jobject javaWebClient) :
                m_javaWebClient(nullptr), m_javaWebClientClass(nullptr)
            {
                resolveJavaMethods(env, javaWebClient);
            }

            ~WebClientImpl()
            {
                auto env = getJavaEnv();
                if (m_javaWebClient) {
                    env->DeleteGlobalRef(m_javaWebClient);
                }
                if (m_javaWebClientClass) {
                    env->DeleteGlobalRef(m_javaWebClientClass);
                }
            }

            json11::Json addCommonRequestFields(const json11::Json& jsonArg)
            {
                json11::Json::object json = jsonArg.object_items();
                const auto& session = qx::Session::instance();
                json["username"] = session.userName();
                json["password"] = session.passwordWeb();
                json["device_uuid"] = session.deviceName();
                return json;
            }

            struct RequestContext {
                JsonCallback callback;
                IsCancelledFunction isCancelledFun;
                bool isFileDownload;

                RequestContext()
                {}

                RequestContext(const JsonCallback& callback, IsCancelledFunction& isCancelledFun, bool isFileDownload) :
                    callback(callback), isCancelledFun(isCancelledFun), isFileDownload(isFileDownload)
                {}
            };

            void postJsonRequest(ServerType serverType, const std::string& serverPath, const json11::Json& jsonArg, JsonCallback callback, const std::string& downloadFilePath = {}, IsCancelledFunction isCancelledFun = {}) override
            {
                auto env = getJavaEnv();
                json11::Json json = addCommonRequestFields(jsonArg);
                jshort jserverType = (jshort)serverType;
                jstring jserverPath = env->NewStringUTF(serverPath.c_str());
                jstring jjsonString = env->NewStringUTF(json.dump().c_str());
                jstring jdownloadFilePath = env->NewStringUTF(downloadFilePath.c_str());

                bool isFileDownload = !downloadFilePath.empty();
                jlong nativeCallbackObject = reinterpret_cast<jlong>(this);
                jlong nativeContext = reinterpret_cast<jlong>(new RequestContext(callback, isCancelledFun, isFileDownload));

                env->CallVoidMethod(m_javaWebClient, m_postJsonRequestMethod, jserverType, jserverPath, jjsonString, jdownloadFilePath, nativeCallbackObject, nativeContext);
                clearAndLogJvmException(env, "com.qliqsoft.qx.web.JavaAndroidWebClient.postJsonRequest()");
            }

            virtual void postMultipartRequest(ServerType serverType, const std::string& serverPath, const json11::Json& jsonArg,
                                              const std::string& fileMimeType, const std::string& fileName, const std::string& filePath,
                                              JsonCallback callback, IsCancelledFunction isCancelledFun = IsCancelledFunction()) override
            {
                auto env = getJavaEnv();
                json11::Json json = addCommonRequestFields(jsonArg);
                jshort jserverType = (jshort)serverType;
                jstring jserverPath = env->NewStringUTF(serverPath.c_str());
                jstring jjsonString = env->NewStringUTF(json.dump().c_str());
                jstring jfileMimeType = env->NewStringUTF(fileMimeType.c_str());
                jstring jfileName = env->NewStringUTF(fileName.c_str());
                jstring jfilePath = env->NewStringUTF(filePath.c_str());
                jlong nativeCallbackObject = reinterpret_cast<jlong>(this);
                jlong nativeContext = reinterpret_cast<jlong>(new RequestContext(callback, isCancelledFun, false));

                env->CallVoidMethod(m_javaWebClient, m_postMultipartRequestMethod, jserverType, jserverPath, jjsonString, jfileMimeType, jfileName, jfilePath, nativeCallbackObject, nativeContext);
                clearAndLogJvmException(env, "com.qliqsoft.qx.web.JavaAndroidWebClient.postMultipartRequest()");
            }

            /// JSON request to any webserver (url based), response is original parsed JSON
            virtual void postJsonRequestToUrl(const std::string& url, const json11::Json& json, const std::map<std::string, std::string>& extraHeaders,
                                              JsonCallback callback, IsCancelledFunction isCancelledFun = IsCancelledFunction()) override
            {}

            /// Request to any webserver (url based) with a parsed JSON response
            virtual void getJsonUrl(const std::string& url, const std::map<std::string, std::string>& extraHeaders,
                                    JsonCallback callback, IsCancelledFunction isCancelledFun = IsCancelledFunction()) override
            {}

            void onJavaFinished(RequestContext *context, int networkErrorOrHttpStatus, int jsonCode, std::string message, std::string jsonString)
            {
                QliqWebError error;
                error.networkErrorOrHttpStatus = networkErrorOrHttpStatus;
                error.code = jsonCode;
                error.message = message;

                json11::Json json;
                if (!error && !context->isFileDownload) {
                    std::string parsingError;
                    json = json11::Json::parse(jsonString, parsingError);
                    if (parsingError.empty()) {
                        const json11::Json& messageObject = json["Message"];
                        if (messageObject["Data"].is_object()) {
                            json = messageObject["Data"];
                        } else if (messageObject["Error"].is_object()) {
                            const json11::Json& errorObject = messageObject["Error"];
                            error.message = errorObject["error_msg"].string_value();
                            error.code = errorObject["error_code"].int_value();
                            if (error.code == 0) {
                                // Webserver sends error as string instead of number
                                error.code = std::stoi(errorObject["error_code"].string_value());
                            }
                        } else {
                            parsingError = "Parsing error: neither Message.Data nor Message.Error object found in response";
                        }
                    }

                    if (!parsingError.empty()) {
                        error.code = -2;
                        error.message = parsingError;
                    }
                }

                context->callback(error, json);
            }


        private:
            void resolveJavaMethods(JNIEnv *env, jobject javaWebClient)
            {
                m_javaWebClient = env->NewGlobalRef(javaWebClient);

                jclass cls = env->FindClass("com/qliqsoft/qx/web/JavaAndroidWebClient");
                if (!cls) {
                    __android_log_write(ANDROID_LOG_ERROR, APPNAME, "Could not find the com.qliqsoft.qx.web.JavaAndroidWebClient class");
                } else {
                    m_javaWebClientClass = reinterpret_cast<jclass>(env->NewGlobalRef(cls));

                    m_postJsonRequestMethod = env->GetMethodID(cls, "postJsonRequest", "(ILjava/lang/String;Ljava/lang/String;Ljava/lang/String;JJ)V");
                    if (!m_postJsonRequestMethod) {
                        __android_log_write(ANDROID_LOG_ERROR, APPNAME, "Could not find the \"public void postJsonRequest(short serverType, String serverPath, String json)\" method");
                    } else {
                        m_postMultipartRequestMethod = env->GetMethodID(cls, "postMultipartRequest",
                                                                        "(ILjava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;JJ)V");
                        if (!m_postMultipartRequestMethod) {
                            __android_log_write(ANDROID_LOG_ERROR, APPNAME,
                                                "Could not find the \"public void postMultipartRequest(short serverType, String serverPath, String json, String fileMimeType, String fileName, String filePath, final long nativeCallbackObject, final long nativeContext) {\" method");
                        }
                    }

                    if (m_postJsonRequestMethod && m_postMultipartRequestMethod) {
                        __android_log_write(ANDROID_LOG_INFO, APPNAME, "Resolved com.qliqsoft.qx.web.JavaAndroidWebClient class");
                    }
                }

                clearAndLogJvmException(env, "qx::web::WebClientImpl::resolveJavaMethods");
            }

            jobject m_javaWebClient;
            jclass m_javaWebClientClass;
            jmethodID m_postJsonRequestMethod;
            jmethodID m_postMultipartRequestMethod;
        };

    } // web
} // qx

namespace  {
    qx::web::WebClientImpl *s_webClientImpl = nullptr;
    std::string s_temporaryDirPath;
    std::string s_dataDirPath;
    qx::NetworkMonitor *s_networkMonitor = nullptr;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
// JNI functions
//
extern "C"
JNIEXPORT void JNICALL
Java_com_qliqsoft_qxlib_AndroidQxPlatform_init(JNIEnv *env, jobject instance)
{
    __android_log_write(ANDROID_LOG_DEBUG, APPNAME, "AndroidQxPlatform.init() entered");
    env->GetJavaVM(&s_jvm);

    try {
        __android_log_write(ANDROID_LOG_DEBUG, APPNAME, "Testing Exception, throwing std::string");
        throw std::string("A test");
    } catch (int e) {
        __android_log_print(ANDROID_LOG_DEBUG, APPNAME, "Exception int: %d", e);
    } catch (const std::exception& ex) {
        __android_log_print(ANDROID_LOG_DEBUG, APPNAME, "Exception std::exception: %s", ex.what());
    } catch (const std::string& str) {
        __android_log_print(ANDROID_LOG_DEBUG, APPNAME, "Exception std::string: %s", str.c_str());
    } catch (...) {
        __android_log_write(ANDROID_LOG_DEBUG, APPNAME, "Exception did not match");
    }

    qx::TerminateHandler::install();

    __android_log_write(ANDROID_LOG_DEBUG, APPNAME, "AndroidQxPlatform.about to resolve qliqsoft Log");
    resolveQliqsoftJavaLogger(env);
    __android_log_write(ANDROID_LOG_DEBUG, APPNAME, "AndroidQxPlatform.after resolved qliqsoft Log");

    if (s_networkMonitor) {
        delete s_networkMonitor;
    }
    s_networkMonitor = new qx::NetworkMonitor();

    __android_log_write(ANDROID_LOG_DEBUG, APPNAME, "AndroidQxPlatform.init() exited");
}

extern "C"
JNIEXPORT void JNICALL
Java_com_qliqsoft_qxlib_AndroidQxPlatform_setWebClient(JNIEnv *env, jobject instance,
                                                       jobject javaWebClient)
{
    __android_log_write(ANDROID_LOG_DEBUG, APPNAME, "AndroidQxPlatform.setWebClient() entered");
    s_webClientImpl = new qx::web::WebClientImpl(env, javaWebClient);
    qx::web::WebClient::setDefaultInstance(s_webClientImpl);
    __android_log_write(ANDROID_LOG_DEBUG, APPNAME, "AndroidQxPlatform.setWebClient() exited");
}


extern "C"
JNIEXPORT void JNICALL
Java_com_qliqsoft_qxlib_AndroidQxPlatform_setUseLogCatOnly(JNIEnv *env, jobject instance, jboolean only)
{
    __android_log_write(ANDROID_LOG_DEBUG, APPNAME, "AndroidQxPlatform.setUseLogCatOnly() entered");
    if (only == JNI_TRUE) {
        s_qliqsoft_utils_log_LogMethod = nullptr;
        if (s_com_qliqsoft_utils_LogClass) {
            env->DeleteGlobalRef(s_com_qliqsoft_utils_LogClass);
            s_com_qliqsoft_utils_LogClass = nullptr;
        }
    } else {
        if (!s_qliqsoft_utils_log_LogMethod) {
            resolveQliqsoftJavaLogger(env);
        }
    }
    __android_log_write(ANDROID_LOG_DEBUG, APPNAME, "AndroidQxPlatform.setUseLogCatOnly() exited");
}

extern "C"
JNIEXPORT jboolean JNICALL
Java_com_qliqsoft_qxlib_AndroidQxPlatform_setKeyPair(JNIEnv *env, jobject instance,
                                                     jstring publicKey_, jstring privateKey_,
                                                     jstring password_) {
    __android_log_write(ANDROID_LOG_DEBUG, APPNAME, "AndroidQxPlatform.setKeyPair() entered");
    const char *publicKey = env->GetStringUTFChars(publicKey_, 0);
    const char *privateKey = env->GetStringUTFChars(privateKey_, 0);
    const char *password = env->GetStringUTFChars(password_, 0);

    qx::Crypto *crypto = qx::Crypto::instance();
    if (!crypto) {
        crypto = new qx::Crypto();
	qx::Crypto::setInstance(crypto);
    }
    jboolean ret = crypto->setKeys(publicKey, privateKey, password) ? 1 : 0;
    if (ret) {
        QXLOG_SUPPORT("Loaded key pair, md5: %s", crypto->publicKeyMd5().c_str());
    } else {
        QXLOG_ERROR("Failed to load key pair, either corrupted key or wrong password", nullptr);
    }

    env->ReleaseStringUTFChars(publicKey_, publicKey);
    env->ReleaseStringUTFChars(privateKey_, privateKey);
    env->ReleaseStringUTFChars(password_, password);
    __android_log_write(ANDROID_LOG_DEBUG, APPNAME, "AndroidQxPlatform.setKeyPair() exited");
    return ret;
}

extern "C"
JNIEXPORT void JNICALL
Java_com_qliqsoft_qx_web_JavaAndroidWebClient_nativeJsonCallback(JNIEnv *env, jclass type,
                                                                 jlong nativeCallbackObject,
                                                                 jlong nativeContext,
                                                                 jint networkErrorOrHttpStatus,
                                                                 jint jsonCode, jstring message_,
                                                                 jstring json_)
{
    __android_log_write(ANDROID_LOG_DEBUG, APPNAME, "JavaAndroidWebClient.nativeJsonCallback() entered");
    const char *message = env->GetStringUTFChars(message_, 0);
    const char *json = env->GetStringUTFChars(json_, 0);

    qx::web::WebClientImpl *webClient = reinterpret_cast<qx::web::WebClientImpl *>(nativeCallbackObject);
    qx::web::WebClientImpl::RequestContext *context = reinterpret_cast<qx::web::WebClientImpl::RequestContext *>(nativeContext);
    try {
        webClient->onJavaFinished(context, networkErrorOrHttpStatus, jsonCode, message, json);
    } catch (const std::exception& ex) {
        __android_log_print(ANDROID_LOG_FATAL, APPNAME, "Unexpected std::exception occurred in webClient->onJavaFinished: %s", ex.what());
    } catch (...) {
        __android_log_write(ANDROID_LOG_FATAL, APPNAME, "Unknown C++ exception occurred in webClient->onJavaFinished");
    }

    clearAndLogJvmException(env, "qx::web::WebClientImpl::onJavaFinished()");

    env->ReleaseStringUTFChars(message_, message);
    env->ReleaseStringUTFChars(json_, json);
    __android_log_write(ANDROID_LOG_DEBUG, APPNAME, "JavaAndroidWebClient.nativeJsonCallback() exited");
}

extern "C"
JNIEXPORT void JNICALL
Java_com_qliqsoft_qxlib_AndroidQxPlatform_setTemporaryDirPath(JNIEnv *env, jobject instance,
                                                              jstring path_)
{
    __android_log_write(ANDROID_LOG_DEBUG, APPNAME, "AndroidQxPlatform.setTemporaryDirPath() entered");
    const char *path = env->GetStringUTFChars(path_, 0);

    s_temporaryDirPath = path;

    env->ReleaseStringUTFChars(path_, path);
    __android_log_write(ANDROID_LOG_DEBUG, APPNAME, "AndroidQxPlatform.setTemporaryDirPath() exited");
}

extern "C"
JNIEXPORT void JNICALL
Java_com_qliqsoft_qxlib_AndroidQxPlatform_setDataDirPath(JNIEnv *env, jobject instance,
                                                              jstring path_)
{
    const char *path = env->GetStringUTFChars(path_, 0);

    s_dataDirPath = path;

    env->ReleaseStringUTFChars(path_, path);
}

extern "C"
JNIEXPORT void JNICALL
Java_com_qliqsoft_qxlib_AndroidQxPlatform_setMyUser(JNIEnv *env, jobject instance, jstring qliqId_,
                                                    jstring userName_, jstring displayName_, jstring password_)
{
    __android_log_write(ANDROID_LOG_DEBUG, APPNAME, "AndroidQxPlatform.setMyUser() entered");
    const char *qliqId = env->GetStringUTFChars(qliqId_, 0);
    const char *userName = env->GetStringUTFChars(userName_, 0);
    const char *displayName = env->GetStringUTFChars(displayName_, 0);
    const char *password = env->GetStringUTFChars(password_, 0);

    auto& session = qx::Session::instance();
    session.setMyQliqId(qliqId);
    session.setUserName(userName);
    session.setMyEmail(userName);
    session.setMyDisplayName(displayName);
    session.setPassword(password);

    env->ReleaseStringUTFChars(qliqId_, qliqId);
    env->ReleaseStringUTFChars(userName_, userName);
    env->ReleaseStringUTFChars(displayName_, displayName);
    env->ReleaseStringUTFChars(password_, password);
    __android_log_write(ANDROID_LOG_DEBUG, APPNAME, "AndroidQxPlatform.setMyUser() exited");
}

extern "C"
JNIEXPORT void JNICALL
Java_com_qliqsoft_qxlib_AndroidQxPlatform_setDeviceName(JNIEnv *env, jobject instance,
                                                        jstring deviceName_)
{
    __android_log_write(ANDROID_LOG_DEBUG, APPNAME, "AndroidQxPlatform.setDeviceName() entered");
    const char *deviceName = env->GetStringUTFChars(deviceName_, 0);

    auto& session = qx::Session::instance();
    session.setDeviceName(deviceName);

    env->ReleaseStringUTFChars(deviceName_, deviceName);
    __android_log_write(ANDROID_LOG_DEBUG, APPNAME, "AndroidQxPlatform.setDeviceName() exited");
}

std::string qx_filesystem_temporaryDirPath_impl()
{
    return s_temporaryDirPath;
}

std::string qx_Session_dataDirectoryRootPath_impl()
{
    return s_dataDirPath;
}

extern "C"
JNIEXPORT jboolean JNICALL
Java_com_qliqsoft_qxlib_AndroidQxPlatform_openDatabase(JNIEnv *env, jobject instance, jstring path_,
                                                       jstring key_)
{
    __android_log_write(ANDROID_LOG_DEBUG, APPNAME, "AndroidQxPlatform.openDatabase() entered");
    const char *path = env->GetStringUTFChars(path_, 0);
    const char *key = env->GetStringUTFChars(key_, 0);

    bool ok = QxDatabase::openDefaultInstance(path, key);
    jboolean ret = (ok ? JNI_TRUE : JNI_FALSE);

    env->ReleaseStringUTFChars(path_, path);
    env->ReleaseStringUTFChars(key_, key);

    __android_log_write(ANDROID_LOG_DEBUG, APPNAME, "AndroidQxPlatform.openDatabase() exited");
    return ret;
}

extern "C"
JNIEXPORT void JNICALL
Java_com_qliqsoft_qxlib_AndroidQxPlatform_closeDatabase(JNIEnv *env, jobject instance)
{
    __android_log_write(ANDROID_LOG_DEBUG, APPNAME, "AndroidQxPlatform.closeDatabase() entered");
    QxDatabase::deleteDefaultInstance();
    __android_log_write(ANDROID_LOG_DEBUG, APPNAME, "AndroidQxPlatform.closeDatabase() exited");
}

extern "C"
JNIEXPORT jboolean JNICALL
Java_com_qliqsoft_qxlib_AndroidQxPlatform_isDatabaseOpen(JNIEnv *env, jobject instance)
{
    __android_log_write(ANDROID_LOG_DEBUG, APPNAME, "AndroidQxPlatform.isDatabaseOpen() entered");

    bool ok = QxDatabase::isDefaultInstanceOpen();
    jboolean ret = (ok ? JNI_TRUE : JNI_FALSE);

    __android_log_write(ANDROID_LOG_DEBUG, APPNAME, "AndroidQxPlatform.isDatabaseOpen() exited");
    return ret;
}

extern "C"
JNIEXPORT jstring JNICALL
Java_com_qliqsoft_qxlib_AndroidQxPlatform_getDatabasePath(JNIEnv *env, jobject instance)
{
    __android_log_write(ANDROID_LOG_DEBUG, APPNAME, "AndroidQxPlatform.getDatabasePath() entered");

    jstring ret = nullptr;
    if (QxDatabase::isDefaultInstanceOpen()) {
	ret = env->NewStringUTF(QxDatabase::defaultInstance().fileName().c_str());
    }

    __android_log_write(ANDROID_LOG_DEBUG, APPNAME, "AndroidQxPlatform.getDatabasePath() exited");
    return ret;
}

extern "C"
JNIEXPORT jstring JNICALL
Java_com_qliqsoft_qxlib_AndroidQxPlatform_getDatabaseKey(JNIEnv *env, jobject instance)
{
    __android_log_write(ANDROID_LOG_DEBUG, APPNAME, "AndroidQxPlatform.getDatabaseKey() entered");

    jstring ret = nullptr;
    if (QxDatabase::isDefaultInstanceOpen()) {
	ret = env->NewStringUTF(QxDatabase::defaultInstance().encryptionKey().c_str());
    }

    __android_log_write(ANDROID_LOG_DEBUG, APPNAME, "AndroidQxPlatform.getDatabaseKey() exited");
    return ret;
}

extern "C"
JNIEXPORT jboolean JNICALL
Java_com_qliqsoft_qxlib_AndroidQxPlatform_testCppExceptions(JNIEnv *env, jobject instance)
{
    __android_log_write(ANDROID_LOG_DEBUG, APPNAME, "AndroidQxPlatform.testCppExceptions() entered");
    jboolean ret = JNI_FALSE;
    try {
        __android_log_write(ANDROID_LOG_DEBUG, APPNAME, "Testing Exception, throwing std::runtime_error");
        throw std::runtime_error("A test");
    } catch (const std::runtime_error& ex) {
        __android_log_print(ANDROID_LOG_DEBUG, APPNAME, "Exception std::runtime_error: %s", ex.what());
        ret = JNI_TRUE;
    }
    __android_log_write(ANDROID_LOG_DEBUG, APPNAME, "AndroidQxPlatform.testCppExceptions() exited");
    return ret;
}

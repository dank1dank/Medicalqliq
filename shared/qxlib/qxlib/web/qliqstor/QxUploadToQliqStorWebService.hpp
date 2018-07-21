#ifndef QXUPLOADTOQLIQSTORWEBSERVICE_H
#define QXUPLOADTOQLIQSTORWEBSERVICE_H
#include "qxlib/web/QxWebClient.hpp"
#include "qxlib/model/QxMediaFile.hpp"

namespace qx {

class Crypto;

namespace web {

class UploadToQliqStorWebService : public BaseWebService
{
public:
    struct UploadParams {
        std::string uploadUuid;
        std::string qliqStorQliqId;
        std::string qliqStorDeviceUuid;
        // if EMR
        struct EmrTarget {
            std::string type;
            std::string uuid;
            std::string hl7Id;
            std::string name;
        } emr;
        // if Fax
        struct FaxTarget {
            std::string number;
            std::string voiceNumber;
            std::string organization;
            std::string contactName;
            std::string subject;
            std::string body;
        } fax;

#ifndef SWIG
        struct UploadedBy {
            std::string name;
            std::string qliqId;
            std::string email;
            std::string device;

            static UploadedBy fromJson(const json11::Json& json);
            static UploadedBy fromJsonString(const std::string& json);
        };

        void parseUploadTarget(const json11::Json &json, MediaFileUpload::ShareType shareType);
        void parseUploadTarget(const std::string& json, MediaFileUpload::ShareType shareType);
        json11::Json::object toJson() const;
        static UploadParams fromJson(const json11::Json& json);
        static UploadParams fromJsonString(const std::string& json);
#endif // !SWIG

        bool isEmrUpload() const;
        bool isFaxUpload() const;
    };

    UploadToQliqStorWebService(WebClient *webClient = nullptr);

#ifndef SWIG
    typedef std::function<void(const QliqWebError& error)> ResultFunction;
    using IsCancelledFunction = WebClient::IsCancelledFunction;

    void uploadFile(const UploadParams& uploadParams, const MediaFile& file,
                    ResultFunction resultCallback, IsCancelledFunction isCancelledFun = IsCancelledFunction());

#endif // !SWIG

    class ResultCallback {
    public:
        virtual ~ResultCallback() {}
        virtual void run(const QliqWebError *error) = 0;
    };
    void uploadFile(const UploadParams& uploadParams, const MediaFile& file, ResultCallback *resultCallback);

#ifndef SWIG
    // public because needed by qx::UploadToQliqStorTask class
    virtual json11::Json::object targetJson(const UploadParams& uploadParams);
#endif

protected:
    virtual const char *serverPath() const;
    virtual const char *uploadTypeString() const;
    virtual const char *uploadTargetKeyString() const;

    json11::Json::object requestJson(const UploadParams& uploadParams);
};

struct UploadToQliqStorResponse {
    enum UploaderErrorCode {
        SuccessUploaderErrorCode = 200,             // upload finished (store on qS or in EMR)
        BadRequestUploaderErrorCode = 400,          // either bug on sender or format not supported, sender should not retry
        WrongKeyUploaderErrorCode = 493,            // if cannot decrypt key, uploader should get qS's PK and retry
        CorruptedUploadUploaderErrorCode = 502,     // uploader should re-upload to web (1 retry only)
        DecryptionFailedUploaderErrorCode = 550,    // uploader should re-upload to web (1 retry only)
        ThirdPartyFailureErrorCode = 500            // uploader did the right thing, either qS or EMR failed
    };

};

} // web
} // qx

#endif // QXUPLOADTOQLIQSTORWEBSERVICE_H

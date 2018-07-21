#ifndef QXUPLOADTOQLIQSTORTASK_HPP
#define QXUPLOADTOQLIQSTORTASK_HPP
#include <vector>
#include "qxlib/web/qliqstor/QxUploadToQliqStorWebService.hpp"
#include "qxlib/controller/qliqstor/QxExportConversation.hpp"

namespace qx {

struct MediaFileUpload;

class UploadToQliqStorTask
{
public:
    UploadToQliqStorTask();
    ~UploadToQliqStorTask();

#ifndef SWIG
    using UploadParams = web::UploadToQliqStorWebService::UploadParams;
    using ResultFunction = web::UploadToQliqStorWebService::ResultFunction;
    using IsCancelledFunction = web::WebClient::IsCancelledFunction;

    void uploadConversation(const UploadParams& uploadParams, const ExportConversation::ConversationMessageList& list, const std::string& publicKey,
                            ResultFunction resultCallback, IsCancelledFunction isCancelledFun = IsCancelledFunction());

    void uploadFile(const UploadParams& uploadParams, const std::string& filePath,
                    const std::string& displayFileName, const std::string& thumbnail, const std::string& publicKey,
                    ResultFunction resultCallback, IsCancelledFunction isCancelledFun = IsCancelledFunction());

    void reuploadFile(const MediaFileUpload& upload, const std::string& publicKey,
                    ResultFunction resultCallback, IsCancelledFunction isCancelledFun = IsCancelledFunction());
#endif
    void uploadConversation(const web::UploadToQliqStorWebService::UploadParams& uploadParams, const ExportConversation::ConversationMessageList& list, const std::string& publicKey,
                            web::UploadToQliqStorWebService::ResultCallback *resultCallback);

    void uploadFile(const web::UploadToQliqStorWebService::UploadParams& uploadParams, const std::string& filePath, const std::string& displayFileName,
                    const std::string& thumbnail, const std::string& publicKey, web::UploadToQliqStorWebService::ResultCallback *resultCallback);

    void reupload(const MediaFileUpload& upload, const std::string& publicKey, web::UploadToQliqStorWebService::ResultCallback *resultCallback);

    static void processChangeNotification(const std::string& subject, const std::string& payload);

private:
    struct Private;
    Private *d;
    friend struct Private;
};

} // qx

#endif // QXUPLOADTOQLIQSTORTASK_HPP

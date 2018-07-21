#ifndef QXENCRYPTMEDIAFILETASK_HPP
#define QXENCRYPTMEDIAFILETASK_HPP
#include "qxlib/model/QxMediaFile.hpp"
#include "qxlib/web/QxWebClient.hpp"

#ifndef SWIG

namespace qx {

class EncryptMediaFileTask
{
public:
    EncryptMediaFileTask();
    ~EncryptMediaFileTask();

    typedef std::function<void(const MediaFile& mf, const web::QliqWebError& error)> SuccessFunction;
    typedef std::function<void(const web::QliqWebError& error)> ErrorFunction;

    void encrypt(const std::string& filePath, const std::string& encryptedFilePath,
                 const std::string& displayFileName, const std::string& thumbnail,
                 const std::string& recipientQliqId, std::string publicKey,
                 SuccessFunction successCallback, ErrorFunction errorCallback);

private:
    struct Private;
    Private *d;
    friend class Private;
};

} // qx

#endif // !SWIG

#endif // QXENCRYPTMEDIAFILETASK_HPP

#include "QxWebClientAndroidImpl.hpp"

namespace qx {
    namespace web {

        void AndroidWebClient::postJsonRequest(const std::string& serverPath, const json11::Json& json,
                                     JsonCallback callback, IsCancelledFunction isCancelledFun)
        {}


        void AndroidWebClient::postMultipartRequest(const std::string& serverPath, const json11::Json& json,
                                          const std::string& fileMimeType, const std::string& fileName, const std::string& filePath,
                                          JsonCallback callback, IsCancelledFunction isCancelledFun)
        {}



    } // web
} // qx

#include "QxSipLogModule.hpp"
#include <algorithm>
#include <vector>
#include <cstring>
#include "qxlib/crypto/QxCrypto.hpp"
#include "qxlib/dao/sip/QxSipContactDao.hpp"
#include "qxlib/model/QxSession.hpp"
#include "qxlib/model/sip/QxSipUtil.hpp"
#include "qxlib/db/QxLogDatabase.hpp"
#include "qxlib/log/sip/QxSipLogRecordDao.hpp"
#include "qxlib/model/sip/QxSip.hpp"

#include <pjsip.h>

namespace qx {

using namespace SipUtil;

namespace {

std::vector<SipLogModule::SipActivityListener *> s_activityListeners;

std::string privateKeyForQliqId(const std::string& qliqId)
{
    SipContact contact = SipContactDao::selectOneBy(SipContactDao::QliqIdColumn, qliqId);
    return contact.privateKey;
}

std::string headerValue(const pj_str_t *message, const char *bodyPtr, const char *headerName)
{
    pj_str_t headerNamePj;
    pj_cstr(&headerNamePj, headerName);
    const char *ptr = pj_strstr(message, &headerNamePj);
    if (ptr && ptr < bodyPtr) {
        ptr += headerNamePj.slen;
#ifdef NO_BUGS_ON_QLIQ_SERVER
        // For a SIP standard complaint message this code is enough
        std::string ret = std::string(ptr, (std::strstr(ptr, "\r\n") - ptr));
#else
        // There is a bug on web/sip server that for messages sent by webserver
        // the Content-Type line ends just with '\n' instead of '\r\n'
        std::string ret;
        const char *eolPtr = std::strchr(ptr, '\n');
        if (eolPtr) {
            if (*(eolPtr - 1) == '\r') {
                eolPtr--;
            }
            ret = std::string(ptr, eolPtr - ptr);
        }
#endif
        return ret;
    } else {
        return "";
    }
}

std::string possiblyDecrypt(Crypto *crypto, const pj_str_t *data, const std::string& qliqId)
{
    std::string ret;

    const pj_str_t delimeter = pj_str_t{(char *)"\r\n\r\n", 4};
    const char *contentPtr = pj_strstr(data, &delimeter);
    if (contentPtr) {
        contentPtr += delimeter.slen;
    } else {
        // Should not happen for a valid message
        contentPtr = data->ptr + data->slen;
    }

    int contentLength = 0;
    {
        std::string contentLengthStr = headerValue(data, contentPtr, "\nContent-Length: ");
        contentLength = std::atoi(contentLengthStr.c_str());
    }

    if (contentLength > 0) {
        std::string contentType = headerValue(data, contentPtr, "\nContent-Type: ");
        auto colonPos = contentType.find(';');
        if (colonPos != std::string::npos) {
            contentType.erase(colonPos);
        }
        // contentPtr is NOT null terminated, we must construct std::string with size argument
        // we have size in contentLength variable from 'Content-Length' header
        // but in case of server/client bug it may be wrong and crash app here
        // so it is safer to compute based on data->slen and pointer arithmetic
        const std::size_t contentLen = data->slen - (contentPtr - data->ptr);
        const std::string content(contentPtr, contentLen);

        if (contentType == "application/octet-stream") {
            if (crypto) {
                bool ok = true;

                if (qliqId == Session::instance().myQliqId()) {
                    ret = crypto->decryptFromBase64ToString(content, &ok);
                } else {
                    std::string privateKey = privateKeyForQliqId(qliqId);
                    if (!privateKey.empty()) {
                        ret = crypto->decryptWithKeyFromBase64ToString(content, privateKey, Sip::defaultGroupKeyPassword(), &ok);
                    } else {
                        QXLOG_ERROR("Could not find private key for qliq id: %s", qliqId.c_str());
                    }
                }

                if (!ok) {
                    std::string callId = headerValue(data, contentPtr, "\nCall-ID: ");
                    QXLOG_ERROR("Could not decrypt message content for logdb for Call-ID: %s", callId.c_str());
                }
            } else {
                QXLOG_ERROR("Cannot decrypt message because no qx::Crypto::instance()", nullptr);
            }
        } else {
            // There is a bug on webserver: it sends 'text/html' instead of 'text/plain'
            // but Krishna ignores so it is not fixed. One day when server starts to encrypt content it will break
            if (contentType != "text/plain" && contentType != "text/html") {
                QXLOG_ERROR("Unsupported Content-Type: '%s', assuming text/plain", contentType.c_str());
            }
            ret = content;
        }
    }

    return ret;
}

bool isMessageMethod(pjsip_msg *msg)
{
    static const pj_str_t MESSAGE = {(char *)"MESSAGE", 7};
    return msg && (pj_strcmp(&msg->line.req.method.name, &MESSAGE) == 0);
}

void logMessage(bool received, pjsip_msg *msg, char *msgInfo)
{
    if (!msg) {
        QXLOG_FATAL("%s structure with null msg pointer, info: %s", (received ? "Received" : "Sending"), msgInfo);
        return;
    }

    pj_str_t callId = {nullptr, 0};
    pjsip_cid_hdr *callIdHeader = PJSIP_MSG_CID_HDR(msg);
    if (callIdHeader) {
        callId = callIdHeader->id;
    }

    std::string from;
    pjsip_from_hdr *fromHeader = PJSIP_MSG_FROM_HDR(msg);
    if (fromHeader) {
        char buffer[PJSIP_MAX_URL_SIZE];
        int len = pjsip_uri_print(PJSIP_URI_IN_FROMTO_HDR, fromHeader->uri, buffer, PJSIP_MAX_URL_SIZE);
        from = qliqIdFromSipUri(stripSip(std::string(buffer, static_cast<std::size_t>(len))));
    }

    std::string to;
    pjsip_to_hdr *toHeader = PJSIP_MSG_TO_HDR(msg);
    if (toHeader) {
        char buffer[PJSIP_MAX_URL_SIZE];
        int len = pjsip_uri_print(PJSIP_URI_IN_FROMTO_HDR, toHeader->uri, buffer, PJSIP_MAX_URL_SIZE);
        to = qliqIdFromSipUri(stripSip(std::string(buffer, static_cast<std::size_t>(len))));
    }

    // TODO: log  detailed information per method type:
    // ie. X-event for NOTIFY, or X-status for MESSAGE with Content-Lenght: 0
    QXLOG_SUPPORT("%s: %s Call-ID: %.*s, From: %s, To: %s", (received ? "Received" : "Sending"),
                  msgInfo, callId.slen, callId.ptr, from.c_str(), to.c_str());
}

} // anonymous

int onRxMessage(pjsip_rx_data *rdata, bool isRequest)
{
    if (LogDatabase::isSipEnabled()) {
        logMessage(true, rdata->msg_info.msg, pjsip_rx_data_get_info(rdata));

        std::string plainText;
        if (isRequest && Crypto::instance()) {
            if (isMessageMethod(rdata->msg_info.msg)) {
                char buffer[PJSIP_MAX_URL_SIZE];
                int len = pjsip_uri_print(PJSIP_URI_IN_FROMTO_HDR, rdata->msg_info.to->uri, buffer, PJSIP_MAX_URL_SIZE);
                std::string to = qliqIdFromSipUri(stripSip(std::string(buffer, static_cast<std::size_t>(len))));

                const pj_str_t request{rdata->msg_info.msg_buf, rdata->msg_info.len};
                plainText = possiblyDecrypt(Crypto::instance(), &request, to);
            }
        }

        SipLogRecord record;
        bool ok = SipLogRecordDao::parse(&record, rdata->msg_info.msg_buf, rdata->msg_info.len, SipLogRecord::Inbound,
                                             isRequest, plainText.empty() ? nullptr : plainText.c_str());

        if (ok) {
            SipLogRecordDao::save(record, isRequest);
        }
    }

    for (auto& l: s_activityListeners) {
        l->onSipActivity();
    }

    return PJ_FALSE;
}

int onTxMessage(pjsip_tx_data *tdata, bool isRequest)
{
    if (LogDatabase::isSipEnabled()) {
        logMessage(false, tdata->msg, pjsip_tx_data_get_info(tdata));

        pj_ssize_t len = (tdata->buf.cur - tdata->buf.start);
        std::string plainText;
        if (isRequest && Sip::instance()) {
            if (isMessageMethod(tdata->msg)) {
                pj_str_t message{tdata->buf.start, len};
                std::string callId = headerValue(&message, (message.ptr + message.slen), "\nCall-ID: ");
                plainText = Sip::instance()->lastMessagePlainTextBody(callId);
            }
        }

        SipLogRecord record;
        bool ok = SipLogRecordDao::parse(&record, tdata->buf.start, len, SipLogRecord::Outbound,
                                             isRequest, plainText.empty() ? nullptr : plainText.c_str());

        if (ok) {
            SipLogRecordDao::save(record, isRequest);
        }
    }

    for (auto& l: s_activityListeners) {
        l->onSipActivity();
    }

    return PJ_FALSE;
}

int onRxRequest(pjsip_rx_data *rdata)
{
    return onRxMessage(rdata, true);
}

int onRxResponse(pjsip_rx_data *rdata)
{
    return onRxMessage(rdata, false);
}

int onTxRequest(pjsip_tx_data *tdata)
{
    return onTxMessage(tdata, true);
}

int onTxResponse(pjsip_tx_data *tdata)
{
    return onTxMessage(tdata, false);
}

static pjsip_module mod_log_handler =
{
    NULL, NULL,				/* prev, next.		*/
    {(char *) "qx-mod-log-handler", 18},	/* Name.		*/
    -1,					/* Id			*/
    PJSIP_MOD_PRIORITY_TRANSPORT_LAYER-1,	/* Priority	        */
    NULL,				/* load()		*/
    NULL,				/* start()		*/
    NULL,				/* stop()		*/
    NULL,				/* unload()		*/
    onRxRequest,		/* on_rx_request()	*/
    onRxResponse,		/* on_rx_response()	*/
    onTxRequest,		/* on_tx_request.	*/
    onTxResponse,		/* on_tx_response()	*/
    NULL,				/* on_tsx_state()	*/
};

void SipLogModule::addActivityListener(SipLogModule::SipActivityListener *listener)
{
    auto it = std::find(s_activityListeners.begin(), s_activityListeners.end(), listener);
    if (it == s_activityListeners.end()) {
        s_activityListeners.push_back(listener);
    }
}

void SipLogModule::removeActivityListener(SipLogModule::SipActivityListener *listener)
{
    auto it = std::find(s_activityListeners.begin(), s_activityListeners.end(), listener);
    if (it != s_activityListeners.end()) {
        s_activityListeners.erase(it);
    }
}

} // namespace qx

extern "C" struct pjsip_module *qx_mod_log_handler()
{
    return &qx::mod_log_handler;
}

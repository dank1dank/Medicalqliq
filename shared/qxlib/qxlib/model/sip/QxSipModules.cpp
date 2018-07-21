#include "QxSipModules.hpp"
#include <algorithm>
#include <pjsip.h>
#include <pjsua-lib/pjsua.h>
#include "qxlib/log/QxLog.hpp"
#include "qxlib/model/sip/QxSipUtil.hpp"

namespace {

using namespace qx::SipUtil;

pj_bool_t are_uris_equal(pjsip_uri *a, pjsip_uri *b, pjsip_sip_uri **uriA, pjsip_sip_uri **uriB)
{
    pj_bool_t ret = PJ_FALSE;
    if ((PJSIP_URI_SCHEME_IS_SIP(a) || PJSIP_URI_SCHEME_IS_SIPS(a)) &&
        (PJSIP_URI_SCHEME_IS_SIP(b) || PJSIP_URI_SCHEME_IS_SIPS(b))) {
        *uriA = (pjsip_sip_uri*) pjsip_uri_get_uri(a);
        *uriB = (pjsip_sip_uri*) pjsip_uri_get_uri(b);
        ret = pj_strcmp(&(*uriA)->user, &(*uriB)->user) == 0;
    }
    return ret;
}

int onRxRequest(pjsip_rx_data *rdata)
{
    int ret = PJ_FALSE;
    // Only want to handle MESSAGE requests.
    pjsip_msg *msg = rdata->msg_info.msg;
    if (pjsip_method_cmp(&msg->line.req.method, &pjsip_message_method) == 0) {
        pjsua_acc_info acc_info;
        if (pjsua_acc_get_info(0, &acc_info) == PJ_SUCCESS) {
            pjsip_uri *acc_uri = pjsip_parse_uri(rdata->tp_info.pool, acc_info.acc_uri.ptr, acc_info.acc_uri.slen, 0);
            pjsip_uri *recipientUri = msg->line.req.uri;
            pjsip_sip_uri *sipAccUri = nullptr;
            pjsip_sip_uri *sipRecipientUri = nullptr;

            if (!are_uris_equal(acc_uri, recipientUri, &sipAccUri, &sipRecipientUri)) {
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

                if (sipRecipientUri) {
                    pj_str_t *recipientUser = &sipRecipientUri->user;
                    QXLOG_SUPPORT("Received a MESSAGE with wrong RURI: %.*s Call-ID: %.*s, From: %s, To: %s, ignoring it with 200 OK status",
                                  recipientUser->slen, recipientUser->ptr, callId.slen, callId.ptr, from.c_str(), to.c_str());
                } else {
                    const char *newLine = strchr(rdata->msg_info.msg_buf, '\n');
                    int firstLineLen = rdata->msg_info.len;
                    if (newLine) {
                        firstLineLen = std::max(0, static_cast<int>(newLine - rdata->msg_info.msg_buf) - 1);
                    }
                    if (firstLineLen > rdata->msg_info.len) {
                        firstLineLen = rdata->msg_info.len;
                    }
                    QXLOG_SUPPORT("Received a MESSAGE with unparsable RURI, Call-ID: %.*s, "
                                  "From: %s, To: %s, first line: '%.*s', ignoring it with 200 OK status",
                                  callId.slen, callId.ptr, from.c_str(), to.c_str(), firstLineLen, rdata->msg_info.msg_buf);
                }

                pjsip_endpt_respond(pjsua_get_pjsip_endpt(), nullptr, rdata, PJSIP_SC_OK, nullptr, nullptr, nullptr, nullptr);
                ret = PJ_TRUE;
            }
        }
    }
    return ret;
}

static pjsip_module mod_filter_handler =
{
    nullptr, nullptr,				/* prev, next.		*/
    {(char *) "qx-mod-filter-handler", 21},	/* Name.		*/
    -1,					/* Id			*/
    PJSIP_MOD_PRIORITY_TSX_LAYER,   	/* Priority	        */
    nullptr,				/* load()		*/
    nullptr,				/* start()		*/
    nullptr,				/* stop()		*/
    nullptr,				/* unload()		*/
    onRxRequest,		/* on_rx_request()	*/
    nullptr,       		/* on_rx_response()	*/
    nullptr,       		/* on_tx_request.	*/
    nullptr,       		/* on_tx_response()	*/
    nullptr,				/* on_tsx_state()	*/
};

} // anonymous

extern "C" struct pjsip_module *qx_mod_filter_handler()
{
    return &mod_filter_handler;
}

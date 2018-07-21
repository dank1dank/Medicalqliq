#ifndef QXSIPLOGMODULE_HPP
#define QXSIPLOGMODULE_HPP

struct pjsip_module;

#ifdef __cplusplus
extern "C"
#endif
struct pjsip_module *qx_mod_log_handler();

#ifdef __cplusplus

namespace qx {

class SipLogModule
{
public:
    struct SipActivityListener {
        virtual ~SipActivityListener() = default;
        // WARNING: this method is invoked on the SIP thread
        virtual void onSipActivity() = 0;
    };

    static void addActivityListener(SipActivityListener *listener);
    static void removeActivityListener(SipActivityListener *listener);
};

} // qx

#endif // C++

#endif // QXSIPLOGMODULE_HPP

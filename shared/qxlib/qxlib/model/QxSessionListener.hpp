#ifndef SESSIONLISTENER_HPP
#define SESSIONLISTENER_HPP

namespace qx {

#ifndef SWIG

class SessionListener {
public:
    virtual void onSessionStarted();
    virtual void onSessionFinishing();
    virtual void onSessionFinished();
    virtual void onForegroundStatusChanged(bool isForegroundApp);

protected:
    ~SessionListener();
};

#endif // !SWIG

} // qx

#endif // SESSIONLISTENER_HPP

#ifndef QX_TIMER_HPP
#define QX_TIMER_HPP

namespace qx {

class Timer;

class TimerListener {
public:
    virtual void onTimedOut(Timer *timer) = 0;
};

class Timer
{
public:
    Timer();
    ~Timer();

    void start();
    void stop();

    void addListener(TimerListener *listener);
    void removeListener(TimerListener *listener);

private:
    struct Private;
    Private *d;
};

} // qx

#endif // QX_TIMER_HPP

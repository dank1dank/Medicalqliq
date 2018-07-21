#include "QxTimer.hpp"
#include <set>
namespace qx {

struct Timer::Private {
    std::set<TimerListener *> listeners;
};

Timer::Timer() :
    d(new Private())
{
}

qx::Timer::~Timer()
{
    stop();
    delete d;
}

void Timer::start()
{

}

void Timer::stop()
{

}

void Timer::addListener(TimerListener *listener)
{
    d->listeners.insert(listener);
}

void Timer::removeListener(TimerListener *listener)
{
    d->listeners.erase(listener);
}

} // qx

#ifndef QXROWDATAOBSERVER_HPP
#define QXROWDATAOBSERVER_HPP
#include <algorithm>
#include <vector>

namespace qx {

class RowDataObserver {
public:
    virtual ~RowDataObserver();

    virtual void onRowInserted(int id);
    virtual void onRowChanged(int id);
    virtual void onRowRemoved(int id);
};

/*
template <typename T>
class RowDataObservableStatic {
public:
    static void addRowDataObserver(RowDataObserver *observer)
    {
        auto it = std::find(s_observers.begin(), s_observers.end(), observer);
        if (it == s_observers.end()) {
            s_observers.push_back(observer);
        }
    }

    static void removeRowDataObserver(RowDataObserver *observer)
    {
        auto it = std::find(s_observers.begin(), s_observers.end(), observer);
        if (it != s_observers.end()) {
            s_observers.erase(it);
        }
    }

protected:
    enum class Event {
        Inserted,
        Changed,
        Removed
    };
    static void notifyObservers(Event event, int rowId)
    {
        switch (event) {
        case Event::Inserted:
            for (RowDataObserver *o: s_observers) {
                o->onRowInserted(rowId);
            }
        case Event::Changed:
            for (RowDataObserver *o: s_observers) {
                o->onRowChanged(rowId);
            }
        case Event::Removed:
            for (RowDataObserver *o: s_observers) {
                o->onRowRemoved(rowId);
            }
        }
    }

private:
    static std::vector<RowDataObserver *> s_observers;
};
*/

} // qx

#endif // QXROWDATAOBSERVER_HPP

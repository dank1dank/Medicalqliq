#ifndef QXTHREADUTIL_HPP
#define QXTHREADUTIL_HPP
#include <QString>

namespace qx {

class ThreadUtil
{
public:
    static void setCurrentThreadName(const QString& name);
};

} // namespace qx

#endif // QXTHREADUTIL_HPP

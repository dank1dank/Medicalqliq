#ifndef QXDATABASEBENCHMARK_HPP
#define QXDATABASEBENCHMARK_HPP
#include <string>

#ifdef PROFILE_DATABASE_PERFORMANCE

namespace qx {

class DatabaseBenchmark
{
public:
    static bool isEnabled();
    static void setEnabled(bool value);

    static double time();
    static void registerInvocation(const std::string& query, double time);

private:
    static bool s_isEnabled;
};

} // qx

#endif

#endif // QXDATABASEBENCHMARK_HPP

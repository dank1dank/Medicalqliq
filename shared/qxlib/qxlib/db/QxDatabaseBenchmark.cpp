#include "QxDatabaseBenchmark.hpp"

#ifdef PROFILE_DATABASE_PERFORMANCE

namespace qx {

bool DatabaseBenchmark::s_isEnabled = false;

bool DatabaseBenchmark::isEnabled()
{
    return s_isEnabled;
}

void DatabaseBenchmark::setEnabled(bool value)
{
    s_isEnabled = value;
}

} // qx

#endif // PROFILE_DATABASE_PERFORMANCE

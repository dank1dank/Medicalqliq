#ifndef QXDATABASEUTIL_HPP
#define QXDATABASEUTIL_HPP
#include <string>

namespace qx {
namespace DatabaseUtil {

template <class CONT>
bool notIn(const CONT& cont, std::string *where)
{
    if (!cont.empty()) {
        // Start with space for easy string join
        *where = " NOT IN (";
        int i = 0;
        for (auto id: cont) {
            if (i++ > 0) {
                *where += ", ";
            }
            *where += std::to_string(id);
        }
        *where += ")";
    }
    return where->empty();
}

} // DatabaseUtil
} // qx

#endif // QXDATABASEUTIL_HPP

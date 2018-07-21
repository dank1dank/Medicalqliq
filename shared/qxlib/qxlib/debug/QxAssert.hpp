#ifndef QXASSERT_HPP
#define QXASSERT_HPP

// This is our version of assert which writes to our log
// For debug build it will also crash using C++ assert

#if defined(QX_DEBUG) && !defined(NDEBUG)
#include <cassert>
#include "qxlib/log/QxLog.hpp"

#define qx_assert(_Expression) \
    if (!(_Expression)) { \
        qxlog::Logger::instance().log(qxlog::FatalLevel, __FILE__, __LINE__, "Assertion failed: " #_Expression, nullptr); \
        assert(_Expression); \
    }

#elif !defined(NO_QX_ASSERT)
#include "qxlib/log/QxLog.hpp"

#define qx_assert(_Expression) \
    if (!(_Expression)) { \
        qxlog::Logger::instance().log(qxlog::FatalLevel, __FILE__, __LINE__, "Assertion failed: " #_Expression, nullptr); \
    }

#else

#define qx_assert(_Expression) ((void)0)

#endif

#endif // QXASSERT_HPP

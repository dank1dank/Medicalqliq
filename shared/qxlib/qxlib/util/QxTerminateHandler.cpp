#include "QxTerminateHandler.hpp"
#include <iostream>
#include <exception>
#include "qxlib/log/QxLog.hpp"

[[noreturn]]
static void handle_terminate()
{
    bool rethrownException = false;
    std::exception_ptr p = std::current_exception();
     try {
        std::rethrow_exception (p);
    } catch (const std::exception& e) {
        rethrownException = true;
        std::cerr << "Uncaught exception called terminate handler, what: " << e.what();
        QXLOG_FATAL("Uncaught exception called terminate handler, what: %s", e.what());
    }
    if (!rethrownException) {
        auto msg = "Uncaught exception called terminate handler but cannot rethrow exception";
        std::cerr << msg;
        QXLOG_FATAL(msg, nullptr);
    }
    abort();
}

void qx::TerminateHandler::install()
{
    std::set_terminate(handle_terminate);
}

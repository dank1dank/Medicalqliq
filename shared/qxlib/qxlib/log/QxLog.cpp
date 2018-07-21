#include "QxLog.hpp"
#include <atomic>
#include <ctime>
#include <cstring>
#ifdef QXL_HAS_QT
#include <QsLog.h>
#else
#include <cstdarg>
void qxlog_implementation_log(int qxLevel, const char *file, unsigned int line, const char *format, va_list args);
#endif
#include "qxlib/util/StringUtils.hpp"
// TODO: fix for qliqDirect manager
#ifndef QLIQ_DIRECT_MANAGER
#include "qxlib/db/QxLogDatabase.hpp"
#include "qxlib/util/QxSettings.hpp"

namespace qx {

LogConfig LogConfig::load()
{
    LogConfig ret;
    Settings settings;
    ret.logLevel = static_cast<LogLevel>(settings.valueAsInt("qxLogLevel", static_cast<int>(LogLevel::Normal)));
    ret.isLogDatabaseEnabled = settings.valueAsBool("qxLogDatabaseEnabled", true);

    LogDatabase::setAllLogsEnabled(ret.isLogDatabaseEnabled);
    return ret;
}

void LogConfig::save(const LogConfig &logConfig)
{
    Settings settings;
    settings.setValue("qxLogLevel", static_cast<int>(logConfig.logLevel));
    settings.setValue("qxLogDatabaseEnabled", logConfig.isLogDatabaseEnabled);

    LogDatabase::setAllLogsEnabled(logConfig.isLogDatabaseEnabled);
}

} // qx

#endif

namespace qxlog {

struct Logger::Private {
    std::time_t sessionId;
    std::atomic<int> sequenceId;

    Private() :
        sessionId(std::time(nullptr)), sequenceId(0)
    {}
};

Logger::Logger() :
    d(new Private())
{
}

Logger::~Logger()
{
    delete d;
}

void Logger::log(Level level, const char *file, int line, const char *format, ...)
{
#ifdef QXL_HAS_QT
    QsLogging::Level l = static_cast<QsLogging::Level>(level);
    if (QsLogging::Logger::instance().loggingLevel() <= l) {
        va_list args;
        va_start(args, format);
        QString message = QString().vsprintf(format, args);
        va_end(args);
        QsLogging::Logger::Helper(l).stream() << QsLogging::Logger::Helper::skipProjectRootDir(file) << '@' << line << message.toAscii();
    }
#else
    // TODO: format string inside this method on all platforms instead of passing va_list which may use a bit different format specifier per platform

    // If file is complete path then shorten it
    file = skipProjectRootDir(file);

    va_list args;
    va_start(args, format);
    qxlog_implementation_log(static_cast<int>(level), file, line, format, args);
    va_end(args);
#endif
}

std::time_t Logger::sessionId()
{
    return d->sessionId;
}

void Logger::incrementSessionId()
{
    d->sessionId = std::time(nullptr);
}

int Logger::nextSequenceId()
{
    return d->sequenceId.fetch_add(1);
}

Logger &Logger::instance()
{
    static Logger inst;
    return inst;
}

const char *Logger::skipProjectRootDir(const char *path)
{
    const char *strippedFilePath = StringUtils::strrstr(path, "qxlib");

    if (strippedFilePath) {
        return strippedFilePath + 6;
    } else {
        return path;
    }
}

} // namespace qxlog


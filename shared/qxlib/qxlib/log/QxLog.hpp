#ifndef QXLOG_H
#define QXLOG_H
#include <ctime>

namespace qx {

enum class LogLevel {
    Normal = 1,
    Verbose = 2,
    Debug = 3
};

struct LogConfig {
    LogLevel logLevel = LogLevel::Normal;
    bool isLogDatabaseEnabled = true;

    static LogConfig load();
    static void save(const LogConfig& config);
};

} // qx

namespace qxlog {

enum Level {
    TraceLevel = 0,
    DebugLevel,
    InfoLevel,
    WarnLevel,
    SupportLevel,
    ErrorLevel,
    FatalLevel,
    OffLevel
};

class Logger
{
public:
    Logger();
    ~Logger();

    Level loggingLevel() const;
    void log(Level level, const char *file, int line, const char *format, ...);

    std::time_t sessionId();
    void incrementSessionId();
    int nextSequenceId();

    static Logger& instance();
    static const char *skipProjectRootDir(const char *path);

private:
    struct Private;
    Private *d;
};

} // namespace qxlog

#define QXLOG_TRACE(format, ...) \
    qxlog::Logger::instance().log(qxlog::TraceLevel, __FILE__, __LINE__, format, __VA_ARGS__)
#define QXLOG_DEBUG(format, ...) \
    qxlog::Logger::instance().log(qxlog::DebugLevel, __FILE__, __LINE__, format, __VA_ARGS__)
#define QXLOG_INFO(format, ...) \
    qxlog::Logger::instance().log(qxlog::InfoLevel, __FILE__, __LINE__, format, __VA_ARGS__)
#define QXLOG_WARN(format, ...) \
    qxlog::Logger::instance().log(qxlog::WarnLevel, __FILE__, __LINE__, format, __VA_ARGS__)
#define QXLOG_SUPPORT(format, ...) \
    qxlog::Logger::instance().log(qxlog::SupportLevel, __FILE__, __LINE__, format, __VA_ARGS__)
#define QXLOG_ERROR(format, ...) \
    qxlog::Logger::instance().log(qxlog::ErrorLevel, __FILE__, __LINE__, format, __VA_ARGS__)
#define QXLOG_FATAL(format, ...) \
    qxlog::Logger::instance().log(qxlog::FatalLevel, __FILE__, __LINE__, format, __VA_ARGS__)

#endif // QXLOG_H

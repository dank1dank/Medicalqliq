#include "QxBaseDao.hpp"

namespace qx {
namespace dao {

namespace {

void logMissingColumnException(const SQLite::Exception& ex, SQLite::Statement& record, const char *columnName)
{
    QXLOG_ERROR("DB exception, cannot get column: '%s' for query: '%s' error: %s", columnName, record.getQuery().c_str(), ex.what());
}

} // anonymous

const char *getOptionalTextColumn(SQLite::Statement& record, const char *columnName, const char *defaultValue)
{
    try {
        return record.getColumn(columnName).getText();
    } catch (const SQLite::Exception& ex) {
        logMissingColumnException(ex, record, columnName);
        return defaultValue;
    }
}

int getOptionalIntColumn(SQLite::Statement& record, const char *columnName, int defaultValue)
{
    try {
        return record.getColumn(columnName).getInt();
    } catch (const SQLite::Exception& ex) {
        logMissingColumnException(ex, record, columnName);
        return defaultValue;
    }
}

} // dao
} // qx

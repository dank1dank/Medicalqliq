#ifndef QX_DBLOGRECORDBASEDAO_HPP
#define QX_DBLOGRECORDBASEDAO_HPP
#include <vector>
#include "qxlib/dao/QxBaseDao.hpp"
#include "qxlib/db/QxLogDatabase.hpp"

namespace qx {

/*
 * Base class with functionality shared between Web, SIP and CN db logs
 */
template <typename T>
class DbLogRecordBaseDao : public QxBaseDao<T>
{
public:
    static int keepLastMeaningfulSessions(int numberOfSessionsToKeep, SQLite::Database& db = LogDatabase::database())
    {
        const int MEANINGFUL_SESSION_ROW_COUNT_THRESHOLD = 10;

        int ret = 0;
        //std::string sql = "SELECT session, COUNT(*) FROM " + tableName + " WHERE session < :session GROUP BY session ORDER BY session DESC";
        std::string sql = "SELECT session, COUNT(*) FROM " + QxBaseDao<T>::tableName + " GROUP BY session ORDER BY session DESC";
        try {
            std::vector<std::pair<int, int> > sessions;
            {
                SQLite::Statement q(db, sql);
                //q.bind(":session", qxlog::Logger::instance().nextSequenceId());
                while (q.executeStep()) {
                    int id = q.getColumn(0).getInt();
                    int count = q.getColumn(1).getInt();
                    sessions.push_back(std::make_pair(id, count));
                }
            }

            if (!sessions.empty()) {
                int meaningfulSessionCount = 0;
                int lastSessionToKeep = sessions[0].first;

                for (const auto& p: sessions) {
//                    if (p.first == sessions[0].first) {
//                        // Always keep first, which is current session
//                        continue;
//                    }
                    if (meaningfulSessionCount < numberOfSessionsToKeep) {
                        if (p.second >= MEANINGFUL_SESSION_ROW_COUNT_THRESHOLD) {
                            meaningfulSessionCount++;
                        }

                        if (meaningfulSessionCount == numberOfSessionsToKeep) {
                            lastSessionToKeep = p.first;
                        }

                        //QXLOG_SUPPORT("Keeping session: %d with row count: %d", p.first, p.second);
                    } else {
                        //QXLOG_SUPPORT("Deleting session: %d with row count: %d", p.first, p.second);
                    }
                }
    #ifndef QT_NO_DEBUG
                if (lastSessionToKeep != 0) {
                    sql = "DELETE FROM " + QxBaseDao<T>::tableName + " WHERE session < :session";
                    SQLite::Statement q(db, sql);
                    q.bind(":session", lastSessionToKeep);
                    q.exec();
                }
    #endif
            }

        } catch (const SQLite::Exception& ex) {
            QXLOG_ERROR("DB exception for query: '%s' error: %s", sql.c_str(), ex.what());
        }
        return ret;
    }

    static std::vector<std::pair<int, int> > sessionsWithCount(const std::string& optionalWhere = {}, SQLite::Database& db = LogDatabase::database())
    {
        std::vector<std::pair<int, int> > ret;
        std::string sql = "SELECT session, COUNT(*) FROM " + QxBaseDao<T>::tableName +
                (optionalWhere.empty() ? "" : " WHERE " + optionalWhere) + " GROUP BY session ORDER BY session DESC";
        try {
            SQLite::Statement q(db, sql);
            while (q.executeStep()) {
                std::pair<int, int> p;
                p.first = q.getColumn(0).getInt();
                p.second = q.getColumn(1).getInt();
                ret.push_back(p);
            }
        } catch (const SQLite::Exception& ex) {
            QXLOG_ERROR("DB exception for query: '%s' error: %s", sql.c_str(), ex.what());
        }
        return ret;
    }
};

} // namespace qx

#endif // QX_DBLOGRECORDBASEDAO_HPP

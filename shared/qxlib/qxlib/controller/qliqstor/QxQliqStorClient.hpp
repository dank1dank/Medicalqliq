#ifndef QXQLIQSTORCLIENT_HPP
#define QXQLIQSTORCLIENT_HPP
#include <vector>
#ifndef SWIG
#include "qxlib/db/QxDatabase.hpp"
#endif // !SWIG

namespace qx {

class QliqStorClient
{
public:
    struct QliqStorPerGroup {
        std::string qliqStorQliqId;
        std::string groupQliqId;
        std::string groupName;

        bool isEmpty() const;
        std::string displayName() const;
    };
    static std::vector<QliqStorPerGroup> qliqStors(SQLite::Database& db = QxDatabase::database());
    static QliqStorPerGroup defaultQliqStor(SQLite::Database& db = QxDatabase::database());
    static void setDefaultQliqStor(const QliqStorPerGroup& qg, SQLite::Database& db = QxDatabase::database());

    // Returns true if there is no default qS saved and multiple qliqStors are available
    static bool shouldShowQliqStorSelectionDialog(SQLite::Database& db = QxDatabase::database());

private:
    QliqStorClient() = delete;
    ~QliqStorClient() = delete;
    static std::string defaultGroupQliqId(SQLite::Database& db = QxDatabase::database());
    static bool setDefaultGroupQliqId(const std::string& groupQliqId, SQLite::Database& db = QxDatabase::database());
};

} // qx

#endif // QXQLIQSTORCLIENT_HPP

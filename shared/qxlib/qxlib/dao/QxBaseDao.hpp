#ifndef QXBASEDAO_H
#define QXBASEDAO_H
#include <string>
#include <vector>
#include <map>
#include "qxlib/debug/QxAssert.hpp"
#include "qxlib/db/QxDatabase.hpp"
#include "qxlib/log/QxLog.hpp"
#include "qxlib/util/StringUtils.hpp"

#ifndef SWIG

#define QX_DAO_CATCH_BLOCK \
    catch (const SQLite::Exception& ex) { \
            QXLOG_ERROR("DB exception for query: '%s' error: %s", sql.c_str(), ex.what()); \
    }
#define QX_DAO_CATCH_BLOCK_CSTR \
    catch (const SQLite::Exception& ex) { \
            QXLOG_ERROR("DB exception for query: '%s' error: %s", sql, ex.what()); \
    }

namespace qx {
namespace dao {

struct Query {
    enum Operator {
        AndOperator,
        OrOperator
    };

    enum Order {
        AscOrder,
        DescOrder
    };

    enum Collation {
        NoneCollation,
        BinaryCollation,
        NoCaseCollation,
        RightTrimCollation
    };

    enum Condition {
        EqualCondition,
        NotEqualCondition,
        LessThenCondition,
        LessThenOrEqualCondition,
        GreaterThenCondition,
        GreaterThenOrEqualCondition,
        LikeCondition
    };

    typedef std::string variant;

    struct ColumnDesc {
        unsigned int column;
        variant value;
        Operator op;
        Condition condition;
        Collation collate;

        ColumnDesc(unsigned int column = 0, const variant& value = variant(),
                   Operator op = AndOperator, Condition condition = EqualCondition, Collation collate = NoneCollation) :
            column(column), value(value), op(op), condition(condition), collate(collate)
        {}
    };

    struct OtherColumnDesc {
        std::string tableName;
        std::string columnName;
        variant value;
        Operator op;
        Condition condition;
        Collation collate;

        OtherColumnDesc(const std::string& tableName, const std::string& columnName, const variant& value = variant(),
                   Operator op = AndOperator, Condition condition = EqualCondition, Collation collate = NoneCollation) :
            tableName(tableName), columnName(columnName), value(value), op(op), condition(condition), collate(collate)
        {}
    };

    struct ConditionsInParenthesis {
        Operator op = Operator::AndOperator;
        std::vector<OtherColumnDesc> select;
    };

    struct ColumnOrderPair {
        unsigned int column;
        Order order;

        ColumnOrderPair(unsigned int column = 0, Order order = AscOrder) :
            column(column), order(order)
        {}
    };

    struct JoinDesc {
        unsigned int column;
        std::string otherTableName;
        std::string otherColumnName;

        JoinDesc() :
            column(0)
        {}
    };

    std::vector<ColumnDesc> select;
    std::vector<ConditionsInParenthesis> conditionsInParenthesis;
    std::vector<ColumnOrderPair> orderBy;
    std::vector<JoinDesc> joins;
    std::vector<OtherColumnDesc> otherWhere;
    std::vector<std::string> customWhere;
    int skip;
    int limit;
    bool debugLogSql;

    Query() :
        skip(0), limit(0), debugLogSql(false)
    {}

    bool isEmpty() const
    {
        return select.empty() && conditionsInParenthesis.empty();
    }

    void append(unsigned int column, const variant& value, Operator op = AndOperator, Collation collate = NoneCollation)
    {
        select.emplace_back(column, value, op, EqualCondition, collate);
    }

    void and_(unsigned int column, Condition cond, const variant& value, Collation collate = NoneCollation)
    {
        select.emplace_back(column, value, AndOperator, cond, collate);
    }

    void and_(unsigned int column, const variant& value, Collation collate = NoneCollation)
    {
        select.emplace_back(column, value, AndOperator, EqualCondition, collate);
    }

    void or_(unsigned int column, Condition cond, const variant& value, Collation collate = NoneCollation)
    {
        select.emplace_back(column, value, OrOperator, cond, collate);
    }

    void or_(unsigned int column, const variant& value, Collation collate = NoneCollation)
    {
        select.emplace_back(column, value, OrOperator, EqualCondition, collate);
    }

    void appendOrder(unsigned int column, Order order = AscOrder)
    {
        orderBy.emplace_back(column, order);
    }

    void join(const std::string& otherTableName, const std::string& otherColumnName, unsigned int column)
    {
        JoinDesc jd;
        jd.otherTableName = otherTableName;
        jd.otherColumnName = otherColumnName;
        jd.column = column;
        joins.push_back(jd);
    }

    void otherAnd_(const std::string& tableName, const std::string& columnName, Condition cond, const variant& value, Collation collate = NoneCollation)
    {
        otherWhere.emplace_back(tableName, columnName, value, AndOperator, cond, collate);
    }

    void appendCustomWhere(const std::string& where)
    {
        customWhere.push_back(where);
    }

    static std::string formatSet(const std::initializer_list<std::string>& values)
    {
        std::string ret = "(";
        int i = 0;
        for (const auto& value: values) {
            if (i++ > 0) {
                ret += ", ";
            }
            ret += '\'';
            ret += value;
            ret += '\'';
        }
        ret += ")";
        return ret;
    }

    static std::string formatSet(const std::vector<std::string>& values)
    {
        std::string ret = "(";
        int i = 0;
        for (const auto& value: values) {
            if (i++ > 0) {
                ret += ", ";
            }
            ret += '\'';
            ret += value;
            ret += '\'';
        }
        ret += ")";
        return ret;
    }

    template <typename CONTAINER>
    static std::string formatSet(const CONTAINER& values)
    {
        std::string ret = "(";
        int i = 0;
        for (auto value: values) {
            if (i++ > 0) {
                ret += ", ";
            }
            ret += std::to_string(value);
        }
        ret += ")";
        return ret;
    }

    static const char *conditionToString(Condition condition)
    {
        switch (condition) {
        case Query::EqualCondition:
            return "=";
        case Query::NotEqualCondition:
            return "!=";
        case Query::LessThenCondition:
            return "<";
        case Query::LessThenOrEqualCondition:
            return "<=";
        case Query::GreaterThenCondition:
            return ">";
        case Query::GreaterThenOrEqualCondition:
            return ">=";
        case Query::LikeCondition:
            return "LIKE";
        }
        return "";
    }

    static const char *operatorToString(Operator op)
    {
        switch (op) {
        case AndOperator:
            return "AND";
        case OrOperator:
            return "OR";
        }
        return "";
    }

    static const char *collationToString(Collation collate)
    {
        switch (collate) {
        case Query::BinaryCollation:
            return " COLLATE BINARY";
        case Query::NoCaseCollation:
            return " COLLATE NOCASE";
        case Query::RightTrimCollation:
            return " COLLATE RTRIM ";
        case Query::NoneCollation:
            // avoid compiler's warning
            return "";
        }
        return "";
    }
};

typedef std::map<int, std::string> UpdateColumns;
typedef std::map<int, std::string> WhereColumns;

} // dao
} // qx

template <typename T>
class QxBaseDao
{
public:
    typedef T value_type;
    typedef std::string variant;

    static int insert(T *obj, SQLite::Database& db = QxDatabase::database())
    {
        int id = insert(const_cast<const T&>(*obj), db);
        if (autogeneratedPrimaryKey) {
            setPrimaryKey(obj, std::to_string(id));
        }
        return id;
    }

    static int insert(const T& obj, SQLite::Database& db = QxDatabase::database())
    {
        int ret = 0;
        std::string sql;
        try {
            sql = "INSERT INTO " + tableName + " (";
            const std::vector<std::string>::size_type startIndex = autogeneratedPrimaryKey ? 1 : 0;

            for (std::vector<std::string>::size_type i = startIndex; i < columnNames.size(); ++i) {
                if (i > startIndex) {
                    sql += ", ";
                }
                sql += columnNames[i];
            }
            sql += ") VALUES (";
            for (std::vector<std::string>::size_type i = startIndex; i < columnNames.size(); ++i) {
                if (i > startIndex) {
                    sql += ", ";
                }
                sql += ":" + columnNames[i];
            }
            sql += ")";

            SQLite::Statement q(db, sql);
            bind(q, obj, autogeneratedPrimaryKey);
            if (q.exec()) {
                ret = static_cast<int>(db.getLastInsertRowid());
            }
        } catch (const SQLite::Exception& ex) {
            QXLOG_ERROR("DB exception for query: '%s' error: %s", sql.c_str(), ex.what());
        }
        return ret;
    }

    static bool update(const T &obj, SQLite::Database& db = QxDatabase::database())
    {
        bool ret = false;
        std::string sql = "UPDATE " + tableName + " SET ";
        try {
            for (std::size_t i = 1; i < columnNames.size(); ++i) {
                if (i > 1) {
                    sql += ", ";
                }
                sql += columnNames[i] + " = :" + columnNames[i];
            }
            sql += " WHERE " + columnNames[0] + " = :" + columnNames[0];

            SQLite::Statement q(db, sql);
            bind(q, obj);
            ret = q.exec();
        } catch (const SQLite::Exception& ex) {
            QXLOG_ERROR("DB exception for query: '%s' error: %s", sql.c_str(), ex.what());
        }
        return ret;
    }

    static bool updateWhere(const T &obj, const std::string& where, bool skipBindPrimaryKey, SQLite::Database& db = QxDatabase::database())
    {
        bool ret = false;
        std::string sql = "UPDATE " + tableName + " SET ";
        try {
            for (std::size_t i = 1; i < columnNames.size(); ++i) {
                if (i > 1) {
                    sql += ", ";
                }
                sql += columnNames[i] + " = :" + columnNames[i];
            }
            sql += " WHERE " + where;

            SQLite::Statement q(db, sql);
            bind(q, obj, skipBindPrimaryKey);
            ret = q.exec();
        } catch (const SQLite::Exception& ex) {
            QXLOG_ERROR("DB exception for query: '%s' error: %s", sql.c_str(), ex.what());
        }
        return ret;
    }

    static bool update(const qx::dao::UpdateColumns& columns, const qx::dao::WhereColumns& where, SQLite::Database& db = QxDatabase::database())
    {
        bool ret = false;
        std::string sql = "UPDATE " + tableName + " SET ";
        try {
            int i = 0;
            for (const auto& kv: columns) {
                if (i > 0) {
                    sql += ", ";
                }
                int columnIndex = kv.first;
                qx_assert(columnIndex < columnNames.size());
                sql += columnNames[columnIndex] + " = :" + columnNames[columnIndex];
                ++i;
            }

            if (!where.empty()) {
                sql += " WHERE ";

                i = 0;
                for (const auto& kv: where) {
                    if (i > 0) {
                        sql += " AND ";
                    }
                    int columnIndex = kv.first;
                    qx_assert(columnIndex < columnNames.size());
                    sql += columnNames[columnIndex] + " = :where_" + columnNames[columnIndex];
                    ++i;
                }
            }

            SQLite::Statement q(db, sql);
            for (const auto& kv: columns) {
                int columnIndex = kv.first;
                q.bind(":" + columnNames[columnIndex], kv.second);
            }
            for (const auto& kv: where) {
                int columnIndex = kv.first;
                q.bind(":where_" + columnNames[columnIndex], kv.second);
            }
            ret = q.exec();
        } catch (const SQLite::Exception& ex) {
            QXLOG_ERROR("DB exception for query: '%s' error: %s", sql.c_str(), ex.what());
        }
        return ret;
    }

    static bool updateColumn(int column, const variant& value, const T &obj, SQLite::Database& db = QxDatabase::database())
    {
        qx_assert(column >= 0);
        qx_assert(column < columnNames.size());
        bool ret = false;
        std::string sql = "UPDATE " + tableName +
                " SET " + columnNames[column] + " = :value " +
                " WHERE " + primaryKeyColumn() + " = :pk";
        try {
            SQLite::Statement q(db, sql);
            q.bind(":value", value);
            q.bind(":pk", primaryKey(obj));
            ret = q.exec();
        } catch (const SQLite::Exception& ex) {
            QXLOG_ERROR("DB exception for query: '%s' error: %s", sql.c_str(), ex.what());
        }
        return ret;
    }

    static T selectOneBy(unsigned int column, const variant& value, int skip = 0, SQLite::Database& db = QxDatabase::database())
    {
        T ret;
        std::string sql = "SELECT * FROM " + tableName + " " + optionalJoinForSelect() + " WHERE " + columnNames[column] + " = :qvalue LIMIT 1 OFFSET " + std::to_string(skip);
        try {
            //if (0 <= column && column < ColumnCount) {
            SQLite::Statement q(db, sql);
            q.bind(":qvalue", value);
            if (q.executeStep()) {
                ret = fromQuery(q);
            }
        } catch (const SQLite::Exception& ex) {
            QXLOG_ERROR("DB exception for query: '%s' error: %s", sql.c_str(), ex.what());
        }
        return ret;
    }

    static T selectOneBy2(unsigned int column, const variant& value, int skip = 0, SQLite::Database& db = QxDatabase::database())
    {
        auto vec = selectBy(column, value, skip, 1, db);
        return (vec.empty() ? T() : vec[0]);
    }

    static bool selectOneInto(T *t, unsigned int column, const variant& value, int skip = 0, SQLite::Database& db = QxDatabase::database())
    {
        bool ret = false;
        std::string sql = "SELECT * FROM " + tableName + " " + optionalJoinForSelect() + " WHERE " + columnNames[column] + " = :qvalue LIMIT 1 OFFSET " + std::to_string(skip);
        try {
            SQLite::Statement q(db, sql);
            q.bind(":qvalue", value);
            if (q.executeStep()) {
                fillFromQuery(t, q);
                ret = true;
            }
        } catch (const SQLite::Exception& ex) {
            QXLOG_ERROR("DB exception for query: '%s' error: %s", sql.c_str(), ex.what());
        }
        return ret;
    }

    static std::vector<T> selectBy(unsigned int column, const variant& value, int skip = 0, int limit = 0, SQLite::Database& db = QxDatabase::database())
    {
        std::vector<T> ret;
        std::string sql = "SELECT * FROM " + tableName + " " + optionalJoinForSelect() + " WHERE " + columnNames[column] + " = :qvalue";
        try {
            //if (0 <= column && column < ColumnCount) {
                if (limit > 0) {
                    sql += " LIMIT " + std::to_string(limit);
                }
                if (skip > 0) {
                    sql += " OFFSET " + std::to_string(skip);
                }

                SQLite::Statement q(db, sql);
                q.bind(":qvalue", value);
                while (q.executeStep()) {
                    ret.push_back(fromQuery(q));
                }
            //}
        } catch (const SQLite::Exception& ex) {
            QXLOG_ERROR("DB exception for query: '%s' error: %s", sql.c_str(), ex.what());
        }
        return ret;
    }
/*
    template <typename CONT>
    static std::vector<T> selectBy(const CONT& columns, const CONT& values, int skip = 0, int limit = 0, SQLite::Database& db = QxDatabase::database())
    {
        std::vector<T> ret;
        std::string sql = "SELECT * FROM " + tableName + " " + optionalJoinForSelect() + " WHERE ";
        qx_assert(columns.size() == values.size());

        std::size_t i = 0;
        for (const auto column: columns) {
            if (i > 0) {
                sql += ", ";
            }
            sql += columnNames[column] + " = :qvalue" + std::to_string(i);
            ++i;
        }

        try {
            if (limit > 0) {
                sql += " LIMIT " + std::to_string(limit);
            }
            if (skip > 0) {
                sql += " OFFSET " + std::to_string(skip);
            }

            SQLite::Statement q(db, sql);

            std::size_t i = 0;
            for (const auto value: values) {
                q.bind(":qvalue" + std::to_string(i), value);
                ++i;
            }

            while (q.executeStep()) {
                ret.push_back(fromQuery(q));
            }
        } catch (const SQLite::Exception& ex) {
            QXLOG_ERROR("DB exception for query: '%s' error: %s", sql.c_str(), ex.what());
        }
        return ret;
    }
*/
    static std::vector<T> selectBy(const std::initializer_list<unsigned int>& columns, const std::initializer_list<const variant>& values, int skip = 0, int limit = 0, SQLite::Database& db = QxDatabase::database())
    {
        std::vector<T> ret;
        std::string sql = "SELECT * FROM " + tableName + " " + optionalJoinForSelect() + " WHERE ";
        qx_assert(columns.size() == values.size());

        std::size_t i = 0;
        for (const auto column: columns) {
            if (i > 0) {
                sql += ", ";
            }
            sql += columnNames[column] + " = :qvalue" + std::to_string(i);
            ++i;
        }

        try {
            if (limit > 0) {
                sql += " LIMIT " + std::to_string(limit);
            }
            if (skip > 0) {
                sql += " OFFSET " + std::to_string(skip);
            }

            SQLite::Statement q(db, sql);

            std::size_t i = 0;
            for (const auto value: values) {
                q.bind(":qvalue" + std::to_string(i), value);
                ++i;
            }

            while (q.executeStep()) {
                ret.push_back(fromQuery(q));
            }
        } catch (const SQLite::Exception& ex) {
            QXLOG_ERROR("DB exception for query: '%s' error: %s", sql.c_str(), ex.what());
        }
        return ret;
    }

    static int count(const qx::dao::Query& query, SQLite::Database& db = QxDatabase::database())
    {
        int count = 0;
        selectGeneric("COUNT(*)", [&count](SQLite::Statement& q) {
            count = q.getColumn(0).getInt();
        }, query, db);
        return count;
    }

    static int exists(qx::dao::Query& query, SQLite::Database& db = QxDatabase::database())
    {
        query.limit = 1;
        int primaryKey = 0;
        selectGeneric(primaryKeyColumn(), [&primaryKey](SQLite::Statement& q) {
            primaryKey = q.getColumn(0).getInt();
        }, query, db);
        return primaryKey;
    }

    static std::vector<T> select(const qx::dao::Query& query, SQLite::Database& db = QxDatabase::database())
    {
        std::vector<T> ret;
        selectGeneric(tableName + ".*", [&ret](SQLite::Statement& q) {
            ret.push_back(fromQuery(q));
        }, query, db);
        return ret;
    }

    static T selectOne(qx::dao::Query& query, SQLite::Database& db = QxDatabase::database())
    {
        query.limit = 1;

        T ret;
        selectGeneric(tableName + ".*", [&ret](SQLite::Statement& q) {
            ret = fromQuery(q);
        }, query, db);
        return ret;
    }

    template <typename Callback>
    static T selectOneJoin(qx::dao::Query& query, const std::string& extraSelect, Callback callback, SQLite::Database& db = QxDatabase::database())
    {
        query.limit = 1;

        T ret;
        selectGeneric(tableName + ".*" + extraSelect, [&ret,callback](SQLite::Statement& q) {
            ret = fromQuery(q);
            callback(ret, q);
        }, query, db);
        return ret;
    }

    static std::vector<T> selectByAnd(const std::vector<unsigned int>& columns, const std::vector<variant>& values, int skip = 0, int limit = 0, SQLite::Database& db = QxDatabase::database())
    {
        std::vector<T> ret;
        std::string sql = "SELECT * FROM " + tableName + " " + optionalJoinForSelect() + " WHERE ";
        qx_assert(columns.size() == values.size());

        std::size_t i = 0;
        for (const auto column: columns) {
            if (i > 0) {
                sql += " AND ";
            }
            sql += columnNames[column] + " = :qvalue" + std::to_string(i);
            ++i;
        }

        try {
            if (limit > 0) {
                sql += " LIMIT " + std::to_string(limit);
            }
            if (skip > 0) {
                sql += " OFFSET " + std::to_string(skip);
            }

            SQLite::Statement q(db, sql);

            std::size_t i = 0;
            for (const auto value: values) {
                q.bind(":qvalue" + std::to_string(i), value);
                ++i;
            }

            while (q.executeStep()) {
                ret.push_back(fromQuery(q));
            }
        } catch (const SQLite::Exception& ex) {
            QXLOG_ERROR("DB exception for query: '%s' error: %s", sql.c_str(), ex.what());
        }
        return ret;
    }

    static bool insertOrUpdate(const T &obj, SQLite::Database& db = QxDatabase::database())
    {
        bool ret = false;
        if (exists(primaryKey(obj), db))
            ret = update(obj, db);
        else
            ret = insert(obj, db);

        return ret;
    }

    static bool insertOrUpdate(T *obj, SQLite::Database& db = QxDatabase::database())
    {
        bool ret = false;
        if (exists(primaryKey(*obj), db)) {
            ret = update(*obj, db);
        } else {
            auto id = insert(*obj, db);
            setPrimaryKey(obj, id);
            ret = id > 0;
        }

        return ret;
    }

    static int deleteAll(SQLite::Database& db = QxDatabase::database())
    {
        int ret = 0;
        const std::string sql = "DELETE FROM " + tableName;
        try {
            SQLite::Statement q(db, sql);
            ret = q.exec();
        } catch (const SQLite::Exception& ex) {
            QXLOG_ERROR("DB exception for query: '%s' error: %s", sql.c_str(), ex.what());
            ret = -1;
        }
        return ret;
    }

    static bool delete_(unsigned int column, const variant& value, SQLite::Database& db = QxDatabase::database())
    {
        qx_assert(column < columnNames.size());
        bool ret = false;
        const std::string sql = "DELETE FROM " + tableName + " WHERE " + columnNames[column] + " = :value";
        try {
            SQLite::Statement q(db, sql);
            q.bind(":value", value);
            ret = q.exec();
        } catch (const SQLite::Exception& ex) {
            QXLOG_ERROR("DB exception for query: '%s' error: %s", sql.c_str(), ex.what());
        }
        return ret;
    }

    static bool exists(const variant& primaryKey, SQLite::Database& db = QxDatabase::database())
    {
        bool ret = false;
        const std::string sql = "SELECT " + primaryKeyColumn() + " FROM " + tableName + " WHERE " + primaryKeyColumn() + " = :pk LIMIT 1";
        try {
            SQLite::Statement q(db, sql);
            q.bind(":pk", primaryKey);
            ret = q.executeStep();
        } catch (const SQLite::Exception& ex) {
            QXLOG_ERROR("DB exception for query: '%s' error: %s", sql.c_str(), ex.what());
        }
        return ret;
    }

    static bool exists(unsigned int column, const variant& value, SQLite::Database& db = QxDatabase::database())
    {
        qx_assert(column < columnNames.size());
        bool ret = false;
        const std::string sql = "SELECT " + columnNames[column] + " FROM " + tableName + " WHERE " + columnNames[column] + " = :value LIMIT 1";
        try {
            SQLite::Statement q(db, sql);
            q.bind(":value", value);
            ret = q.executeStep();
        } catch (const SQLite::Exception& ex) {
            QXLOG_ERROR("DB exception for query: '%s' error: %s", sql.c_str(), ex.what());
        }
        return ret;
    }

    static int count(SQLite::Database& db = QxDatabase::database())
    {
        int ret = 0;
        const std::string sql = "SELECT COUNT(*) FROM " + tableName;
        try {
            SQLite::Statement q(db, sql);
            if (q.executeStep()) {
                ret = q.getColumn(0).getInt();
            }
        } catch (const SQLite::Exception& ex) {
            QXLOG_ERROR("DB exception for query: '%s' error: %s", sql.c_str(), ex.what());
        }
        return ret;
    }

    static int count(unsigned int column, const variant& value, SQLite::Database& db = QxDatabase::database())
    {
        qx_assert(column < columnNames.size());
        int ret = 0;
        const std::string sql = "SELECT COUNT(*) FROM " + tableName + " WHERE " + columnNames[column] + " = :value";
        try {
            SQLite::Statement q(db, sql);
            q.bind(":value", value);
            if (q.executeStep()) {
                ret = q.getColumn(0).getInt();
            }
        } catch (const SQLite::Exception& ex) {
            QXLOG_ERROR("DB exception for query: '%s' error: %s", sql.c_str(), ex.what());
        }
        return ret;
    }

    static int count(unsigned int column,
                     const std::vector<std::string>& values,
                     const qx::dao::Query::Condition condition,
                     bool valuesAreStrings,
                     SQLite::Database& db = QxDatabase::database()) {
        qx_assert(column < columnNames.size());
        int ret = 0;
        std::string sql = "SELECT COUNT(*) FROM " + tableName + " WHERE ";

        using qx::dao::Query;
        bool firstValue = true;
        for (std::string value: values) {
            value = StringUtils::trim(value);
            if (firstValue) {
                firstValue = false;
            } else {
                sql += " OR ";
            }
            sql += columnNames[column] + " ";
            sql += Query::conditionToString(condition);

            sql.push_back(' ');
            if (valuesAreStrings) {
                sql.push_back('\'');
            }
            sql += value;
            if (valuesAreStrings) {
                sql.push_back('\'');
            }
        }

        try {
            SQLite::Statement q(db, sql);
            if (q.executeStep()) {
                ret = q.getColumn(0).getInt();
            }
        } catch (const SQLite::Exception& ex) {
            QXLOG_ERROR("DB exception for query: '%s' error: %s", sql.c_str(), ex.what());
        }
        return ret;
    }

    static std::string primaryKeyColumn()
    {
        return columnNames[0];
    }

    static std::string optionalJoinForSelect()
    {
        return "";
    }

    static variant primaryKey(const T& obj);
    static void setPrimaryKey(T *obj, const variant& key);
    static void bind(SQLite::Statement& q, const T& obj, bool skipPrimaryKey = false);
    static T fromQuery(SQLite::Statement& query);
    static void fillFromQuery(T *t, SQLite::Statement& query);

    static const bool autogeneratedPrimaryKey;
    static const std::string tableName;
    static const std::vector<std::string> columnNames;

protected:
    static std::size_t toString(std::string& sql, std::size_t paramIndex, const std::vector<qx::dao::Query::ColumnDesc>& select, bool hasJoin)
    {
        using qx::dao::Query;
        std::size_t i = paramIndex;
        bool isFirstElement = true;

        for (const auto& cv: select) {
            if (isFirstElement) {
                isFirstElement = false;
            } else {
                if (cv.op == Query::AndOperator) {
                    sql += " AND ";
                } else {
                    sql += " OR ";
                }
            }
            if (hasJoin) {
                sql += tableName;
                sql += '.';
            }
            sql += columnNames[cv.column] + " ";
            sql += Query::conditionToString(cv.condition);
            sql += " :qvalue" + std::to_string(i);
            sql += Query::collationToString(cv.collate);

            ++i;
        }

        return i;
    }

    template <typename Fun>
    static void selectGeneric(const std::string& resultColumns, Fun fun, const qx::dao::Query& query, SQLite::Database& db = QxDatabase::database())
    {
        using qx::dao::Query;

        std::string sql = "SELECT " + resultColumns + " FROM " + tableName + " " + optionalJoinForSelect();

        bool hasJoin = !query.joins.empty() || !optionalJoinForSelect().empty();
        for (const Query::JoinDesc& jd: query.joins) {
            sql += " INNER JOIN " + jd.otherTableName + " ON ";
            sql += jd.otherTableName + "." + jd.otherColumnName + " = " + tableName + "." + columnNames[jd.column];
        }

        if (!query.select.empty() || !query.otherWhere.empty() || !query.customWhere.empty() || !query.conditionsInParenthesis.empty()) {
            sql += " WHERE ";
        }

        std::size_t i = toString(sql, 0, query.select, hasJoin);

        for (const auto& parenthesis: query.conditionsInParenthesis) {
            if (!parenthesis.select.empty()) {
                if (i > 0) {
                    sql.push_back(' ');
                    sql += Query::operatorToString(parenthesis.op);
                    sql.push_back(' ');
                }
                sql.push_back('(');

                bool isFirstElement = true;
                for (const auto& cv: parenthesis.select) {
                    if (isFirstElement) {
                        isFirstElement = false;
                    } else {
                        if (cv.op == Query::AndOperator) {
                            sql += " AND ";
                        } else {
                            sql += " OR ";
                        }
                    }
                    sql += cv.tableName;
                    sql += '.';
                    sql += cv.columnName + " ";
                    sql += Query::conditionToString(cv.condition);
                    sql += " :qvalue" + std::to_string(i);
                    sql += Query::collationToString(cv.collate);

                    ++i;
                }
                sql.push_back(')');
            }
        }

        for (const Query::OtherColumnDesc& cv: query.otherWhere) {
            if (i > 0) {
                sql.push_back(' ');
                sql += Query::operatorToString(cv.op);
                sql.push_back(' ');
            }
            sql += cv.tableName;
            sql += '.';
            sql += cv.columnName + " ";
            sql += Query::conditionToString(cv.condition);

            sql += " :qvalue" + std::to_string(i);
            sql += Query::collationToString(cv.collate);

            ++i;
        }

        for (const std::string& condition: query.customWhere) {
            sql.push_back(' ');
            sql.append(condition);
            sql.push_back(' ');
        }

        i = 0;
        for (const auto& o: query.orderBy) {
            if (i == 0) {
                sql += " ORDER BY ";
            } else {
                sql += ", ";
            }
            if (hasJoin) {
                sql += tableName;
                sql += '.';
            }
            sql += columnNames[o.column];
            if (o.order == Query::DescOrder) {
                sql += " DESC";
            }
            ++i;
        }

        try {
            if (query.limit > 0) {
                sql += " LIMIT " + std::to_string(query.limit);
            }
            if (query.skip > 0) {
                sql += " OFFSET " + std::to_string(query.skip);
            }

            if (query.debugLogSql) {
                QXLOG_DEBUG("SQL: %s", sql.c_str());
            }

            SQLite::Statement q(db, sql);

            std::string debugBoundValues;
            std::size_t i = 0;
            for (const Query::ColumnDesc& cv: query.select) {
                q.bind(":qvalue" + std::to_string(i), cv.value);
                if (query.debugLogSql) {
                    debugBoundValues += std::to_string(i);
                    debugBoundValues.push_back(':');
                    debugBoundValues += cv.value;
                    debugBoundValues += "; ";
                }
                ++i;
            }

            for (const auto& parenthesis: query.conditionsInParenthesis) {
                for (const Query::OtherColumnDesc& cv: parenthesis.select) {
                    q.bind(":qvalue" + std::to_string(i), cv.value);
                    if (query.debugLogSql) {
                        debugBoundValues += std::to_string(i);
                        debugBoundValues.push_back(':');
                        debugBoundValues += cv.value;
                        debugBoundValues += "; ";
                    }
                    ++i;
                }
            }

            for (const Query::OtherColumnDesc& cv: query.otherWhere) {
                q.bind(":qvalue" + std::to_string(i), cv.value);
                if (query.debugLogSql) {
                    debugBoundValues += std::to_string(i);
                    debugBoundValues.push_back(':');
                    debugBoundValues += cv.value;
                    debugBoundValues += "; ";
                }
                ++i;
            }

            if (query.debugLogSql) {
                QXLOG_DEBUG("Bound values: %s", debugBoundValues.c_str());
            }

            while (q.executeStep()) {
                fun(q);
            }
        } catch (const SQLite::Exception& ex) {
            QXLOG_ERROR("DB exception for query: '%s' error: %s", sql.c_str(), ex.what());
        }
    }
};

template <typename T, typename U>
class QxJoinedDao : public QxBaseDao<T> {
public:
    typedef std::string variant;

    static unsigned int joinOtherColumn();
    static unsigned int joinSelfColumn();
    static typename U::value_type *joinedObject(T& obj);

    static std::vector<T> selectJoined(qx::dao::Query& query, SQLite::Database& db = QxDatabase::database())
    {
        query.join(U::tableName, U::columnNames[joinOtherColumn()], joinSelfColumn());

        std::string extraSelect;
        for (const auto& columnName: U::columnNames) {
            extraSelect.append(", ");

            // full column name
            extraSelect.append(U::tableName);
            extraSelect.push_back('.');
            extraSelect.append(columnName);

            // alias
            extraSelect.append(" AS ");
            extraSelect.append(U::tableName);
            extraSelect.push_back('_');
            extraSelect.append(columnName);
        }

        std::vector<T> ret;
        QxBaseDao<T>::selectGeneric(QxBaseDao<T>::tableName + ".*" + extraSelect, [&ret](SQLite::Statement& q) {
            ret.push_back(QxBaseDao<T>::fromQuery(q));
            T& obj = *(--ret.end());
            U::fillFromQuery(joinedObject(obj), q, U::tableName + "_");
        }, query, db);
        return ret;
    }

    static std::vector<T> selectJoined(unsigned int column, const variant& value, int skip = 0, int limit = 0, SQLite::Database& db = QxDatabase::database())
    {
        qx::dao::Query query;
        query.append(column, value);
        query.limit = limit;
        query.skip = skip;

        return selectJoined(query, db);
    }

    static T selectOneJoined(unsigned int column, const variant& value, int skip = 0, SQLite::Database& db = QxDatabase::database())
    {
        qx::dao::Query query;
        query.append(column, value);
        query.limit = 1;
        query.skip = skip;

        auto vec = selectJoined(query, db);
        if (!vec.empty()) {
            return vec[0];
        } else {
            return T();
        }
    }
};

namespace qx {
namespace dao {

const char *getOptionalTextColumn(SQLite::Statement& record, const char *columnName, const char *defaultValue = "");
int getOptionalIntColumn(SQLite::Statement& record, const char *columnName, int defaultValue = 0);

} // dao
} // qx

#endif // !SWIG

#endif // QXBASEDAO_H

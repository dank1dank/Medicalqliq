#include "QxPlatformQtHelpers.hpp"
#include "json/qt-json/qtjson.h"

namespace qx {

json11::Json toJson(const QVariantMap &map)
{
    QString str = Json::toJson(map);
    std::string parsingError;
    return json11::Json::parse(toStd(str), parsingError);
}

QString toQt(const std::string& str)
{
//    return QString::fromStdString(str);
    return QString::fromUtf8(str.c_str(), static_cast<int>(str.size()));
}

std::string toStd(const QString& str)
{
//    return str.toStdString();
    const QByteArray& data = str.toUtf8();
    return std::string(data.constData(), static_cast<std::string::size_type>(data.size()));
}

std::string toStdLocal(const QString &str)
{
    const QByteArray& data = str.toLocal8Bit();
    return std::string(data.constData(), static_cast<std::string::size_type>(data.size()));
}

QVariant toVariant(const json11::Json &json)
{
    switch (json.type()) {
    case json11::Json::BOOL:
        return json.bool_value();

    case json11::Json::NUMBER:
        // TODO: JSON does not distinguish between double and int
        // however since in our app we basically only use int, so I use int here
        return json.int_value();

    case json11::Json::STRING:
        return qx::toQt(json.string_value());

    case json11::Json::ARRAY:
    {
        QVariantList list;
        for (const auto& e: json.array_items()) {
            list.append(toVariant(e));
        }
        return list;
    }

    case json11::Json::OBJECT:
    {
        QVariantMap obj;
        for (const auto& kv: json.object_items()) {
            obj[qx::toQt(kv.first)] = toVariant(kv.second);
        }
        return obj;
    }

    case json11::Json::NUL:
        return QVariant();
    }
}

} // qx

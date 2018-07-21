#ifndef QXPLATFORMQTHELPERS_HPP
#define QXPLATFORMQTHELPERS_HPP
#include <QString>
#include <QVariantMap>
#include "json11/json11.hpp"

namespace qx {

template <template<class> class CONTAINER>
std::vector<std::string> toStdVector(const CONTAINER<QString>& cont)
{
    std::vector<std::string> ret;
    ret.reserve(cont.size());

    for (int i = 0; i < cont.size(); ++i) {
        ret.emplace_back(cont[i].toStdString());
    }

    return ret;
}

template <class CONTAINER>
std::vector<std::string> toStdVector(const CONTAINER& cont)
{
    std::vector<std::string> ret;
    ret.reserve(cont.size());

    for (int i = 0; i < cont.size(); ++i) {
        ret.emplace_back(cont[i].toStdString());
    }

    return ret;
}

json11::Json toJson(const QVariantMap& map);
QVariant toVariant(const json11::Json& json);

QString toQt(const std::string& str);
std::string toStd(const QString& str);
std::string toStdLocal(const QString& str);

} // qx

#endif // QXPLATFORMQTHELPERS_HPP

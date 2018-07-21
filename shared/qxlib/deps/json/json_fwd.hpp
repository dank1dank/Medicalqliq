#ifndef NLOHMANN_JSON_FWD_HPP
#define NLOHMANN_JSON_FWD_HPP
#include "json.hpp"

class json : public nlohmann::json
{
public:
    //using basic_json<>::basic_json;
    json()
    {}

    json(const value_t value_type) :
        nlohmann::json(value_type)
    {}

    json(const nlohmann::json& j) :
        nlohmann::json(j)
    {}
};

#endif // NLOHMANN_JSON_FWD_HPP

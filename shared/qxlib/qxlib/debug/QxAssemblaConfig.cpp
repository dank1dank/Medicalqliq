#include "QxAssemblaConfig.hpp"

#define DEFAULT_API_KEY "579deacad2240648ae9c"
#define DEFAULT_API_SECRET "e1077eb5a67c6892f1f81befeb49439a076161b0"

#define ADD_NON_EMPTY(field, key) if (!field.empty()) { json[key] = field; }
#define ADD_NON_ZERO(field, key)  if (field != 0)     { json[key] = field; }

using namespace json11;

namespace qx {

std::string AssemblaConfig::baseUrl()
{
    return "https://api.assembla.com/v1/spaces/";
}

std::string AssemblaConfig::baseUrlWithNamespace()
{
    return baseUrl() + namespaceName();
}

std::string AssemblaConfig::viewTicketUrlWithNamespace()
{
    return "https://app.assembla.com/spaces/" + namespaceName() + "/tickets/";
}

std::string AssemblaConfig::apiKey()
{
    return DEFAULT_API_KEY;
}

std::string AssemblaConfig::apiSecret()
{
    return DEFAULT_API_SECRET;
}

std::string AssemblaConfig::namespaceName()
{
#ifdef QXL_DEVICE_PC
    return "qliqDesktop";
#endif
}

std::string AssemblaConfig::spaceId()
{
#ifdef QXL_DEVICE_PC
    return "b2PbdcJlWr4l2NeJe4gwI3";
#endif
}

AssemblaUser AssemblaConfig::defaultAssignee()
{
    AssemblaUser u;
#ifdef QXL_DEVICE_PC
    u.id = "aIFTjiNfCr4jageJe5cbCb";
    u.login = "strixcode";
    u.name = "Adam Sowa";
#endif
    return u;
}

AssemblaUser AssemblaConfig::defaultReporter()
{
    AssemblaUser u;
    u.id = "dITozeiVqr47BdacwqjQXA";
    u.login = u.name = "93sree";
    return u;
}

bool AssemblaUser::isEmpty() const
{
    return id.empty();
}

Json AssemblaUser::toJson() const
{
    Json::object json;
    ADD_NON_EMPTY(id, "id");
    ADD_NON_EMPTY(login, "login");
    ADD_NON_EMPTY(name, "name");
    ADD_NON_EMPTY(email, "email");
    return json;
}

AssemblaUser AssemblaUser::fromJson(const Json &json)
{
    AssemblaUser ret;
    ret.id = json["id"].string_value();
    ret.login = json["login"].string_value();
    ret.name = json["name"].string_value();
    ret.email = json["email"].string_value();
    return ret;
}

bool AssemblaUser::lessThen(const AssemblaUser &a, const AssemblaUser &b)
{
    return a.name < b.name;
}

bool AssemblaTicket::isEmpty() const
{
    return number == 0;
}

std::string AssemblaTicket::url() const
{
    std::string ret;
    if (number) {
        ret = AssemblaConfig::viewTicketUrlWithNamespace() + std::to_string(number);
    }
    return ret;
}

json11::Json AssemblaTicket::toJson() const
{
    Json::object json;
    json["summary"] = summary;

    ADD_NON_EMPTY(description, "description");
    ADD_NON_ZERO(id, "id");
    ADD_NON_ZERO(number, "number");
    ADD_NON_EMPTY(reporterId, "reporter_id");
    ADD_NON_EMPTY(assignedToId, "assigned_to_id");
    if (priority != NormalPriority) { json["priority"] = priority; }
    ADD_NON_EMPTY(followers, "followers");

    return json;
}

AssemblaTicket AssemblaTicket::fromJson(const json11::Json &json)
{
    AssemblaTicket ret;
    ret.summary = json["summary"].string_value();
    ret.description = json["description"].string_value();
    ret.id = json["id"].int_value();
    ret.number = json["number"].int_value();
    ret.reporterId = json["reporter_id"].string_value();
    ret.assignedToId = json["assigned_to_id"].string_value();
    int p = json["priority"].int_value();
    if (p >= HighestPriority && p <= LowestPriority) {
        ret.priority = static_cast<Priority>(p);
    }
    if (json["followers"].is_array()) {
        auto followers = json["followers"].array_items();
        for (const auto& jsonItem: followers) {
            ret.followers.push_back(jsonItem.string_value());
        }
    }
    return ret;
}

bool AssemblaDocument::isEmpty() const
{
    return id.empty();
}

Json AssemblaDocument::toJson() const
{
    Json::object json;
    ADD_NON_EMPTY(toString(attachableType), "attachable_type");
    ADD_NON_EMPTY(attachableGuid, "attachable_guid");
    ADD_NON_ZERO(attachableId, "attachable_id");
    ADD_NON_EMPTY(description, "description");
    ADD_NON_EMPTY(file, "file");
    ADD_NON_EMPTY(fileName, "filename");
    ADD_NON_EMPTY(name, "name");
    return json;
}

AssemblaDocument AssemblaDocument::fromJson(const Json &json)
{
    AssemblaDocument ret;
    ret.id = json["id"].string_value();
    ret.createdAt = json["created_at"].string_value();
    ret.createdBy = json["created_by"].string_value();
    ret.updatedAt = json["updated_at"].string_value();
    ret.updatedBy = json["updated_by"].string_value();
    ret.version = json["version"].int_value();
    ret.description = json["description"].string_value();
    ret.position = json["position"].int_value();

    ret.fileName = json["file_name"].string_value();
    ret.fileSize = static_cast<unsigned int>(json["filesize"].number_value());
    ret.name = json["name"].string_value();
    ret.contentType = json["content_type"].string_value();
    ret.hasThumbnail = json["has_thumbnail"].bool_value();

    ret.ticketId = json["ticket_id"].int_value();
    ret.attachableId = json["attachable_id"].int_value();
    ret.attachableGuid = json["attachable_guid"].string_value();

    std::string type = json["attachable_type"].string_value();
    if (type == "Ticket") {
        ret.attachableType = AttachableType::Ticket;
    } else if (type == "Flow") {
        ret.attachableType = AttachableType::Flow;
    } else if (type == "Milestone") {
        ret.attachableType = AttachableType::Milestone;
    }

    ret.spaceId = json["space_id"].string_value();
    ret.url = json["url"].string_value();

    return ret;
}

std::string AssemblaDocument::toString(AttachableType type)
{
    switch (type) {
    case AttachableType::None:
        return "";
    case AttachableType::Ticket:
        return "Ticket";
    case AttachableType::Flow:
        return "Flow";
    case AttachableType::Milestone:
        return "Milestone";
    }
}

} // qx

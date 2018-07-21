#ifndef QXASSEMBLACONFIG_HPP
#define QXASSEMBLACONFIG_HPP
#include <string>
#include "json11/json11.hpp"

namespace qx {

struct AssemblaUser {
    std::string id;
    std::string login;
    std::string name;
    std::string email; // can be hidden

    bool isEmpty() const;
    json11::Json toJson() const;
    static AssemblaUser fromJson(const json11::Json& json);
    static bool lessThen(const AssemblaUser& a, const AssemblaUser& b);
};

struct AssemblaTicket {
    enum Priority {
        HighestPriority = 1,
        HighPriority = 2,
        NormalPriority = 3,
        LowPriority = 4,
        LowestPriority = 5
    };

    std::string summary;
    std::string description;
    int id = 0;
    int number = 0;
    std::string reporterId;
    std::string assignedToId;
    Priority priority = Priority::NormalPriority;
    std::vector<std::string> followers;

    bool isEmpty() const;
    std::string url() const;
    json11::Json toJson() const;
    static AssemblaTicket fromJson(const json11::Json& json);
};

struct AssemblaDocument {
    enum class AttachableType {
        None,
        Ticket,
        Flow,
        Milestone
    };

    std::string id;
    std::string createdAt;
    std::string createdBy;
    std::string updatedAt;
    std::string updatedBy;
    int version = 0;
    std::string description;
    int position = 0;

    unsigned int fileSize = 0;
    std::string fileName;
    std::string file; // body
    std::string filePath; // our extension to implement reading file during web upload
    std::string name;
    std::string contentType;
    bool hasThumbnail = false;

    int attachableId = 0;
    std::string attachableGuid;
    AttachableType attachableType = AttachableType::None;
    int ticketId = 0;

    std::string spaceId;
    std::string url;

    bool isEmpty() const;
    json11::Json toJson() const;
    static AssemblaDocument fromJson(const json11::Json& json);
    static std::string toString(AttachableType type);
};

class AssemblaConfig
{
public:
    static std::string baseUrl();
    static std::string baseUrlWithNamespace();
    static std::string viewTicketUrlWithNamespace();

    static std::string apiKey();
    static std::string apiSecret();
    static std::string namespaceName();
    static std::string spaceId();

    static AssemblaUser defaultAssignee();
    static AssemblaUser defaultReporter();

};

} // qx

#endif // QXASSEMBLACONFIG_HPP

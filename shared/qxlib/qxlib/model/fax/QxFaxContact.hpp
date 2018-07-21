#ifndef QXFAXCONTACT_HPP
#define QXFAXCONTACT_HPP
#include <string>

namespace qx {

class FaxContact
{
public:
    int databaseId = 0;
    std::string uuid;
    std::string faxNumber;
    std::string voiceNumber;
    std::string organization;
    std::string contactName;

    bool isCreatedByUser = false;
    std::string groupQliqId;

    bool isEmpty() const;
    std::string toMultiLineString() const;
};

} // qx

#endif // QXFAXCONTACT_HPP

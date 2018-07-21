#include "QxFaxContact.hpp"

namespace qx {

bool FaxContact::isEmpty() const
{
    return faxNumber.empty();
}

std::string FaxContact::toMultiLineString() const
{
    std::string ret = "Fax: ";
    ret.append(faxNumber);

    if (!organization.empty()) {
        ret.append("\nOrganization: ");
        ret.append(organization);
    }

    if (!contactName.empty()) {
        ret.append("\nContact Name: ");
        ret.append(contactName);
    }

    return ret;
}

} // qx

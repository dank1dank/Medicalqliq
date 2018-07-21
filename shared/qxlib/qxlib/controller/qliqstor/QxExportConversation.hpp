#ifndef QXEXPORTCONVERSATION_HPP
#define QXEXPORTCONVERSATION_HPP
#include <string>
#include <vector>

namespace qx {

class ExportConversation
{
public:
    struct ConversationMessageList {
        std::string conversationUuid;
        std::vector<std::string> messageUuids;
    };

    static std::string toRtf(const ConversationMessageList &conversationOrMessages);
    static bool toRtf(const ConversationMessageList &conversationOrMessages, const std::string& filePath);
};

} // qx

#endif // QXEXPORTCONVERSATION_HPP

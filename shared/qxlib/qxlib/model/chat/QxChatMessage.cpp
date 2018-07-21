#include "QxChatMessage.hpp"
#include "qxlib/log/QxLog.hpp"
#include "qxlib/dao/QxQliqUserDao.hpp"

namespace qx {

void ChatMessageListener::onChatMessageStatusChanged(const ChatMessage&)
{
}

void ChatMessageListener::onChatMessageReceived(const ChatMessage&)
{
}

ChatMessageListener::~ChatMessageListener()
{
}

bool ChatMessage::isEmpty() const
{
    return id == 0;
}

std::string ChatMessage::typeToString(ChatMessage::Type type)
{
    switch (type) {
    case Type::Unknown:
    case Type::Regular:
        return "";
    case Type::Event:
        return "event";
    }
    QXLOG_FATAL("Uknown ChatMessage::Type: %d", static_cast<int>(type));
    return "";
}

std::string ChatMessage::timestampToString(time_t timestamp)
{
    char buffer[80];
    struct tm *timeinfo = localtime(&timestamp);
    size_t ret = strftime(buffer, sizeof(buffer), "%b %d %Y, %I:%M %p", timeinfo);
    return buffer;
}

MessageStatusLog::MessageStatusLog()
{
}

MessageStatusLog::MessageStatusLog(int messageId) :
    messageId(messageId)
{
}

bool MessageStatusLog::isEmpty() const
{
    return entries.empty();
}

std::string MessageStatusLog::statusToText(int status)
{
    switch (static_cast<Status>(status)) {
    case Status::TextFromServer:
        return "Text From Server";
    case Status::Created:
        return "Created";
    case Status::Sending:
        return "Sending...";
    case Status::Received:
        return "Received (by this device)";
    case Status::AckSending:
        return "Sending Ack...";
    case Status::AckReceived:
        return "Ack Received";
    case Status::AckSentToServer:
        return "Ack Sent";
    case Status::AckDelivered:
        return "Ack Delivered";
    case Status::AckSynced:
        return "Ack Synced";
    case Status::Read:
        return "Read";
    case Status::Pending:
        return "Waiting for Recipient";
    case Status::UserLoggedOut:
        return "User Logged Out";
    case Status::Delivered:
        return "Delivered";
    case Status::Synced:
        return "Synced";
    case Status::Sent:
        return "Sent";
    case Status::ReceivedByAnotherDevice:
        return "Received (by another device)";
    case Status::Recalled:
        return "Recalled";
    case Status::SentToQliqStor:
        return "Sent to qliqStor";
    case Status::PushNotificationSentByServer:
        return "Push Notification Sent By Server";
    default:
        return "Status " + std::to_string(status);
        //return core::connect::ChatMessage::deliveryErrorString(status);
    }
}

std::string MessageStatusLog::statusToText(const std::string &statusTextFromServer, int statusArg, const std::string &qliqId, int totalRecipientCount)
{
    Status status = static_cast<Status>(statusArg);
    std::string text = MessageStatusLog::statusToText(statusArg);
    if (!qliqId.empty()) {
        std::string displayName;
        QliqUser u = QliqUserDao::selectOneBy(QliqUserDao::QliqIdColumn, qliqId);
        if (u.isEmpty()) {
            displayName = "unknown user (" + qliqId + ")";
        } else {
            displayName = u.displayName();
        }

        if (!statusTextFromServer.empty()) {
            text = displayName + ": " + statusTextFromServer + " (" + std::to_string(statusArg) + ")";
        } else {
            std::string preposition = ((status == Status::Read || status == Status::AckSentToServer || status == Status::Recalled) ? " by " : " to ");
            if (status == Status::AckReceived) {
                preposition = " from ";
            } else if (status == Status::SentToQliqStor) {
                preposition = " ";
            }
            text += preposition + displayName;
        }
    } else if (status == Status::Delivered && totalRecipientCount > 1) {
        text += " to all";
    } else if (!statusTextFromServer.empty()) {
        text = statusTextFromServer + + " (" + std::to_string(statusArg) + ")";
    }
    return text;
}

bool MessageStatusLog::Entry::isEmpty() const
{
    return id == 0;
}

std::string MessageStatusLog::Entry::timestampText() const
{
    return "TODO: timestampText";
}

std::string MessageStatusLog::Entry::statusText(int totalRecipientCount) const
{

}

bool Conversation::isEmpty() const
{
    return id == 0;
}

bool ChatMessageAttachment::isEmpty() const
{
    return id == 0;
}

} // qx

#include "QxExportConversation.hpp"
#include <fstream>
#include "qxlib/crypto/QxBase64.hpp"
#include "qxlib/util/StringUtils.hpp"
#include "qxlib/dao/QxQliqUserDao.hpp"
#include "qxlib/dao/chat/QxChatMessageDao.hpp"
#if defined(QXL_DEVICE_PC) && !defined(QT_NO_DEBUG)
#include <QByteArray>
#include <QFile>
#endif

namespace qx {

#ifdef QXL_DEVICE_PC
#define NEW_LINE "\n"
#else
#define NEW_LINE "\r\n"
#endif

namespace {

std::string chatMessageToRtf(const ChatMessage &msg, const MessageStatusLog &statusLog, ContactEntityProvider& contactProvider)
{
    std::string ret;

    ret += "\\pard ";

    if (msg.type == ChatMessage::Type::Event) {
        std::string eventString = msg.text;
        ret += "\\i " + eventString + "\\i0 ";

    } else if (msg.type == ChatMessage::Type::Regular) {
        ret += "\\b ";
        ret += contactProvider.byQliqId(msg.fromQliqId).displayName();
        ret += "\\b0  ";

        std::string message = msg.text;
        StringUtils::replace(message, "\r\n", "\\par ");
        StringUtils::replace(message, "\n", "\\par ");
        ret += message + "\\par ";

        if (!msg.attachments.empty()) {
            const auto& attachment = msg.attachments[0];

            ret += "\\i File attached:\\i0  ";
            ret += attachment.fileName;
            ret += "\\par ";

            const std::string& thumbnail = attachment.thumbnail;
            if (!thumbnail.empty()) {
                const int lineWidth = 78;
                std::string bytes;
                // TODO: doesn't decode thumbnails on desktop
                auto len = base64::decode(thumbnail.c_str(), thumbnail.size(), &bytes);
                if (len > 0) {
                    ret += "{\\pict\\jpegblip" NEW_LINE;
                    char buffer[3];
                    for (std::size_t i = 0; i < bytes.size(); ++i) {
                        sprintf(buffer, "%02x", (unsigned char) bytes[i]);
                        ret += buffer;
                        if (((i + 1) * 2) % lineWidth == 0) {
                            ret += NEW_LINE;
                        }
                    }
                    ret += NEW_LINE "}" NEW_LINE "\\par ";
                } else {
                    QXLOG_ERROR("Could not base64 decode attachment thumbnail", nullptr);
                }
            } else {
                QXLOG_INFO("Attachment thumbnail is empty", nullptr);
            }
        }

        ret += "\\fs22\\cf1 ";
//        if (!statusLog.isEmpty()) {
//            const auto& last = *(--statusLog.entries.end());
//            ret += last.timestampText();
//            ret += " * ";
//            ret += last.statusText(0);
//        }
        ret += ChatMessage::timestampToString(msg.timestamp);
        ret += "\\fs24\\cf0\\par\\par ";
    }

    return ret;
}

} // anonymous

std::string ExportConversation::toRtf(const ConversationMessageList &conversationOrMessages)
{
    Conversation conversation;
    std::vector<ChatMessage> messages;

    if (!conversationOrMessages.messageUuids.empty()) {
        std::string where = ChatMessageDao::columnNames[ChatMessageDao::UuidColumn] +
            " IN (";
        int i = 0;
        for (const auto& uuid: conversationOrMessages.messageUuids) {
            if (i++ > 0) {
                where += ", ";
            }
            where.push_back('"');
            where += uuid;
            where.push_back('"');
        }
        where += ")";

        dao::Query q;
        q.appendCustomWhere(where);
        messages = ChatMessageDao::select(q);

        if (!messages.empty()) {
            conversation = ConversationDao::selectOneBy(ConversationDao::IdColumn, std::to_string(messages[0].conversationId));
        }
    } else if (!conversationOrMessages.conversationUuid.empty()) {
        conversation = ConversationDao::selectOneBy(ConversationDao::UuidColumn, conversationOrMessages.conversationUuid);
        messages = ChatMessageDao::selectBy(ChatMessageDao::ConversationIdColumn, std::to_string(conversation.id));
    } else {
        QXLOG_FATAL("Neither conversation uuid nor messages uuids where given to convert to RTF", nullptr);
        return "";
    }

    if (conversation.isEmpty() || messages.empty()) {
        QXLOG_FATAL("No messages to convert to RTF", nullptr);
        return "";
    }

    for (auto& msg: messages) {
        if (msg.hasAttachment) {
            auto attachment = ChatMessageAttachmentDao::selectOneBy(ChatMessageAttachmentDao::MessageUuidColumn, msg.uuid);
            msg.attachments.push_back(attachment);
        }
    }

    std::string rtf;
    rtf =  "{\\rtf1\\ansi\\deff0{\\fonttbl{\\f0\\fnil\\fcharset0 Arial;}}" NEW_LINE;
    rtf += "{\\colortbl ;\\red102\\green102\\blue102;}" NEW_LINE;
    if (!conversation.subject.empty()) {
        rtf += "\\f0\\fs28 re: " + conversation.subject + "\\fs24\\par\\par ";
    }

    ContactEntityProvider contactProvider;
    for (const auto& msg: messages) {
        MessageStatusLog statusLog;
        rtf += chatMessageToRtf(msg, statusLog, contactProvider);
    }

    rtf += "}";

    return rtf;
}

bool ExportConversation::toRtf(const ExportConversation::ConversationMessageList &conversationOrMessages, const std::string &filePath)
{
    bool ret = false;
    std::string rtf = toRtf(conversationOrMessages);
    if (!rtf.empty()) {
        std::ofstream out(filePath, std::ios::out | std::ios::trunc);
        if (out.is_open()) {
            out << rtf;
            ret = out.good();
        }
    }
    return ret;
}

} // qx

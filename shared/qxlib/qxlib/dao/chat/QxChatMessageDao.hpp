#ifndef QXCHATMESSAGEDAO_HPP
#define QXCHATMESSAGEDAO_HPP
#include "qxlib/dao/QxBaseDao.hpp"
#include "qxlib/model/chat/QxChatMessage.hpp"

namespace qx {

class ContactEntityProvider;

class ConversationDao : public QxBaseDao<qx::Conversation>
{
public:
    enum Column {
        IdColumn,
        UuidColumn,
        SubjectColumn,
    };
};

class ChatMessageDao : public QxBaseDao<qx::ChatMessage>
{
public:
    enum Column {
        IdColumn,
        ConversationIdColumn,
        UuidColumn,
        TimestampColumn,
        FromQliqIdColumn,
        ToQliqIdColumn,
        TextColumn,
        AckRequiredColumn,
        DeliveryStatusColumn,
        StatusTextColumn,
        TypeColumn,
        HasAttachmentColumn,
        DeletedColumn,
        RecallStatusColumn,
    };

    static int unreadConversationMessageCount();
    static int unreadCareChannelMessageCount();

#ifndef SWIG
    struct Result {
        int messageId;
        int conversationId;
        std::string fromQliqId;
        std::string snippet;
        std::string subject;
        std::time_t timestamp;
    };

    static std::vector<Result> fullTextSearch(const std::string& pattern, int limit = 0, int skip = 0, SQLite::Database& db = QxDatabase::database());
#if defined(QXL_DEVICE_PC) && !defined(QT_NO_DEBUG)
    static void test();
#endif // defined(QXL_DEVICE_PC) && !defined(QT_NO_DEBUG)
#endif // !SWIG
};

class ChatMessageAttachmentDao : public QxBaseDao<qx::ChatMessageAttachment>
{
public:
    enum Column {
        IdColumn,
        MessageUuidColumn,
        UrlColumn,
        MimeColumn,
        FileNameColumn,
        ThumbnailColumn,
#ifdef QXL_DEVICE_PC
        MediaFileStatusColumn,
#endif
    };

#if !defined(QXL_DEVICE_PC) || defined(TEST_MOBILE_DB)
    static ChatMessageAttachment selectOneBy(Column column, const variant& value, int skip = 0, SQLite::Database& db = QxDatabase::database());
#endif // !defined(QXL_DEVICE_PC) || defined(TEST_MOBILE_DB)
#ifdef QXL_DEVICE_PC
    static bool setMediaFileStatusDeleted(const std::string& messageUuid, SQLite::Database& db = QxDatabase::database());
#endif
};

class MessageStatusLogEntryDao : public QxBaseDao<qx::MessageStatusLog::Entry>
{
public:
    enum Column {
        MessageIdColumn,
        TimestampColumn,
        StatusColumn,
        QliqIdColumn,
        StatusTextFromServerColumn,
    };
};

} // namespace qx

#endif // QXCHATMESSAGEDAO_HPP

#ifndef QXCHATMESSAGE_HPP
#define QXCHATMESSAGE_HPP
#include <string>
#include <vector>
#include <ctime>

namespace qx {

struct Conversation {
/*
    enum class Status {
        Active,
        Archived,
        Deleted
    };
    enum class Type {
        Chat,
        CareChannel
    };
    enum class BroadcastType {
        NotBroadcast,
        Encrypted,
        PlainText,
        Received
    };
*/
    int id = 0;
    std::string uuid;
    std::string subject;
/*
    std::time_t createdAt = 0;
    std::time_t lastUpdatedAt = 0;
    Status status = Status::Active;
    std::string contactQliqId;
    SipContact::Type contactType;
    BroadcastType broadcastType = BroadcastType::NotBroadcast;
    std::string redirectQliqId;
    bool isMuted = false;
*/
    bool isEmpty() const;
};

struct ChatMessageAttachment {
    int id = 0;
    std::string messageUuid;
    std::string url;
    std::string mime;
    std::string fileName;
    std::string thumbnail;
    std::string key;
    std::string checksum;
    int encryptionMethod = 0;
    int status = 0;
    std::string localPath;
    std::string originalPath;
    unsigned int size = 0;
    std::string decryptedPath;

#ifdef QXL_DEVICE_PC
    enum class MediaFileStatus {
        Normal = 0,
        Archived = 1,
        Deleted = 2
    };
    MediaFileStatus mediaFileStatus = MediaFileStatus::Normal;
#endif // QXL_DEVICE_PC

    bool isEmpty() const;
};

struct ChatMessage {
    int id = 0;
    int conversationId = 0;
    std::string uuid;

    std::time_t timestamp = 0;
    std::string fromQliqId;
    std::string toQliqId;
    std::string text;
    bool isAckRequired = false;

    // sender only
    int deliveryStatus = 0;
    std::string statusText;

    enum class Type {
        Unknown = -1,
        Regular = 0,
        Event = 1
    };
    Type type = Type::Regular;

    bool hasAttachment = false;
    std::vector<ChatMessageAttachment> attachments;

    bool isEmpty() const;
    static std::string typeToString(Type type);
    static std::string timestampToString(std::time_t timestamp);
};

class ChatMessageListener {
public:
    virtual void onChatMessageStatusChanged(const ChatMessage& msg);
    virtual void onChatMessageReceived(const ChatMessage& msg);

protected:
    ~ChatMessageListener();
};

class MessageStatusLog
{
public:
    enum class Status {
        TextFromServer = -1,
        Created = 1,
        Sending = 2,
        Received = 3,
        AckSending = 4,
        AckReceived = 5,
        Read = 6,
        AckSentToServer = 7,
        AckDelivered = 8,
        AckSynced = 9,
        Sent = 10,
        ReceivedByAnotherDevice = 11,
        Recalled = 12,
        SentToQliqStor = 13,
        PushNotificationSentByServer = 14,
        Delivered = 200,
        Pending = 202,
        UserLoggedOut = 204,
        Synced = 299
    };

    struct Entry {
        int id = 0;
        int messageId = 0;
        std::time_t timestamp = 0;
        int status = 0;             // the status can be an enum value or a SIP error code
        std::string qliqId;         // the qliq id related to the event (ex. of recipient) if applicable
        std::string statusTextFromServer;

        bool isEmpty() const;
        std::string timestampText() const;
        std::string statusText(int totalRecipientCount) const;
    };

    int messageId = 0;
    std::vector<Entry> entries;

    MessageStatusLog();
    MessageStatusLog(int messageId);
    bool isEmpty() const;

    static std::string statusToText(int status);
    static std::string statusToText(const std::string& statusTextFromServer, int status, const std::string& qliqId, int totalRecipientCount);
};

} // qx

#endif // QXCHATMESSAGE_HPP

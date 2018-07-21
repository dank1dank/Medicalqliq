//
//  ConversationTableViewCell.h
//  qliq
//
//  Created by Valerii Lider on 7/31/14.
//
//

#import <UIKit/UIKit.h>

#import "ChatMessage.h"
#import "AttachmentView.h"
#import "MessageTextView.h"
#import "Conversation.h"

extern NSString *const ConversationMyCellId;
extern NSString *const ConversationWithAttachmentMyCellId;
extern NSString *const ConversationContactCellId;
extern NSString *const ConversationWithAttachmentContactCellId;

typedef NS_ENUM(NSInteger, TypeCell) {
    TypeCellMy = 0,
    TypeCellMyWithAttachment,
    TypeCellReceived,
    TypeCellReceivedWithAttachment
};

@class ConversationTableViewCell;

@protocol ConversationCellDelegate <NSObject>

- (BOOL)ackGotForConversationTableViewCell:(ConversationTableViewCell *)cell;
- (void)conversationTableViewCellNeedUpdate:(ConversationTableViewCell *)cell;
- (void)conversationTableViewCellWasLongPressed:(ConversationTableViewCell *)cell;
- (void)conversationTableViewCell:(ConversationTableViewCell *)cell didTappedAttachment:(MessageAttachment *)attachment;
- (void)conversationTableViewCell:(ConversationTableViewCell *)cell didChangedAttachmentState:(ProgressState)state;
- (void)reloadCellWithMessageUUID:(NSString *)uuid;
- (void)downloadAttachments:(MessageAttachment *)attachment;
- (void)resendMessage:(ChatMessage*)message;

- (void)phoneNumberWasPressedInCell:(ConversationTableViewCell *)cell andPhoneNumber:(NSString *)phoneNumber;
- (void)cell:(ConversationTableViewCell *)cell qliqAssistedViewWasTappedWithPhoneNumbers:(NSMutableArray *)phoneNumbers;

@end

@interface ConversationTableViewCell : UITableViewCell

@property (nonatomic, assign) id<ConversationCellDelegate> delegate;

@property (nonatomic, weak) IBOutlet AttachmentView *attachmentImage;
//TextMessage
@property (weak, nonatomic) IBOutlet MessageTextView *messageTextView;

@property (nonatomic, readonly) ChatMessage *chatMessage;

+ (CGFloat)getCellHeightWithMessage:(ChatMessage*)message withBounds:(CGRect)bounds itsForMessageTimestamp:(BOOL)itsForMessageTimestamp;
+ (CGSize)getSizeOfText:(NSString *)text withBounds:(CGRect)bounds itsForMessageTimestamp:(BOOL)itsForMessageTimestamp;
+ (CGFloat)getBotTextLabelValue:(BOOL)isMyMessage withMessage:(ChatMessage*)message;
+ (CGFloat)getMaxWidthBubbleMessage;

- (void)setCellMessage:(ChatMessage *)message
                ofUser:(BOOL)isUsersMessage
   isGroupConversation:(BOOL)isGroupConversation
         broadcastType:(BroadcastType)broadcastType
itsForMessageTimestamp:(BOOL)itsForMessageTimestamp;

- (void)showDeletingMode:(BOOL)isDeletingMode messageIsChecked:(BOOL)messageIsChecked;

@end

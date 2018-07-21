//
//  ConversationViewController.h
//  qliq
//
//  Created by Valerii Lider on 7/30/14.
//
//

#import <UIKit/UIKit.h>

#define kConversationsListDidPressActionButtonNotification @"ConversationsListDidPressActionButton"
#define kConversationsListDidPressDeleteButtonNotification @"ConversationsListDidPressDeleteButton"

@class Conversation, Recipients, MessageAttachment;

@protocol ConversationViewControllerDelegate <NSObject>

- (void)conversationDeletePressed:(Conversation *)conversation;
- (void)conversationSavePressed:(Conversation *)conversation;

@end

@interface ConversationViewController : UIViewController

@property (nonatomic, assign) id <ConversationViewControllerDelegate> delegate;

@property (nonatomic, strong) Conversation *conversation;
@property (nonatomic, assign) BOOL isCareChannelMode;

/** For New Conversation */
@property (nonatomic, assign) BOOL isNewConversation;
@property (nonatomic, assign) BOOL isBroadcastConversation;

@property (nonatomic, strong) NSString *messageForNewConversation;
@property (nonatomic, strong) NSString *subjectForNewConversation;

@property (nonatomic, strong) MessageAttachment *attachment;
@property (nonatomic, strong) Recipients *recipients;

- (void) sendMessageInNewConversation:(NSString *)text toRecipients:(Recipients *)recipients withSubject:(NSString *)subjectText conversationUuuid:(NSString *)conversationUuid messageUuid:(NSString *)messageUuid;

- (void)setNeedAskBroadcast:(BOOL)needAskBroadcast;

@end

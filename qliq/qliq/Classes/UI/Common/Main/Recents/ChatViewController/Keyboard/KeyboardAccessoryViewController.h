//
//  KeyboardAccessoryViewController.h
//  qliq
//
//  Created by Valeriy Lider on 8/7/14.
//
//

#import <UIKit/UIKit.h>

#import "ChatMessage.h"
#import "HPGrowingTextView.h"

@class KeyboardAccessoryViewController;

@protocol KeyboardAccessoryViewControllerDelegate <NSObject>

- (void)keyboardInputAccessoryViewSendPressed:(KeyboardAccessoryViewController *)inputView;
- (void)keyboardInputAccessoryViewQuickMessagePressed:(KeyboardAccessoryViewController *)inputView;
- (void)keyboardInputAccessoryView:(KeyboardAccessoryViewController *)inputView didPressAttachment:(MessageAttachment *)attachment;
- (void)changeHeightAccessoryViewTo:(CGFloat)height;
- (void)changeBottomTableview:(CGFloat)height;

- (void)showAlert:(UIAlertView_Blocks *)alert withBlock:(void(^)(NSInteger buttonIndex))block;
- (NSString *)getPagerNumber;

- (CGFloat)getMaxHeightForKeyboardAccessoryView;
- (void)scrollUpChatTableDown:(BOOL)scrollDown offset:(CGFloat)offset isSentMessage:(BOOL)isSentMessage animated:(BOOL)animated;
- (BOOL)turnOnSingleFieldMode:(BOOL)isSingleFieldMode;
- (BOOL)isSingleFieldModeSetup;

@end

@interface KeyboardAccessoryViewController : UIViewController

@property (nonatomic, weak) id <KeyboardAccessoryViewControllerDelegate> delegate;

@property (nonatomic, weak, readonly) IBOutlet UIView *selectAttachmentView;
@property (weak, nonatomic) IBOutlet HPGrowingTextView *textView;
@property (weak, nonatomic) IBOutlet UILabel *placeholderLabel;

@property (nonatomic, assign) BOOL isRequestAck;
@property (assign, nonatomic) BOOL textViewWillResignFirstResponder;
@property (assign, nonatomic) BOOL isMessageSent;

@property (nonatomic, assign) ChatMessagePriority messagePriority;

@property (nonatomic, strong) NSMutableArray *attachmentsList;

- (BOOL)needsAck;
- (NSString *)currentMessage;
- (NSArray *)attachments;
- (void)clearAllWithCompletion:(VoidBlock)completion;
- (void)clearMessageTextWithCompletion:(VoidBlock)completion;
- (void)appendMessageText:(NSString *)messageStr;

- (BOOL)hasAttachment;

- (void)hiddenAttachmentView:(BOOL)hidden;
- (void)hiddenPagerOnlyView:(BOOL)hidden;
- (void)addAttachment:(MessageAttachment *)attachment;

- (void)showFlagView:(BOOL)show pagerMode:(BOOL)pagerMode withDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay options:(UIViewAnimationOptions)options withCompletion:(void (^)(void))completion;

- (void)setupKAVForSingleFieldModeWithFreeSpace:(CGFloat)freeSpace;
- (BOOL)needToTurnOffSingleFieldMode;
@end

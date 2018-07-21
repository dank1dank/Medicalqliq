//
//  RecentTableViewCell.h
//  qliq
//
//  Created by Valerii Lider on 7/29/14.
//
//

#import <UIKit/UIKit.h>

#define kValueHeightRecentCell 74.f

@class Conversation;

@protocol RecentCellDelegate <NSObject>

//OptionView
- (void)pressCallButton:(Conversation *)conversation;
- (void)pressFlagButton:(Conversation *)conversation;
- (void)pressSaveButton:(Conversation *)conversation;
- (void)pressDeleteButton:(Conversation *)conversation;

//GestureRecognizer
- (void)cellLeftSwipe:(Conversation *)conversation;
- (void)cellRightSwipe;

@end

@interface RecentTableViewCell : UITableViewCell

@property (nonatomic, assign) id <RecentCellDelegate> delegate;

- (void)configureCellWithConversation:(Conversation *)conversation withSelectedCell:(Conversation *)selectedConversation;
- (void)configureBackroundColor:(UIColor *)color;
- (void)showOptions;
- (void)hideOptions;

@end

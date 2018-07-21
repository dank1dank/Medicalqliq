//
//  ConversationsListTableViewCell.h
//  qliq
//
//  Created by Valerii Lider on 10/08/15.
//
//

#import <UIKit/UIKit.h>

@class Conversation;

#define kDefaultConversationsListTableViewCellHeight 64.f
#define kConversationsListTableViewCellReuseId @"ConversationsListCellReuseId"

@interface ConversationsListTableViewCell : UITableViewCell

- (void)configureCellWithConversation:(Conversation*)conversation cellIsChecked:(BOOL)isChecked;

@end

//
//  ConversationsListViewController.h
//  qliq
//
//  Created by Valerii Lider on 10/08/15.
//
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, ConversationsAction) {
    ConversationsActionDelete,
    ConversationsActionArchive,
    ConversationsActionRestore
};

#define kConversationsListDidPressActionButtonNotification @"ConversationsListDidPressActionButton"
#define kConversationsListDidPressDeleteButtonNotification @"ConversationsListDidPressDeleteButton"

@interface ConversationsListViewController : UIViewController

@property (nonatomic, strong) NSArray *conversations;
@property (nonatomic, strong) NSMutableSet *selectedConversations;
@property (nonatomic, assign) ConversationsAction currentConversationsAction;

@end

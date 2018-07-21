//
//  ConversationsViewController.h
//  qliq
//
//  Created by Valerii Lider on 3/12/15.
//
//

#import <UIKit/UIKit.h>

@interface ConversationsViewController : UIViewController

@property (nonatomic, assign) BOOL isArchivedConversations;
@property (nonatomic, assign) BOOL isCareChannelsMode;

@property (nonatomic, strong) NSMutableArray *conversations;

@end

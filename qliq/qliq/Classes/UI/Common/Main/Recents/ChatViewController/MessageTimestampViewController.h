//
//  MessageTimestampViewController.h
//  qliq
//
//  Created by Valeriy Lider on 10/1/14.
//
//

#import <UIKit/UIKit.h>

@class ChatMessage;

@interface MessageTimestampViewController : UIViewController

/**
 IBOutlets
 */
@property (weak, nonatomic) IBOutlet UITableView *tableView;

/**
 Data
 */
@property (nonatomic, assign) BOOL isGroupMessage;

@property (nonatomic, strong) ChatMessage *message;
@property (nonatomic, strong) NSArray *messageHistory;

@end

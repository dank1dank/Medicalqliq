//
//  DeclineMessagesController.h
//  qliq
//
//  Created by Paul Bar on 1/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DeclineMessageTableViewCell.h"

@class DeclineMessageService;
@class DeclineMessage;

@protocol DeclineMessagesControllerDelegate <NSObject>

-(void) declineMessageSelected:(DeclineMessage*)declineMessage;

@end

@interface DeclineMessagesController : NSObject <UITableViewDelegate, UITableViewDataSource, DeclineMessageTableViewCellDelegate>
{
    NSMutableArray *declineMessages;
    DeclineMessageService *declineMessageService;
}

@property (nonatomic, assign) id<DeclineMessagesControllerDelegate> delegate;
@property (nonatomic, retain) UITableView* tableView; 

-(void) refreshData;

@end

//
//  DeclineMessageTableViewCell.h
//  qliq
//
//  Created by Paul Bar on 1/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DeclineMessageTableViewCell;

@protocol DeclineMessageTableViewCellDelegate <NSObject>

-(void) sendButtonPressedOnCell:(DeclineMessageTableViewCell*)cell;

@end

@interface DeclineMessageTableViewCell : UITableViewCell
{
    UIButton *sendButton;
}

@property (nonatomic, assign) id<DeclineMessageTableViewCellDelegate> delegate;

@end

//
//  IncomingCallView.h
//  qliq
//
//  Created by Paul Bar on 1/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol IncomingCallViewDelegate <NSObject>

-(void) answerButtonPressed;
-(void) declineButtonPressed;
-(void) forwardButtonPressed;
-(void) declineWithMessageButtonPressed;

@end

@interface IncomingCallView : UIView
{
    UILabel *nameLabel;
    UILabel *phoneLabel;
    
    UIButton *answerButton;
    UIButton *declineButton;
    UIButton *declineWithMessageButton;
    UIButton *forwardButton;
    
    UITableView *table;
}

@property (nonatomic, assign) id<IncomingCallViewDelegate> delegate;
@property (nonatomic, readonly) UILabel *nameLabel;
@property (nonatomic, readonly) UILabel *phoneLabel;

@end

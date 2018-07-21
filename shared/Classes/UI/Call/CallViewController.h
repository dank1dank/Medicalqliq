//
//  CallViewController.h
//  qliq
//
//  Created by Paul Bar on 1/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QliqBaseViewController.h"
#import "CallView.h"
#import "NavigationBarChattingWithView.h"
#import "DeclineMessagesController.h"
#import "ForwardListController.h"
#import "Contact.h"

@class Call;
@class CallViewController;

@protocol CallViewControllerDelegate <NSObject>

-(void) callViewControllerWillEnteredBackground:(CallViewController*)callViewController;
-(void) presentContacts;

@end

@interface CallViewController : QliqBaseViewController<CallViewDelegate, DeclineMessagesControllerDelegate>
{
    CallView *callView;
    
    NavigationBarChattingWithView *navBarChattingWithView;
    DeclineMessagesController *declineMessagesController;
    ForwardListController *forwardListController;
}

@property (nonatomic, assign) id<CallViewControllerDelegate> delegate;
@property (nonatomic, assign) BOOL callInProgress;

-(void) initiatingCall:(Call*)call;
-(void) callStarted;
-(void) incomingCall:(Call*)call;
-(void) callFailedWithReason:(NSString*)reason;
-(void) answerCall;


@end

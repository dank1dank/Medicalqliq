//
//  CallView.h
//  qliq
//
//  Created by Paul Bar on 1/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "IncomingCallView.h"
#import "CallingView.h"
#import "CallFailedView.h"
#import "CallInProgressView.h"
#import "Contact.h"

typedef enum
{
    CallViewStateIncomingCall = 0,
    CallViewStateCalling = 1,
    CallViewStateCallFailed = 2,
    CallViewStateCallInProgress = 3
}CallViewState;


@protocol CallViewDelegate <NSObject>

-(void) answerButtonPressed;
-(void) declineButtonPressed;
-(void) forwardButtonPressed;
-(void) declineWithMessageButtonPressed;
-(void) endCallButtonPressed;
-(void) tryAgainButtonPressed;

-(void) muteButtonPressed:(BOOL)enable;
-(void) contactsButtonPressed;
-(void) addCallButtonPressed;
-(void) videoCallButtonPressed;
-(void) speakerButtobPressed:(BOOL)enable;

@end

@protocol Contact;

@interface CallView : UIView<IncomingCallViewDelegate, CallingViewDelegate, CallFailedViewDelegate, CallInProgressViewDelegate>
{
    IncomingCallView *incomingCallView;
    CallingView *callingView;
    CallFailedView *callFailedView;
    CallInProgressView *callInProgressView;
    
    NSArray *callViews;
}

@property (nonatomic, readonly) UITableView *table;
@property (nonatomic, assign) id<CallViewDelegate> delegate;

-(void) showTable;
-(void) hideTable;
-(void) presentState:(CallViewState)state;
-(void) updateRecipientName:(Contact *)contact;

@end

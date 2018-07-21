//
//  VoiceCallsController.h
//  qliq
//
//  Created by Paul Bar on 1/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CallStateChangeInfo.h"
#import "QliqSipProtocols.h"

@protocol Contact;

@interface VoiceCallsController : NSObject
{
    NSMutableArray *calls;
    BOOL busy;
}

@property (nonatomic, assign) id<QliqSipVoiceCallsDelegate> voiceCallsDelegate;

-(void) callUser:(Contact *)userContact;
-(void) callStateChanged:(CallStateChangeInfo*)stateChangeInfo;
-(void) incomingCall:(NSNumber*)call_id;

-(void) answerCall:(Call*)call;
-(void) declineCall:(Call*)call;
-(void) endCall:(Call*)call;


@end

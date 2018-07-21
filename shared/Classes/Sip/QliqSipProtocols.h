//
//  QliqSipProtocols.h
//  qliq
//
//  Created by Paul Bar on 1/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Call.h"

@protocol Contact;

@protocol  QliqSipVoiceCallsDelegate <NSObject>

-(void) callFailedWithError:(NSString *)error;

-(void) initiatingCall:(Call*)call;

-(void) callEnded;

-(void) callStarted;

-(void) incomingCall:(Call*)call;

-(void) callFailedWithReason:(NSString*)reason;

- (BOOL) isReachable;

@end

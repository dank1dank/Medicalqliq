//
//  CallStateChangeInfo.m
//  qliq
//
//  Created by Paul Bar on 1/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CallStateChangeInfo.h"

@implementation CallStateChangeInfo
@synthesize call_id;
@synthesize state;
@synthesize lastReasonCode;

-(void) dealloc
{
    [call_id release];
    [state release];
    [lastReasonCode release];
    [super dealloc];
}

@end

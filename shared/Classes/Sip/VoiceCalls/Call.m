//
//  Call.m
//  qliq
//
//  Created by Paul Bar on 1/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Call.h"

@implementation Call

@synthesize type;
@synthesize call_id;
@synthesize state;
@synthesize contact;

-(id) initWithCallId:(unsigned int)_call_id andType:(CallType)_call_type
{
    self = [super init];
    if(self)
    {
    }
    return self;
}

-(NSString*)stringForCallState
{
    NSString *rez = nil;
    switch (state)
    {
        case CallStateInitial:
        {
            rez = @"Initial";
        }break;
        case CallStateEstablishing:
        {
            rez = @"Establishing";
        }break;
        case CallStateAccepted:
        {
            rez = @"Accepted";
        }break;
        case CallStatePresented:
        {
            rez = @"Presented";
        }break;
        case CallStateInProgress:
        {
            rez = @"Progress";
        }break;
        default:
        {
            rez = @"Unknown";
        }break;
    }
    
    return rez;
}


@end

//
//  Call.h
//  qliq
//
//  Created by Paul Bar on 1/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Contact.h"

typedef enum
{
    CallTypeIncoming = 0,
    CallTypeOutgoing = 1
} CallType;

typedef enum
{
    CallStateInitial = 0,
    CallStateEstablishing = 1,
    CallStateAccepted = 2,
    CallStatePresented = 3,
    CallStateInProgress = 4,
} CallState;

@interface Call : NSObject
{
}

-(NSString*) stringForCallState;

@property (nonatomic, assign) CallType type;
@property (nonatomic, assign) unsigned int call_id;
@property (nonatomic, assign) CallState state;
@property (nonatomic, retain) Contact * contact;


@end

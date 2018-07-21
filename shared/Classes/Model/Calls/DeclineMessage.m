//
//  DeclineMessage.m
//  qliq
//
//  Created by Paul Bar on 2/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DeclineMessage.h"

@implementation DeclineMessage

@synthesize messageText;

-(void) dealloc
{
    [messageText release];
    [super dealloc];
}

@end

//
//  CallInitiationResult.m
//  qliq
//
//  Created by Paul Bar on 1/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CallInitiationResult.h"

@implementation CallInitiationResult

@synthesize call_id;
@synthesize error;


-(void) dealloc
{
    [error release];
    [super dealloc];
}

@end

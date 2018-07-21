//
//  State.m
//  CCiPhoneApp
//
//  Created by Ravi Ada on 5/23/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import "State.h"
#import "DBPersist.h"

@implementation State
@synthesize stateCode,stateName;
@synthesize isDirty,isDetailViewHydrated;

+ (NSMutableArray *) getAllStatesToDisplay
{
    return [[DBPersist instance] getAllStatesToDisplay];
}

- (void) dealloc {
 	[stateCode release];
    [stateName release];
	[super dealloc];
}

@end

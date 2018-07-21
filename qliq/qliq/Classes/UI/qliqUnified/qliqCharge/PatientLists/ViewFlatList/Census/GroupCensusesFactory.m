//
//  GroupCensusesFactory.m
//  qliq
//
//  Created by Paul Bar on 3/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GroupCensusesFactory.h"
#import "Group.h"

@implementation GroupCensusesFactory

@synthesize group;


-(void) dealloc
{
    [self.group release];
    [super dealloc];
}

-(NSArray*) getCensuesOfUser:(QliqUser *)user forDate:(NSDate *)date withCensusType:(NSString *)censusType
{
    return [NSArray arrayWithObjects: nil]; // TODO implement logic to get censuses for self.group
}

@end

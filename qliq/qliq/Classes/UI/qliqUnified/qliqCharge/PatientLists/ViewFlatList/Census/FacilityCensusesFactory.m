//
//  FacilityCensusesFactory.m
//  qliq
//
//  Created by Paul Bar on 3/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FacilityCensusesFactory.h"

@implementation FacilityCensusesFactory
@synthesize facility;

-(NSArray*) getCensuesOfUser:(QliqUser *)user forDate:(NSDate *)date withCensusType:(NSString *)censusType
{
    return [NSArray arrayWithObjects: nil]; // TODO implement logic to get censuses for self.facility
}

@end

//
//  Facility.m
//  qliq
//
//  Created by Paul Bar on 2/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Facility.h"
#import "NSObject+AutoDescription.h"
#import "FMResultSet.h"

@implementation Facility

@synthesize npi;
@synthesize name;
@synthesize type;
@synthesize country;
@synthesize state;
@synthesize city;
@synthesize zip;
@synthesize address;
@synthesize phone;

+(Facility*)facilityWithResultSet:(FMResultSet *)resultSet
{
    Facility *facility = [[Facility alloc] init];
    
    facility.npi = [NSNumber numberWithInt:[resultSet intForColumn:@"npi"]];
    facility.name = [resultSet stringForColumn:@"name"];
    facility.type = [resultSet stringForColumn:@"type"];
    facility.country = [resultSet stringForColumn:@"country"];
    facility.state = [resultSet stringForColumn:@"state"];
    facility.city = [resultSet stringForColumn:@"city"];
    facility.zip = [resultSet stringForColumn:@"zip"];
    facility.address = [resultSet stringForColumn:@"address"];
    facility.phone = [resultSet stringForColumn:@"phone"];
    
    return [facility autorelease];
}

-(void) dealloc
{
    [self.npi release];
    [self.name release];
    [self.type release];
    [self.country release];
    [self.state release];
    [self.city release];
    [self.zip release];
    [self.address release];
    [self.phone release];
    [super dealloc];
}

-(NSString*)description
{
    return [self autoDescription];
}

@end

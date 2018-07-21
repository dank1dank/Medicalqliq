//
//  Floor.m
//  qliq
//
//  Created by Paul Bar on 3/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Floor.h"
#import "FMResultSet.h"
#import "NSObject+AutoDescription.h"

@implementation Floor

@synthesize floorId;
@synthesize facilityNpi;
@synthesize name;
@synthesize displayOrder;
@synthesize floorDescription;


-(void) dealloc
{
    [self.floorId release];
    [self.facilityNpi release];
    [self.name release];
    [self.displayOrder release];
    [self.floorDescription release];
    [super dealloc];
}

+(Floor*) floorWithResultSet:(FMResultSet *)rs
{
    Floor *floor = [[Floor alloc] init];
    
    floor.floorId = [NSNumber numberWithInt:[rs intForColumn:@"id"]];
    floor.facilityNpi = [NSNumber numberWithInt:[rs intForColumn:@"facility_npi"]];
    floor.name = [rs stringForColumn:@"name"];
    floor.displayOrder = [NSNumber numberWithInt:[rs intForColumn:@"display_order"]];
    floor.floorDescription = [rs stringForColumn:@"description"];
    
    return [floor autorelease];
}

-(NSString*) description
{
    return [self autoDescription];
}

@end

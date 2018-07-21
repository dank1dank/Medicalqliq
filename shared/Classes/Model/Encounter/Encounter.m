//
//  Encounter.m
//  qliq
//
//  Created by Paul Bar on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Encounter.h"
#import "FMResultSet.h"
#import "NSObject+AutoDescription.h"

@implementation Encounter

@synthesize encounterId;
@synthesize patietnVisitId;
@synthesize dateOfService;
@synthesize status;
@synthesize data;

-(void) dealloc
{
    [self.encounterId release];
    [self.patietnVisitId release];
    [self.dateOfService release];
    [self.status release];
    [self.data release];
    [super dealloc];
}

+(Encounter*) encounterWithResultSet:(FMResultSet *)result_set
{
    Encounter *encounter = [[Encounter alloc] init];
    
    encounter.encounterId = [NSNumber numberWithInt:[result_set intForColumn:@"id"]];
    encounter.patietnVisitId = [NSNumber numberWithInt:[result_set intForColumn:@"patient_visit_id"]];
    encounter.dateOfService = [NSDate dateWithTimeIntervalSince1970:[result_set intForColumn:@"date_of_service"]];
    encounter.status = [NSNumber numberWithInt:[result_set intForColumn:@"status"]];
    encounter.data = [result_set stringForColumn:@"data"];
    
    return [encounter autorelease];
}

-(NSString*) description
{
    return [self autoDescription];
}

@end

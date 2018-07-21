//
//  EncounterCpt.m
//  CCiPhoneApp
//
//  Created by Ravi Ada on 4/12/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import "EncounterCpt.h"
#import "DBPersist.h"

@implementation EncounterCpt
@synthesize encounterCptId,encounterId,cptCode;
@synthesize codeWithModifiers,shortDescription,masterCptPft,physicianCptPft;
@synthesize isDirty,isDetailViewHydrated;
@synthesize dateOfService;
@synthesize createdAt, createdUser;
@synthesize lastUpdated, lastUpdatedUser;
@synthesize status;

+ (NSMutableArray *) getChargesToDisplayForCensus:(Census_old*)censusObj andDos:(NSTimeInterval)dateOfService
{
    return [[DBPersist instance] getChargesToDisplayForCensus:censusObj andDos:dateOfService];
}

+ (NSMutableArray *) getChargesToDisplayForAppointment:(NSInteger)appointmentId :(NSTimeInterval)dateOfService
{
    return [[DBPersist instance] getChargesToDisplayForAppointment:appointmentId :dateOfService];
}

+ (NSInteger) addEncounterCpt:(EncounterCpt *)encounterCpt
{
    return [[DBPersist instance] addEncounterCpt:encounterCpt];
}

+ (BOOL) deleteEncounterCpt:(NSInteger)encounterCptId
{
    return [[DBPersist instance] deleteEncounterCpt:encounterCptId];
}

- (id) initWithPrimaryKey:(NSInteger) pk {
    
    [super init];
    encounterCptId = pk;
    isDetailViewHydrated = NO;
    
    return self;
}

- (void) dealloc {
	[cptCode release];
    [codeWithModifiers release];
    [shortDescription release];
    [physicianCptPft release];
	[masterCptPft release];
	[super dealloc];
}

@end


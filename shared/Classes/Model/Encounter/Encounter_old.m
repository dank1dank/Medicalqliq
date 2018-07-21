//
//  Encounter.m
//  CCiPhoneApp
//
//  Created by Ravi Ada on 4/12/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import "Encounter_old.h"
#import "DBPersist.h"

//charges sync log
@implementation ChargesPullRequest
@synthesize transactionId,lastUpdated,syncRequested,syncRequestUser,pageNum,syncData,sentTime,sentStatus;

- (id) initWithPrimaryKey:(NSString *) transId :(NSInteger) pn {
    
    [super init];
    transactionId = transId;
	pageNum = pn;
    return self;
}

- (void) dealloc {
	[transactionId release];
	[syncRequestUser release];
	[syncData release];
 	[super dealloc];
}

@end

 
//encounter
@implementation Encounter_old
@synthesize encounterId,censusId,apptId,dateOfService,attendingPhysicianNpi;
@synthesize isDirty;
@synthesize status;
@synthesize lastUpdated, lastUpdatedUser;

//add an encounter
+ (NSInteger) addEncounter:(Encounter_old *)encounter
{
    return [[DBPersist instance] addEncounter:encounter];
}

//delete an encounter for given id
+ (BOOL) deleteEncounter:(NSInteger)encounterId
{
    return [[DBPersist instance] deleteEncounter:encounterId];
}

//get the note count for given encounter
+ (NSInteger) getNoteCount:(NSInteger)encounterId
{
    return [[DBPersist instance] getNoteCount:encounterId];
}
+ (NSInteger) getEncounterForCensus:(NSInteger) censusId:(double) attendingPhysicianNpi :(NSTimeInterval) dateOfService
{
    return [[DBPersist instance] getEncounterForCensus:censusId :attendingPhysicianNpi :dateOfService];
}

// MZ: get encounter object
+ (Encounter_old *) getEncounterObjForCensus:(NSInteger) censusId:(double) attendingPhysicianNpi :(NSTimeInterval) dateOfService {
    NSInteger encounterId = [[DBPersist instance] getEncounterForCensus:censusId :attendingPhysicianNpi :dateOfService];
    return [[DBPersist instance] getEncounterWithId:encounterId];
}

+ (NSInteger) getEncounterForAppt:(NSInteger) apptId:(double) attendingPhysicianNpi :(NSTimeInterval) dateOfService
{
    return [[DBPersist instance] getEncounterForAppt:apptId :attendingPhysicianNpi :dateOfService];
}

+ (BOOL) updateEncounter:(NSInteger)encounterId withStatus:(EncounterStatus)newStatus {
    return [[DBPersist instance] updateEncounter:encounterId withStatus:newStatus];
}

+ (NSMutableDictionary *) getChargesForDesktopSync:(ChargesPullRequest*)chargesPullRequest{
	return [[DBPersist instance] getChargesForDesktopSync:chargesPullRequest];
}

+ (NSInteger) getEncounterId:(NSInteger)encounterCptId
{
	return [[DBPersist instance] getEncounterId:encounterCptId];
}

+ (BOOL) updateEncounterLastUpdated:(NSInteger)encounterId
{
	return [[DBPersist instance] updateEncounterLastUpdated:encounterId];
	
}

+ (BOOL) copyCharge:(NSDictionary *)chargeDictObj andCensusObj:(Census_old*)censusObj andCurrentDos:(NSTimeInterval)currentDos
{
	return [[DBPersist instance] copyCharge:chargeDictObj  andCensusObj:censusObj andCurrentDos:currentDos];
}

- (void) dealloc {
	[super dealloc];
}

- (id) initWithPrimaryKey:(NSInteger) pk {
    [super init];
    encounterId = pk;
    return self;
}

@end

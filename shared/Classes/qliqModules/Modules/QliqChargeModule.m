//
//  QliqChargeModule.m
//  qliq
//
//  Created by Paul Bar on 1/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QliqChargeModule.h"
#import "QliqModuleBase+Protected.h"
#import "QliqSipMessage.h"
#import "ChargesRequestSchema.h"
#import "QliqAppToAppMessage.h"
#import "QliqPushAppointmentsMessage.h"
#import "ChargesRequestSchema.h"
#import "QliqPullChargesRequestMessage.h"
#import "Hl7MessageSchema.h"
#import "QliqHL7CensusMessage.h"
#import "PublickeyChangedNotificationSchema.h"
#import "QliqSupernodeNotificationMessage.h"
#import "Outbound.h" //TODO delete
#import "QliqSip.h"
#import "DBPersist.h"
#import "JSONKit.h"
#import "UserNotifications.h"
#import "QliqCensusMessage.h"
#import "QliqAppointmentMessage.h"
#import "QliqPutCensusRequest.h"
#import "CensusSchema.h"
#import "Helper.h"
#import "Patient_old.h"
#import "Facility_old.h"
#import "ReferringPhysician.h"
#import "Log.h"
#import "DataServerClient.h"
#import "FMDatabase.h"
#import "DBUtil.h"
#import "SuperbillService.h"

@interface QliqChargeModule()
-(void) processAppointments:(QliqPushAppointmentsMessage*)message;

-(void) processHL7CensusMessage:(QliqHL7CensusMessage*)message;
-(void) processHL7Census: (NSDictionary *)dataDict;

-(BOOL) processSupernodeNotification:(QliqSupernodeNotificationMessage*)message;

//-(void) processSupernodeCensusPage:(QliqCensusMessage*)message;
- (BOOL) processCensus:(NSDictionary *)censusDict fromUser:(NSString *)qliqId;
- (BOOL) processEncounters:(NSArray *)encountersArray fromUser:(NSString *)qliqId forCensusId:(int)censusId;
- (BOOL) mergeCensusWithLocalChanges:(Census_old *)remoteCensus: (NSDictionary *)remoteCensusDict fromUser:(NSString *)qliqId;
- (BOOL) mergeEncountersWithLocalChanges:(NSArray *)remoteEncountersArray forCensus:(Census_old *)localCensus fromUser:(NSString *)qliqId;
- (BOOL) processEncounter: (NSDictionary *)encounterDict fromUser:(NSString *)qliqId forCensusId:(int)censusId;

-(void) processSuperNodeAppointmentPage:(QliqAppointmentMessage*)message;
- (BOOL) processAppointment:(NSDictionary *)appDict fromUser:(NSString *)qliqId;

-(void) processSuperNodePutCensusRequest:(QliqPutCensusRequest*)message;
-(void) pullCensusFromDataServer;
-(void) pullAppointmentFromDataServer;
@end

@implementation QliqChargeModule

-(id) init
{
    self = [super init];
    if(self)
    {
        self.name = QliqChargeModuleName;
		/*
        NSString *qliqSchemaPath = [[NSBundle mainBundle] pathForResource:@"qliqCharge-schema" ofType:@"sql"];
        [[DBUtil instance] loadSchema:qliqSchemaPath];
		SuperbillService *sbService = [[SuperbillService alloc] init];
		[sbService getSuperbillInfoForUser];
		 */
    }
    return self;
}

-(void) dealloc
{
    [super dealloc];
}

-(UIImage *) moduleLogo
{
    return [UIImage imageNamed:@"qliqCharge_logo.png"];
}


#pragma mark -
#pragma mark Protected

-(BOOL) handleSipMessage:(QliqSipMessage *)message
{
    if ([message.type compare:@"a2a"] == NSOrderedSame)
    {
        if ([message.command compare:@"notification"] == NSOrderedSame)
        {
            QliqSupernodeNotificationMessage *notificationMessage = (QliqSupernodeNotificationMessage*)message;
            return [self processSupernodeNotification:notificationMessage];
        }
    }
    else if ([message.type compare:@"response"] == NSOrderedSame)
    {
        if ([message.command compare:@"put"] == NSOrderedSame)
        {
            
            if ([message.subject compare:@"census"] == NSOrderedSame)
            {
                QliqPutCensusRequest *putCensusRequest = (QliqPutCensusRequest*)message;
                [self processSuperNodePutCensusRequest:putCensusRequest];
                return YES;
            }
        }
    }
    return NO;
}

#pragma mark -
#pragma mark Private

-(BOOL) processSupernodeNotification:(QliqSupernodeNotificationMessage *)message
{
    Buddy *fromBuddy = [BuddyList getBuddyBySipUri:message.fromUri];
    if (fromBuddy && [fromBuddy.roles containsObject:@"Data Server"])
    {
        if ([message.subject compare:@"census"] == NSOrderedSame)
        {
            [self pullCensusFromDataServer];
            return YES;
        }
        else if ([message.subject compare:@"appointment"] == NSOrderedSame)
        {
            [self pullAppointmentFromDataServer];
            return YES;
        }
    }
    else
    {
        DDLogSupport(@"Cannot process SuperNode notification because cannot get qliqId for URI: %@", message.fromUri);
    }
    return NO;    
}

- (BOOL) processCensus:(NSDictionary *)censusDict fromUser:(NSString *)qliqId
{
    // TODO:
    // - transaction
    // - data validation
    
	Physician *me = [Physician currentPhysician];
	if (me == nil) {
		DDLogError(@"Cannot get physician object for the current user");
		return NO;
	}
    
	NSDictionary *dict = [censusDict objectForKey:CENSUS_ADMITTING_PHYSICIAN];
	if (!dict) {
        DDLogError(@"No admittingPhyscian field");
        return NO;
    }
    Physician *admittingPhysician = [Physician physicianFromDict:dict];
    if ([Physician getPhysicianWithNPI:admittingPhysician.physicianNpi] == nil)
        [Physician addPhysician:admittingPhysician];
	
	ReferringPhysician *referringPhysician = nil;
	dict = [censusDict objectForKey:CENSUS_REFERRING_PHYSICIAN];
	if (dict) {
		referringPhysician = [ReferringPhysician referringPhysicianFromDict:dict];
        if ([ReferringPhysician getReferringPhysician:referringPhysician.referringPhysicianNpi] == nil)
            [ReferringPhysician addReferringPhysician:referringPhysician];
    }
    
	Physician *activePhysician = nil;
	dict = [censusDict objectForKey:CENSUS_ACTIVE_PHYSICIAN];
	if (dict) {
		activePhysician = [Physician physicianFromDict:dict];
        if ([Physician getPhysicianWithNPI:activePhysician.physicianNpi] == nil)
            [Physician addPhysician:activePhysician];
    }
	
	dict = [censusDict objectForKey:CENSUS_PATIENT];
	if (dict == nil) {
		DDLogError(@"No patient object in JSON");
		return NO;
	}
	Patient_old *patient = [Patient_old patientFromDict:dict];
	
	// getPatientId will add the patient if doesn't exist
	NSInteger patientId = [Patient_old getPatientId:patient];
    
	dict = [censusDict objectForKey:CENSUS_FACILITY];
	if (dict == nil) {
		DDLogError(@"No facility object in JSON");
		return NO;
	}
	Facility_old *facility = [Facility_old facilityFromDict:dict];
	/*
	 double facilityNpi = [Facility getFacilityIdByNpi:thisFacilityNpi];
	 if (facilityNpi == 0) {
	 DDLogError(@"Cannot find facility with NPI: '%@'", facilityNpi);
	 return;
	 }*/
	
	Census_old *census = [Census_old censusFromDict:censusDict];
	census.patientId = patientId;
	census.physicianNpi = admittingPhysician.physicianNpi;
	census.activePhysicianNpi = activePhysician.physicianNpi;
	census.facilityNpi = facility.facilityNpi;
	census.referringPhysicianNpi = (referringPhysician ? referringPhysician.referringPhysicianNpi : 0.0);
	census.activePhysicianNpi = (activePhysician ? activePhysician.physicianNpi : 0.0);
	
    if (census.metadata && census.metadata.seq > 0) {
        [[DBPersist instance] setLastSubjectSeqIfGreater:census.metadata.seq
                                              forSubject:@"census"
                                                 forUser:qliqId
                                            andOperation:PullOperation];
    }
    
	NSInteger censusId = [Census_old getCensusId:census];
    BOOL isNewCensus = (censusId == 0);
    if (isNewCensus) {
        censusId = [Census_old addPatientToCensus:census];
    } else {
        census.censusId = censusId;	
        
        Metadata *localMd = [[DBPersist instance] tableMetadata:@"census" forRowId:censusId];
        if ([census.metadata.uuid compare:localMd.uuid] != NSOrderedSame) {
            DDLogError(@"Recevied census' uuid doesn't match the one in db, censusId: %u, local uuid: %@, received uuid: %@",
                       censusId, census.metadata.uuid, localMd.uuid);
            return NO;
        }
        
        NSUInteger localRev = [Metadata revisionNumberFromString:localMd.rev];
        NSUInteger serverRev = [Metadata revisionNumberFromString:census.metadata.rev];
        if (serverRev < localRev) 
        {
            return NO;
        } else if ([localMd.rev compare:census.metadata.rev] == NSOrderedSame) {
            DDLogVerbose(@"Received census with the same revision number that I already have, skipping");
            return YES;
        }
        
        if (localMd.isRevisionDirty) {
            DDLogInfo(@"Received census but I have not pushed data for it also, trying to merge");
            return [self mergeCensusWithLocalChanges: census: censusDict fromUser:qliqId];
        }
        
        [Census_old updateCensus:census];
    }
    NSArray *encountersArray = [censusDict objectForKey:CENSUS_ENCOUNTERS];
    [self processEncounters:encountersArray fromUser:qliqId forCensusId:censusId];
	
    return YES;
}

- (BOOL) processEncounters:(NSArray *)encountersArray fromUser:(NSString *)qliqId forCensusId:(int)censusId
{
    // Break in a loop mean memory leaks this is why we use NSAutoreleasePool.
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    BOOL ret = TRUE;
    
    for (NSDictionary *encounterDict in encountersArray) {
        
        if (![self processEncounter: encounterDict fromUser:qliqId forCensusId:censusId]) {
            ret = NO;
            break;
        }
    }
    
    [pool release];
    return ret;
}

- (BOOL) processEncounter: (NSDictionary *)encounterDict fromUser:(NSString *)qliqId forCensusId:(int)censusId
{
    BOOL ret = YES;
    DBPersist *db = [DBPersist instance];    
    
    Physician *attendingPhysician = [Physician physicianFromDict:[encounterDict objectForKey:CENSUS_ATTENDING_PHYSICIAN]];
    if (![attendingPhysician isValid]) {
        DDLogError(@"Cannot parse attending physician from user: %@", qliqId);
        return NO;
    }
    // This call we add the physician if he doesn't exist
    double attendingPhysicianNpi = [db getPhysicianId:attendingPhysician];
    
    int encounterStatus = EncounterStatusVisit;
    {
        NSNumber *statusNumber = [encounterDict objectForKey:CENSUS_ENCOUNTERS_STATUS];
        if (!statusNumber) {
            DDLogError(@"Cannot parse encounter status from user: %@", qliqId);
            return NO;
        }
        encounterStatus = [statusNumber intValue];
    }
    /*
     * TODO: completion date is hardcoded in DBPersist
     *
     if (encounterStatus == EncounterStatusComplete) {
     dosStr = [encounterDict objectForKey:CENSUS_ENCOUNTERS_COMPLETION_DATE];
     encounterObj.completionDate = [Helper strDateISO8601ToInterval:dosStr];            
     }*/
    
    NSString *dosStr = [encounterDict objectForKey:CENSUS_ENCOUNTERS_DOS];
    NSString *lastUpdatedStr = [encounterDict objectForKey:CENSUS_ENCOUNTERS_LAST_UPDATED];
    
    Encounter_old *encounterObj = [[[Encounter_old alloc] init] autorelease];
    encounterObj.censusId = censusId;
    encounterObj.dateOfService = [Helper strDateISO8601ToInterval:dosStr];
    encounterObj.attendingPhysicianNpi = attendingPhysicianNpi;
    encounterObj.status = encounterStatus;
    encounterObj.lastUpdated = [Helper strDateISO8601ToInterval:lastUpdatedStr];
    encounterObj.lastUpdatedUser = [encounterDict objectForKey:CENSUS_ENCOUNTERS_LAST_UPDATED_USER];
    int encounterId = [Encounter_old addEncounter:encounterObj];
    
    for (NSDictionary *cptDict in [encounterDict objectForKey:CENSUS_ENCOUNTERS_CPTS]) {
        EncounterCpt *encounterCptObj = [[[EncounterCpt alloc] initWithPrimaryKey:0] autorelease];
        encounterCptObj.encounterId = encounterId;
        
        NSString *cptWithModifiers = [cptDict objectForKey:CENSUS_CPTS_CODE];
        if (!cptWithModifiers) {
            DDLogError(@"Cannot find code field in encounter from user: %@", qliqId);
            return NO;
        }
        NSArray *codes = [cptWithModifiers componentsSeparatedByString:@"-"];
        encounterCptObj.cptCode = [codes objectAtIndex:0];
        
        int encounterCptId = [db addEncounterCpt:encounterCptObj];
        
        for (int i = 1; i < [codes count]; ++i) {
            EncounterCptModifier *encounterCptModifierObj = [[[EncounterCptModifier alloc] initWithPrimaryKey:0] autorelease];
            encounterCptModifierObj.encounterCptId = encounterCptId;
            encounterCptModifierObj.modifier = [codes objectAtIndex:i];
            [EncounterCptModifier addEncounterCptModifier:encounterCptModifierObj];
        }
        
        int i = 0;
        for (NSString *icdCode in [cptDict objectForKey:CENSUS_CPTS_ICDS]) {
            EncounterIcd *newEncounterIcdObj = [[[EncounterIcd alloc] initWithPrimaryKey:0] autorelease];
            newEncounterIcdObj.encounterCptId = encounterCptId;
            newEncounterIcdObj.icdCode = icdCode;
            newEncounterIcdObj.isPrimary = (i == 0);
            [EncounterIcd addEncounterIcd:newEncounterIcdObj];
            ++i;
        }
    }
    return ret;
}

- (BOOL) mergeCensusWithLocalChanges:(Census_old *)remoteCensus: (NSDictionary *)remoteCensusDict fromUser:(NSString *)qliqId
{
    if (remoteCensus.censusId == 0) {
        NSInteger censusId = [Census_old getCensusId:remoteCensus];
        if (censusId == 0) {
            DDLogError(@"Cannot find censusId for a census to merge from user: %@", qliqId);
            return NO;
        }
        remoteCensus.censusId = censusId;
    }
    Census_old *localCensus = [[DBPersist instance] getCensusObject:remoteCensus.censusId];
    
    if (NO && [localCensus isPatientDirty]) {
        // Ask the user to merge changes
    } else {
        localCensus.patient = remoteCensus.patient;
        
        localCensus.gender = remoteCensus.gender;
        localCensus.race = remoteCensus.race;
        localCensus.insurance = remoteCensus.insurance;
        localCensus.dateOfBirth = remoteCensus.dateOfBirth;
        
        localCensus.metadata.rev = remoteCensus.metadata.rev;
        [[DBPersist instance] updateCensus:localCensus];
    }
    
    if (NO && [localCensus isCensusPartDirty])
    {
        // Ask the user to merge changes
    } 
    else
    {
        localCensus.physicianNpi = remoteCensus.physicianNpi;
        localCensus.activePhysicianNpi = remoteCensus.activePhysicianNpi;
        localCensus.referringPhysicianNpi = remoteCensus.referringPhysicianNpi;        
        localCensus.referringPhysicianName = remoteCensus.referringPhysicianName;        
        localCensus.facilityNpi = remoteCensus.facilityNpi;
        localCensus.facilityName = remoteCensus.facilityName;
        
        localCensus.admitDate = remoteCensus.admitDate;
        localCensus.dischargeDate = remoteCensus.dischargeDate;
        localCensus.room = remoteCensus.room;
        localCensus.active = remoteCensus.active;
        
        localCensus.admittingPhysician = remoteCensus.admittingPhysician;
        localCensus.activePhysician = remoteCensus.activePhysician;
        localCensus.referringPhysician = remoteCensus.referringPhysician;
        localCensus.facility = remoteCensus.facility;
        
        localCensus.metadata.rev = remoteCensus.metadata.rev;
        [[DBPersist instance] updateCensus:localCensus];
    }
    
    NSArray *remoteEncountersArray = [remoteCensusDict objectForKey:CENSUS_ENCOUNTERS];
    BOOL ret = [self mergeEncountersWithLocalChanges:remoteEncountersArray forCensus:localCensus fromUser:qliqId];
    
    if (ret) {
        [localCensus setRevisionDirty:YES];
    }
    
    return ret;
}

- (BOOL) mergeEncountersWithLocalChanges:(NSArray *)remoteEncountersArray forCensus:(Census_old *)localCensus fromUser:(NSString *)qliqId
{
    // Break in a loop mean memory leaks this is why we use NSAutoreleasePool.
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    BOOL ret = TRUE;
    DBPersist *db = [DBPersist instance];
    
    int censusId = localCensus ? localCensus.censusId : 0;
    
    for (NSDictionary *encounterDict in remoteEncountersArray) {
        
        Physician *attendingPhysician = [Physician physicianFromDict:[encounterDict objectForKey:CENSUS_ATTENDING_PHYSICIAN]];
        if (![attendingPhysician isValid]) {
            DDLogError(@"Cannot parse attending physician from user: %@", qliqId);
            ret = NO;
            break;
        }        
        // This call will add the physician if he doesn't exist
        double attendingPhysicianNpi = [db getPhysicianId:attendingPhysician];        
        
        NSString *dosStr = [encounterDict objectForKey:CENSUS_ENCOUNTERS_DOS];        
        NSTimeInterval dos = [Helper strDateISO8601ToInterval:dosStr];
        
        NSString *lastUpdatedStr = [encounterDict objectForKey:CENSUS_ENCOUNTERS_LAST_UPDATED];
        //NSTimeInterval lastUpdated = [Helper strDateISO8601ToInterval:lastUpdatedStr];
        NSString *lastUpdatedUser = [encounterDict objectForKey:CENSUS_ENCOUNTERS_LAST_UPDATED_USER];        
        
        int localEncounterId = censusId ? [db getEncounterForCensus:localCensus.censusId: attendingPhysicianNpi :dos] : 0;
        
        if (localEncounterId == 0) {
            // No local encounter to merge, just save the remote one
            if (![self processEncounter: encounterDict fromUser:qliqId forCensusId:censusId])
            {
                ret = NO;
                break;
            }
            continue;
        }
        
        Encounter_old *localEncounter = [db getEncounterWithId:localEncounterId];
        
        if ([localEncounter.lastUpdatedUser compare:lastUpdatedUser] == NSOrderedSame) {
            // This encounter belongs to the current physician, we assume iphone has newest data
            continue;
        }        
        // TODO: merge CPT and ICDs and notes
        
        
        int encounterStatus = EncounterStatusVisit;
        {
            NSNumber *statusNumber = [encounterDict objectForKey:CENSUS_ENCOUNTERS_STATUS];
            if (!statusNumber) {
                DDLogError(@"Cannot parse encounter status from user: %@", qliqId);
                ret = NO;
                break;
            }
            encounterStatus = [statusNumber intValue];
        }
        /*
         * TODO: completion date is hardcoded in DBPersist
         *
         if (encounterStatus == EncounterStatusComplete) {
         dosStr = [encounterDict objectForKey:CENSUS_ENCOUNTERS_COMPLETION_DATE];
         encounterObj.completionDate = [Helper strDateISO8601ToInterval:dosStr];            
         }*/
        
        Encounter_old *remoteEncounterObj = [[[Encounter_old alloc] init] autorelease];
        remoteEncounterObj.censusId = localCensus.censusId;
        remoteEncounterObj.dateOfService = dos;
        remoteEncounterObj.attendingPhysicianNpi = attendingPhysicianNpi;
        remoteEncounterObj.status = encounterStatus;
        remoteEncounterObj.lastUpdated = [Helper strDateISO8601ToInterval:lastUpdatedStr];
        remoteEncounterObj.lastUpdatedUser = [encounterDict objectForKey:CENSUS_ENCOUNTERS_LAST_UPDATED_USER];
        
        BOOL areEncountersSame = NO;
        
        if (remoteEncounterObj.dateOfService == localEncounter.dateOfService &&
            remoteEncounterObj.attendingPhysicianNpi == localEncounter.attendingPhysicianNpi &&
            remoteEncounterObj.status == localEncounter.status) {
            areEncountersSame = YES;
        } else {
            // TODO: display UI to the user
        }
        int encounterId = [Encounter_old addEncounter:remoteEncounterObj];
        
        for (NSDictionary *cptDict in [encounterDict objectForKey:CENSUS_ENCOUNTERS_CPTS]) {
            EncounterCpt *remoteEncounterCptObj = [[[EncounterCpt alloc] initWithPrimaryKey:0] autorelease];
            remoteEncounterCptObj.encounterId = encounterId;
            //            encounterCptObj.createdAt = [[NSDate date] timeIntervalSince1970];
            //            encounterCptObj.createdUser = [Helper getUsername];
            
            NSString *cptWithModifiers = [cptDict objectForKey:CENSUS_CPTS_CODE];
            if (!cptWithModifiers) {
                DDLogError(@"Cannot find code field in encounter from user: %@", qliqId);
                ret = NO;
                break;
            }
            NSArray *remoteModifiers = [cptWithModifiers componentsSeparatedByString:@"-"];
            remoteEncounterCptObj.cptCode = [remoteModifiers objectAtIndex:0];
            
            NSMutableSet *cptModifiers = [[[NSMutableSet alloc] init] autorelease];
            for (int i = 1; i < [remoteModifiers count]; ++i) {
                [cptModifiers addObject:[remoteModifiers objectAtIndex:i]];
            }            
            
            int encounterCptId = [db addEncounterCpt:remoteEncounterCptObj];
            
            //for (int i = 1; i < [codes count]; ++i) {
            for (NSString *modifier in cptModifiers) {
				EncounterCptModifier *encounterCptModifierObj = [[[EncounterCptModifier alloc] initWithPrimaryKey:0] autorelease];
				encounterCptModifierObj.encounterCptId = encounterCptId;
				encounterCptModifierObj.modifier = modifier;
				[EncounterCptModifier addEncounterCptModifier:encounterCptModifierObj];
            }
            
            int i = 0;
            for (NSString *icdCode in [cptDict objectForKey:CENSUS_CPTS_ICDS]) {
                EncounterIcd *newEncounterIcdObj = [[[EncounterIcd alloc] initWithPrimaryKey:0] autorelease];
                newEncounterIcdObj.encounterCptId = encounterCptId;
                newEncounterIcdObj.icdCode = icdCode;
                newEncounterIcdObj.isPrimary = (i == 0);
                [EncounterIcd addEncounterIcd:newEncounterIcdObj];
                ++i;
            }
        }
    }
    
    [pool release];
    return ret;
}    

- (BOOL) processAppointment:(NSDictionary *)appDict fromUser:(NSString *)qliqId
{
    Appointment *app = [Appointment appointmentFromDict:appDict];
    NSInteger appId = [Appointment addAppointment:app];
    // appId is unused right now
    appId = 0;
    return YES;
}

-(void) processSuperNodePutCensusRequest:(QliqPutCensusRequest *)message
{
    Buddy *fromBuddy = [BuddyList getBuddyBySipUri:message.fromUri];
    if (fromBuddy)
    {
        [[Outbound sharedOutbound] processSuperNodePutCensusResponse:message.dataDict fromUser:fromBuddy.buddyQliqId];
    }
}

-(void) onSipRegistrationStatusChanged:(BOOL)registered
{
    if (registered)
    {
        // TODO: refactor, that we pull appointments when census query finished
        [self pullCensusFromDataServer];
        [self pullAppointmentFromDataServer];
    }
}

#pragma mark -
#pragma mark DataServerCallback

-(void) pullCensusFromDataServer
{
    [[DataServerClient sharedDataServerClient] sendQuery:@"census" delegate:self extraQuery:nil limit:0 lastSeq:-1];
}

-(void) pullAppointmentFromDataServer
{
    [[DataServerClient sharedDataServerClient] sendQuery:@"appointment" delegate:self extraQuery:nil limit:0 lastSeq:-1];    
}

- (BOOL) onQueryPageReceived: (NSString *)qliqId: (NSString *)subject: (NSString *)requestId: (NSArray *)results: (int)page: (int)pageCount: (int)totalPages
{
    BOOL ret = [DataServerClient defaultOnQueryPageReceived:self :qliqId :subject :requestId :results :page :pageCount :totalPages];

    if (ret && [results count] > 0)
    {
        if ([subject compare:@"census"] == NSOrderedSame || [subject compare:@"appointment"] == NSOrderedSame)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:SIPNewCensusNotification object:self];
            [[UserNotifications getInstance] notifyNewAdmition];
        }
    }
    return ret;
}

- (BOOL) onQueryResultReceived: (NSString *)qliqId: (NSString *)subject: (NSString *)requestId: (NSDictionary *)result
{
    if ([subject compare:@"census"] == NSOrderedSame)
        return [self processCensus:result fromUser:qliqId];
    else if ([subject compare:@"appointment"] == NSOrderedSame)
        return [self processAppointment:result fromUser:qliqId];
    else
        return NO;
}

- (void) onQuerySent: (NSString *)qliqId: (NSString *)subject: (NSString *)requestId
{
    
}

- (void) onQuerySendingFailed: (NSString *)qliqId: (NSString *)subject: (NSString *)requestId
{
    
}

- (void) onQueryFinished: (NSString *)qliqId: (NSString *)subject: (NSString *)requestId withStatus:(int)status
{
    
}

@end

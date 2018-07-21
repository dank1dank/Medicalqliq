//
//  Census.m
//  CCiPhoneApp
//
//  Created by Ravi Ada on 4/12/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import "Census_old.h"
#import "DBPersist.h"
#import "Helper.h"
#import "CensusSchema.h"
#import "Outbound.h"

@implementation AllCharges
@synthesize censusId,dateOfService,encounterStatus,strCptCodes,strIcdCodes;

- (void) dealloc {
	[super dealloc];
	[strCptCodes release];
	[strIcdCodes release];
}
@end

@implementation Census_old
@synthesize censusId,patientId,patientName,patientLastName,patientFirstName,patientMiddleName;
@synthesize physicianNpi,activePhysicianNpi,physicianInitials,physicianSpecialty,facilityNpi,facilityName,mrn, insurance, censusType;
@synthesize room,gender,race,dateOfBirth,dateOfService,selectedDos,admitDate,dischargeDate,referringPhysicianNpi,referringPhysicianName,active;
@synthesize lastUpdated, lastUpdatedUser;
@synthesize isDirty,isDetailViewHydrated;
@synthesize patient, admittingPhysician, activePhysician, referringPhysician, facility, metadata;

+ (NSMutableArray *) getCensusToDisplay:(NSString *)dateOfService andPhysicianId:(double) physicianNpi andFacilityId:(double) facilityNpi andBtnPressed:(NSString*)btnLabel  andSortBy:(NSString*) sortOrder
{
	return [[DBPersist instance] getCensusToDisplay:dateOfService andPhysicianId:physicianNpi andFacilityId:facilityNpi andBtnPressed:btnLabel andSortBy:sortOrder];
}

+ (NSMutableArray *) getCensusForFacility:(NSString *)dateOfService:(double) facilityNpi:(double) physicianNpi
{
	return [[DBPersist instance] getCensusForFacility:dateOfService:facilityNpi:physicianNpi];   
}
+ (NSInteger) addPatientToCensus:(Census_old *)census
{
    return [[DBPersist instance] addPatientToCensus:census];
}
+ (BOOL) updateCensus:(Census_old *)census
{
    return [[DBPersist instance] updateCensus:census];
}
+ (BOOL) dischargePatient:(Census_old *)census
{
    return [[DBPersist instance] dischargePatient:census];
}
+ (Census_old *) getCensusObject:(NSInteger) censusId
{
    return [[DBPersist instance] getCensusObject:censusId];
}
+ (NSMutableArray *) getActiveCensusObjects:(double) physicianNpi andBtnPressed:(NSString *)btnPressed;
{
	return [[DBPersist instance] getActiveCensusObjects:physicianNpi andBtnPressed:btnPressed];   
}
+ (BOOL) hasPriorChargesToAdmitDate:(Census_old *) censusObj andNewAdmitDate:(NSTimeInterval)admitDateInSecs
{
	return [[DBPersist instance] hasPriorChargesToAdmitDate:censusObj andNewAdmitDate:admitDateInSecs];   
}
+ (BOOL) hasLaterChargesToDischargeDate:(Census_old *) censusObj andNewDischargeDate:(NSTimeInterval) dischargeDateInSecs
{
	return [[DBPersist instance] hasLaterChargesToDischargeDate:censusObj andNewDischargeDate:dischargeDateInSecs];   
}
+ (NSInteger) getPendingCountForFacility:(NSMutableArray*) censusArray
{
	return [[DBPersist instance] getPendingCountForFacility:censusArray];
}

+ (NSInteger) getPendingCount:(NSInteger)phyId andFacilityId:(NSInteger) facId  andDos:(NSTimeInterval) dos{
	return [[DBPersist instance] getPendingCount:phyId andFacilityId:facId andDos:dos];
}

+ (NSInteger) getCensusId:(Census_old *) census
{
	return [[DBPersist instance] getCensusId:census];
}

+ (NSInteger) getCensusIdOrInsert:(Census_old *) census
{
	return [[DBPersist instance] getCensusIdOrInsert:census];
}

+ (void) createEncounter:(Census_old*) censusObj
{

	Encounter_old *encounterObj = [Encounter_old getEncounterObjForCensus:censusObj.censusId :censusObj.physicianNpi :censusObj.dateOfService];
	
	if(encounterObj !=nil && encounterObj.encounterId>0){
		NSInteger encounterStatus;
		if(encounterObj.status==EncounterStatusNoVisit)
			encounterStatus=EncounterStatusVisit;
		else if(encounterObj.status==EncounterStatusVisit)
			encounterStatus=EncounterStatusNoVisit;
		[Encounter_old updateEncounter:encounterObj.encounterId withStatus:encounterStatus];
	}else{
		Encounter_old *newencounter = [[[Encounter_old alloc] init] autorelease];
		newencounter.censusId = censusObj.censusId;
		newencounter.dateOfService = censusObj.dateOfService;
		if(censusObj.censusType == NonConsult)
			newencounter.status=EncounterStatusNoVisit;
		else 
			newencounter.status=EncounterStatusVisit;
		newencounter.attendingPhysicianNpi=censusObj.physicianNpi;
		[Encounter_old addEncounter:newencounter];
	}	
}

+ (id) censusFromDict:(NSDictionary *)dict
{
	Census_old *census = [[[Census_old alloc] init] autorelease];
	
	NSString *strDate = [dict objectForKey:CENSUS_ADMIT_DATE];
	census.admitDate = [Helper strDateISO8601ToInterval:strDate];
	strDate = [dict objectForKey:CENSUS_DISCHARGE_DATE];
	if ([strDate length] > 0) {
		census.dischargeDate = [Helper strDateISO8601ToInterval:strDate];
		census.active = FALSE;
	} else {
		census.active = TRUE;
	}
	
	census.room = [dict objectForKey:CENSUS_ROOM];
  	census.mrn = [dict objectForKey:CENSUS_MRN];
	
	NSString *type = [dict objectForKey:CENSUS_TYPE];
	if ([type compare:@"Consult"] == NSOrderedSame)
		census.censusType = Consult;
	else
		census.censusType = NonConsult;
    
	// TODO:
	// here census object is missing patient, physician and facility information
	// I think it should be refactored to reference those as subobjects
    
    census.patient = [Patient_old patientFromDict:[dict objectForKey:CENSUS_PATIENT]];
    census.admittingPhysician = [Physician physicianFromDict:[dict objectForKey:CENSUS_ADMITTING_PHYSICIAN]];
    census.facility = [Facility_old facilityFromDict:[dict objectForKey:CENSUS_FACILITY]];
    
    NSDictionary *tmpDict = [dict objectForKey:CENSUS_ACTIVE_PHYSICIAN];
    if (tmpDict)
        census.activePhysician = [Physician physicianFromDict:tmpDict];

    tmpDict = [dict objectForKey:CENSUS_REFERRING_PHYSICIAN];
    if (tmpDict)
        census.referringPhysician = [Physician physicianFromDict:tmpDict];
    
    
    tmpDict = [dict objectForKey:CENSUS_METADATA];
    if (tmpDict)
        census.metadata = [Metadata metadataFromDict:tmpDict];    
    
    return census;
}

- (NSMutableDictionary *) toDict
{
    NSMutableDictionary *dict = [[[NSMutableDictionary alloc] init] autorelease];

    NSString *dateStr = [Helper intervalToISO8601DateString:admitDate];
    [dict setObject:dateStr forKey:CENSUS_ADMIT_DATE];
    
    if (dischargeDate != 0) {
        NSString *dateStr = [Helper intervalToISO8601DateString:dischargeDate];
        [dict setObject:dateStr forKey:CENSUS_DISCHARGE_DATE];
    }
    
    NSString *typeStr;
    if (censusType == Consult)
        typeStr = @"Consult";
    else
        typeStr = @"Admit";
    [dict setObject:typeStr forKey:CENSUS_TYPE];
    
    if (mrn)
        [dict setObject:mrn forKey:CENSUS_MRN];
    
    if (room)
        [dict setObject:room forKey:CENSUS_ROOM];

    [dict setObject:[admittingPhysician toDict] forKey:CENSUS_ADMITTING_PHYSICIAN];
    [dict setObject:[patient toDict] forKey:CENSUS_PATIENT];    
    [dict setObject:[facility toDict] forKey:CENSUS_FACILITY];    

    if (referringPhysician)
        [dict setObject:[referringPhysician toDict] forKey:CENSUS_REFERRING_PHYSICIAN];

    if (activePhysician)
        [dict setObject:[activePhysician toDict] forKey:CENSUS_ACTIVE_PHYSICIAN];    
    
    if (metadata)
        [dict setObject:[metadata toDict] forKey:CENSUS_METADATA];
    
    return dict;
}

- (void) addEncountersToDict:(NSMutableDictionary *)dict
{
    NSMutableArray *retArray = [[[NSMutableArray alloc] init] autorelease];
    NSArray *encounterCptArray = [[DBPersist instance] getChargesToDisplayForCensus:self andDos:1];

    if ([encounterCptArray count] == 0)
        return;
    
    int currentEncounterId = 0;
    NSMutableDictionary *currentEncounterDict = nil;
    NSMutableArray *currentEncounterCpts = nil;
    
    for (NSDictionary *encounterCptDict in encounterCptArray) {
        EncounterCpt *encounterCptObj = [encounterCptDict objectForKey:@"cpt"];
        
        // If this is new encounter
        if (encounterCptObj.encounterId != currentEncounterId) {
            if (currentEncounterDict) {
                [retArray addObject:currentEncounterDict];
                [currentEncounterDict release];                
            }
            currentEncounterId = encounterCptObj.encounterId;
            currentEncounterDict = [[NSMutableDictionary alloc] init];
            currentEncounterCpts = [[NSMutableArray alloc] init];
            [currentEncounterDict setObject:currentEncounterCpts forKey:CENSUS_ENCOUNTERS_CPTS];

            // dos & status
            NSString *dosString = [Helper intervalToISO8601DateString:encounterCptObj.dateOfService];
            [currentEncounterDict setObject:dosString forKey:CENSUS_ENCOUNTERS_DOS];
            [currentEncounterDict setObject:[NSNumber numberWithInt:encounterCptObj.status] forKey:CENSUS_ENCOUNTERS_STATUS];
            
            
            
            // Attending physician object
            NSMutableDictionary *attendingPhysicianDict = [[NSMutableDictionary alloc] init];
            NSNumber *npiNumber = [encounterCptDict objectForKey:@"attending_physician_npi"];
            NSString *npi = [NSString stringWithFormat:@"%0.0f", [npiNumber doubleValue]];
            NSString *attendingPhysicianName = [encounterCptDict objectForKey:@"attending_physician_name"];
            [attendingPhysicianDict setObject:npi forKey:CENSUS_ATTENDING_PHYSICIAN_NPI];
            [attendingPhysicianDict setObject:attendingPhysicianName forKey:CENSUS_ATTENDING_PHYSICIAN_NAME];
            [currentEncounterDict setObject:attendingPhysicianDict forKey:CENSUS_ATTENDING_PHYSICIAN];
            [attendingPhysicianDict release];
            
            // Notes
            NSArray *notesObjectsArray = [[DBPersist instance] getEncounterNotesToDisplay:currentEncounterId];
            if ([notesObjectsArray count] > 0)
            {
                NSMutableArray *notesArray = [[NSMutableArray alloc] init];
                for (EncounterNote *noteObj in notesObjectsArray)
                {
                    [notesArray addObject:[noteObj toDict]];
                }
                
                [currentEncounterDict setObject:notesArray forKey:CENSUS_ENCOUNTERS_NOTES];
                [notesArray release];
            }            
        }
        
        /////////////////////////////////////////////////////////
        // Cpt object
        
        NSMutableDictionary *cptDict = [[NSMutableDictionary alloc] init];
        [cptDict setObject:encounterCptObj.codeWithModifiers forKey:CENSUS_CPTS_CODE];

        NSArray *icdsObjectsArray = [encounterCptDict objectForKey:@"icds"];
        if ([icdsObjectsArray count] > 0) 
        {
            NSMutableArray *icdsArray = [[NSMutableArray alloc] init];
            for (EncounterIcd *icd in icdsObjectsArray)
            {
                if (icd.isPrimary)
                    [icdsArray insertObject:icd.icdCode atIndex:0];
                else
                    [icdsArray addObject:icd.icdCode];
            }
            
            [cptDict setObject:icdsArray forKey:CENSUS_CPTS_ICDS];
            [icdsArray release];
        }
        
        [currentEncounterCpts addObject:cptDict];
        [cptDict release];
    }
    
    if (currentEncounterDict) {
        [retArray addObject:currentEncounterDict];
        [currentEncounterDict release];                
    }
    
    [dict setObject:retArray forKey:CENSUS_ENCOUNTERS];
}

- (void) setMetadataAuthor:(NSString *)author
{
    if (metadata == nil) {
        self.metadata = [Metadata createNew];        
    }
    if ([metadata.author compare:author] != NSOrderedSame) {
        metadata.author = author;
        if (censusId > 0)
            [[DBPersist instance] updateTableMetadataAuthor:@"census" forRowId:censusId author:author];
    }
}

- (void) setRevisionDirty:(BOOL) dirty
{
    if (dirty) {
        [self setMetadataAuthor:[Metadata defaultAuthor]];
        [[DBPersist instance] setRevisionDirty:@"census" forRowId:censusId dirty:dirty];
//        [[Outbound sharedOutbound] scheduleCensusPush];
    }
    isDirty = dirty;
}

- (BOOL) isRevisionDirty
{
    return isDirty;
}

- (BOOL) isPatientDirty
{
    return NO;
}

- (BOOL) isCensusPartDirty
{
    return NO;
}

- (id) initWithPrimaryKey:(NSInteger) pk {
    
    [super init];
    censusId = pk;
    isDetailViewHydrated = NO;
    
    return self;
}


- (void) dealloc {
	[patientName release];
	[patientLastName release];
	[patientFirstName release];
	[patientMiddleName release];
	[physicianInitials release];
	[physicianSpecialty release];
    [facilityName release];
    [mrn release];
    [room release];
    [gender release];
    [race release];
    [referringPhysicianName release];
    
    [patient release];
    [admittingPhysician release];
    [activePhysician release];
    [referringPhysician release];
    [facility release];    
    [metadata release];
	[super dealloc];
}

@end

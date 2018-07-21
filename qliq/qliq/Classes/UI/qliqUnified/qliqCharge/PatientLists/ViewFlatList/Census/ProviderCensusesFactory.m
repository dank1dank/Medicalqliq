//
//  ProviderCensusesFactory.m
//  qliq
//
//  Created by Paul Bar on 3/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ProviderCensusesFactory.h"
#import "QliqUser.h"
#import "Census.h"
#import "PatientVisit.h"

#import "CareteamService.h"
#import "PatientVisitService.h"
#import "EncounterService.h"

@implementation ProviderCensusesFactory
@synthesize provider;
@synthesize careteamService;
@synthesize patientVisitService;
@synthesize encounterService;

-(id) init
{
    self = [super init];
    if(self)
    {
        self.careteamService = [[CareteamService alloc] init];
        self.patientVisitService = [[PatientVisitService alloc] init];
        self.encounterService = [[EncounterService alloc] init];
    }
    return self;
}

-(void) dealloc
{
    [self.encounterService release];
    [self.careteamService release];
    [self.patientVisitService release];
    [provider release];
    [super dealloc];
}

-(NSArray*) getCensuesOfUser:(QliqUser *)user forDate:(NSDate *)date withCensusType:(NSString *)censusType
{
    NSMutableArray *mutableRez = [[NSMutableArray alloc] init];
	NSArray *patientVisits = [self.patientVisitService getPatientVisitsForDos:date forProvider:self.provider];
	
	for(PatientVisit *patientVisit in patientVisits)
	{
        if([patientVisit.type isEqualToString:censusType])
        {
            Census *census = [[Census alloc] init];
            census.patientVisit = patientVisit;
            census.patient = [self.patientVisitService getPatientForVisit:patientVisit];
            census.facility = [self.patientVisitService getFacilityOfVisit:patientVisit];
			census.admitUser = [self.patientVisitService getAdmitPhysicianForPatientVisit:patientVisit];
			census.activeUser = [self.patientVisitService getActivePhysicianForPatientVisit:patientVisit];
			census.encounter = [self.encounterService getEncounterOfPatientVisit:patientVisit forDate:date];
            [mutableRez addObject:census];
            [census release];
        }
	}
    
    NSArray *rez = [NSArray arrayWithArray:mutableRez];
    [mutableRez release];
    return rez;
}

@end

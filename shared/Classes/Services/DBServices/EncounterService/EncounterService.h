//
//  EncounterService.h
//  qliq
//
//  Created by Paul Bar on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DBServiceBase.h"

@class Encounter;
@class PatientVisit;

@interface EncounterService : DBServiceBase

-(BOOL) saveEncounter:(Encounter*)encounter;

-(NSArray*)getEncountersForPatientVisit:(PatientVisit*)patientVisit;
-(Encounter*) getEncounterOfPatientVisit:(PatientVisit*)patientVisit forDate:(NSDate*)date;

@end

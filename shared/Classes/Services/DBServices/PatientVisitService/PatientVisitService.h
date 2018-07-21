//
//  ObservationService.h
//  qliq
//
//  Created by Paul Bar on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DBServiceBase.h"
#import "Group.h"
#import "QliqUser.h"

@class Patient;
@class PatientVisit;
@class Facility;
@class Floor;
@class QliqUser;

@interface PatientVisitService : DBServiceBase

-(BOOL) savePatientVisit:(PatientVisit*)patientVisit;
-(Patient*) getPatientForVisit:(PatientVisit*)patientVisit;
-(NSArray*) getPatientVisits;
-(NSArray*) getPatientVisitsForDos:(NSDate *)dateOfService;
-(NSArray*) getPatientVisitsForDos:(NSDate *)dateOfService forCareteamWithId:careteamId onFloor:(Floor *) floor;
-(NSArray*) getPatientVisitsForDos:(NSDate *)dateOfService forProvider:(QliqUser *) provider;
-(NSArray*) getPatientVisitsForDos:(NSDate *)dateOfService forCareteamWithId:(NSNumber*)careteamId;
-(Facility*) getFacilityOfVisit:(PatientVisit*)patientVisit;
-(QliqUser*) getActivePhysicianForPatientVisit:(PatientVisit*)patientVisit;
-(QliqUser*) getAdmitPhysicianForPatientVisit:(PatientVisit*)patientVisit;
@end

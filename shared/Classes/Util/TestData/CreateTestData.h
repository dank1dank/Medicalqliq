//
//  CreateTestData.h
//  CCiPhoneApp
//
//  Created by Ravi Ada on 7/27/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "Physician.h"

@interface CreateTestData : NSObject {

}
- (void) resetDemoData;
- (void) createMyRounds;
- (void) addMyCharges;
- (void) createGroupRounds;
- (void) addGroupCharges;

- (void) createChargesForThisPatient:(NSInteger)newCensusId:(double) physicianNpi;
- (NSInteger) createPhysician:(NSInteger) groupId:(NSString *) name:(NSString *)initials:(NSString*) specialty:(NSString*) email:(double) npi;
- (NSInteger) createPatient:(NSString *)fn:(NSString*)mn:(NSString*)ln:(NSString *)dob:(NSString*)gender:(NSString*)race;
- (NSInteger) createCensus:(NSInteger)newPatId:(double) facilityNpi:(NSString*)rphName:(double) physicianNpi:(NSString *)room:(NSString*)mrn;
- (NSInteger) createFacility:(NSString *) name:(NSString *)type;
- (NSInteger) createPhysicianGroup:(NSString *) name;

@end

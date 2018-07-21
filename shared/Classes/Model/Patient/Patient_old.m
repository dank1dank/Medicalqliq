//
//  Patient.m
//  CCiPhoneApp
//
//  Created by Ravi Ada on 4/12/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import "Patient_old.h"
#import "DBPersist.h"
#import "PatientSchema.h"
#import "Helper.h"
#import "DBHelperNurse.h"

@implementation Patient_old
@synthesize patientId,firstName,middleName,lastName,fullName,dateOfBirth,race,gender,phone,email,insurance;
@synthesize censusId,apptId;
@synthesize isDirty,isDetailViewHydrated;

+ (Patient_old *) getPatientToDisplay:(NSInteger)patientId
{
    return [[DBPersist instance] getPatientToDisplay:patientId];
}
+ (NSMutableArray *) getAllPatientsToDisplay
{
    return [[DBPersist instance] getAllPatientsToDisplay];
}
+ (NSInteger) addPatient:(Patient_old *)patient
{
    return [[DBPersist instance] addPatient:patient];
}
+ (NSInteger) getPatientId:(Patient_old*)patient
{
	return [[DBPersist instance] getPatientId:patient];
}
+ (BOOL) updatePatient:(Patient_old *)patient
{
    return [[DBPersist instance] updatePatient:patient];
}

+ (NSMutableDictionary *) getCareTeamForCensus:(NSInteger) censusId
{
	return [DBHelperNurse getCareTeamForCensus:censusId]; 
}


+ (id) patientFromDict:(NSDictionary *)dict
{
	Patient_old *patient = [[[Patient_old alloc] init] autorelease];
    
	patient.patientId = 0;
	patient.dateOfBirth = 0.0;
	
	patient.firstName = [dict objectForKey:PATIENT_FIRST_NAME];
	patient.lastName = [dict objectForKey:PATIENT_LAST_NAME];
	patient.middleName = [dict objectForKey:PATIENT_MIDDLE_NAME];
	patient.race = [dict objectForKey:PATIENT_RACE];
	patient.email = [dict objectForKey:PATIENT_EMAIL];
	patient.phone = [dict objectForKey:PATIENT_PHONE];
	patient.insurance = [dict objectForKey:PATIENT_INSURANCE];
    
	NSString *gender = [dict objectForKey:PATIENT_GENDER];
	if ([gender compare:@"M"] == NSOrderedSame)
		patient.gender = @"Male";
	else
		patient.gender = @"Female";
	
	NSString *strDate = [dict objectForKey:PATIENT_DOB];
	if ([strDate length] > 0)
		patient.dateOfBirth = [Helper strDateISO8601ToInterval:strDate];
    
	return patient;
}

- (NSMutableDictionary *) toDict
{
    NSMutableDictionary *dict = [[[NSMutableDictionary alloc] init] autorelease];
    [dict setObject:firstName forKey:PATIENT_FIRST_NAME];
    [dict setObject:lastName forKey:PATIENT_LAST_NAME];
    
    if (middleName)
        [dict setObject:middleName forKey:PATIENT_MIDDLE_NAME];
    
    if (race)
        [dict setObject:race forKey:PATIENT_RACE];
    
    if (email)
        [dict setObject:email forKey:PATIENT_EMAIL];

    if (phone)
        [dict setObject:phone forKey:PATIENT_PHONE];
    
    if (insurance)
        [dict setObject:insurance forKey:PATIENT_INSURANCE];
    
    if (dateOfBirth != 0)
        [dict setObject:[Helper intervalToISO8601DateString:dateOfBirth] forKey:PATIENT_DOB];
    
    NSString *genderStr;
    if ([gender compare:@"Male"] == NSOrderedSame)
        genderStr = @"M";
    else
        genderStr = @"F";
    [dict setObject:genderStr forKey:PATIENT_GENDER];     

    return dict;
}

- (BOOL) isValid
{
    return ([firstName length] > 0) && ([lastName length] > 0) &&
           ([gender compare:@"Female"] == NSOrderedSame || [gender compare:@"Male"] == NSOrderedSame);
}

- (id) initWithPrimaryKey:(NSInteger) pk {
    
    if (self = [super init]) {
		patientId = pk;
		isDetailViewHydrated = NO;
	}    
    return self;
}

- (void) dealloc {
 	[firstName release];
    [middleName release];
    [lastName release];
    [race release];
    [gender release];
    [phone release];
    [email release];
    [insurance release];
	[fullName release];
	[super dealloc];
}

@end


@implementation PatientContact
@synthesize patientContactId,patientId,name,relation,phone,mobile,email,isPrimary;

- (id) initWithPrimaryKey:(NSInteger) pk {
    
    if (self = [super init]) {
		patientContactId = pk;
	}    
    return self;
}
- (void) dealloc {
 	[name release];
    [relation release];
    [phone release];
	[mobile release];
    [email release];
    [isPrimary release];
	[super dealloc];
}

@end



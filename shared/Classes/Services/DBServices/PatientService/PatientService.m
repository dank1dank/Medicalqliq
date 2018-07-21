//
//  PatientService.m
//  qliq
//
//  Created by Paul Bar on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PatientService.h"
#import "Patient.h"

@interface PatientService()

-(BOOL) insertPatient:(Patient*) patient;
-(BOOL) updatePatient:(Patient*) patient;
-(BOOL) patientExists:(Patient*) patient;
-(NSString*) generateGuidForPatient;
@end

@implementation PatientService

-(BOOL) savePatient:(Patient *)patient
{
    BOOL rez = NO;
    
    if([patient.guid length] == 0)
    {
        patient.guid = [self generateGuidForPatient];
    }
    
    if([self patientExists:patient])
    {
        rez = [self updatePatient:patient];
    }
    else
    {
        rez = [self insertPatient:patient];
    }
    
    return rez;
    
}

-(NSArray*) getPatinents
{
    NSMutableArray *mutableRez = [[NSMutableArray alloc] init];
    
    NSString *selectQuery = @""
    "SELECT * FROM patient";
    
    FMResultSet *rs = [self.db executeQuery:selectQuery];
    
    while ([rs next])
    {
        [mutableRez addObject:[Patient patientWithResultSet:rs]];
    }
    
    [rs close];
    
    NSArray *rez = [NSArray arrayWithArray:mutableRez];
    [mutableRez release];
    return rez;
}
-(Patient*) getPatientWithGuid:(NSString *) guid
{
    Patient *patientRez = [[Patient alloc] init];
    
    NSString *selectQuery = @""
    "SELECT * FROM patient WHERE guid = ?";
    
    FMResultSet *rs = [self.db executeQuery:selectQuery,guid];
    
    while ([rs next])
    {
		patientRez = [Patient	patientWithResultSet:rs];
    }
    
    [rs close];
    return patientRez;
}

-(Patient *) getPatientWithName:(Patient *) patient
{
    Patient *patientRez = [[Patient alloc] init];
    
    NSString *selectQuery = @""
    "SELECT * FROM patient WHERE first_name = ? AND last_name = ?";
    
    FMResultSet *rs = [self.db executeQuery:selectQuery,patient.firstName,patient.lastName];
    
    while ([rs next])
    {
		patientRez = [Patient	patientWithResultSet:rs];
    }
    
    [rs close];
    return patientRez;
}


#pragma mark -
#pragma mark Private

-(BOOL) patientExists:(Patient *)patient
{
    BOOL rez = NO;
    NSString *selectQuery = @""
    "SELECT * FROM patient WHERE guid = ?";
    FMResultSet *rs = [self.db executeQuery:selectQuery, patient.guid];
    if([rs next])
    {
        rez = YES;
    }
    
    [rs close];
    return rez;
}

-(BOOL) insertPatient:(Patient *)patient
{
    NSString *insertQuery = @""
    "INSERT INTO patient ("
    " guid, "
    " first_name, "
    " middle_name, "
    " last_name, "
    " date_of_birth, "
    " race, "
    " gender, "
    " phone, "
    " email, "
    " insurance "
    " ) VALUES (?,?,?,?,?,?,?,?,?,?) ";
    
    BOOL rez = [self.db executeUpdate:insertQuery,
                patient.guid,
                patient.firstName,
                patient.middleName,
                patient.lastName,
                patient.dateOfBirth, //???
                patient.race,
                patient.gender,
                patient.phone,
                patient.email,
                patient.insurance];
    
    return  rez;
}


-(BOOL) updatePatient:(Patient *)patient
{
    NSString *updateQuery = @""
    "UPDATE patient SET"
    " first_name = ?, "
    " middle_name = ?, "
    " last_name = ?, "
    " date_of_birth = ?, "
    " race = ?, "
    " gender = ?, "
    " phone = ?, "
    " email = ?, "
    " insurance = ? "
    " WHERE guid = ? ";
    
    BOOL rez = [self.db executeUpdate:updateQuery, 
                patient.firstName,
                patient.middleName,
                patient.lastName,
                patient.dateOfBirth,
                patient.race,
                patient.gender,
                patient.phone,
                patient.email,
                patient.insurance,
                patient.guid];
    
    return rez;
}
    
-(NSString*) generateGuidForPatient
{
    return [[NSProcessInfo processInfo] globallyUniqueString];
}

@end

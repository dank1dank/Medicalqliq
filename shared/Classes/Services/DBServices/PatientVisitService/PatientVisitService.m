//
//  ObservationService.m
//  qliq
//
//  Created by Paul Bar on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PatientVisitService.h"
#import "PatientVisit.h"
#import "Patient.h"
#import "Facility.h"
#import "Floor.h"
#import "QliqUser.h"

@interface PatientVisitService()

-(BOOL) insertPatientVisit:(PatientVisit*) patientVisit;
-(BOOL) updatePatientVisit:(PatientVisit*) patientVisit;
-(BOOL) patientVisitExists:(PatientVisit*) patientVisit;

@end

@implementation PatientVisitService

-(Patient*) getPatientForVisit:(PatientVisit*)patientVisit
{
	NSString *selectQuery = @""
    "SELECT * FROM patient WHERE guid = ?";
    FMResultSet *rs = [self.db executeQuery:selectQuery, patientVisit.patientGuid];
    Patient *rez = nil;
    if([rs next])
    {
        rez = [Patient patientWithResultSet:rs];
    }
    [rs close];
    return rez;
}

-(BOOL) savePatientVisit:(PatientVisit *)patientVisit
{
    
    BOOL rez = NO;
    
    if([self patientVisitExists:patientVisit])
    {
        [self updatePatientVisit:patientVisit];
    }
    else
    {
        [self insertPatientVisit:patientVisit];
    }
    
    return rez;
}

-(NSArray*)getPatientVisits
{
    NSMutableArray *mutableRez = [[NSMutableArray alloc] init];
    
    NSString *selectQuery = @""
    "SELECT * FROM patient_visit";
    
    FMResultSet *rs = [self.db executeQuery:selectQuery];
    
    while ([rs next])
    {
        [mutableRez addObject:[PatientVisit patientVisitWithResultSet:rs]];
    }
    
    NSArray *rez = [NSArray arrayWithArray:mutableRez];
    [mutableRez release];
    return rez;
}
-(NSArray*) getPatientVisitsForDos:(NSDate *)dateOfService
{
    NSMutableArray *mutableRez = [[NSMutableArray alloc] init];
	NSNumber *unixTime = [NSNumber numberWithInt:[dateOfService timeIntervalSince1970]];

    NSString *selectQuery = @""
    "SELECT * FROM patient_visit WHERE ? BETWEEN admit_date AND (CASE WHEN discharge_date > 0 THEN discharge_date ELSE strftime('%s','now') END) ";
    
    FMResultSet *rs = [self.db executeQuery:selectQuery,unixTime];
    
    while ([rs next])
    {
        [mutableRez addObject:[PatientVisit patientVisitWithResultSet:rs]];
    }
    
    NSArray *rez = [NSArray arrayWithArray:mutableRez];
    [mutableRez release];
    return rez;
}

-(NSArray*) getPatientVisitsForDos:(NSDate *)dateOfService forCareteamWithId:(NSNumber *)careteamId onFloor:(Floor *) floor
{
    NSMutableArray *mutableRez = [[NSMutableArray alloc] init];
	NSNumber *unixTime = [NSNumber numberWithInt:[dateOfService timeIntervalSince1970]];

    NSString *selectQuery = @""
    "SELECT * FROM patient_visit WHERE careteam_id = ? AND facility_npi = ? AND floor_id = ? "
	"AND ? BETWEEN admit_date AND (CASE WHEN discharge_date > 0 THEN discharge_date ELSE strftime('%s','now') END) ";
    
    FMResultSet *rs = [self.db executeQuery:selectQuery,careteamId,floor.facilityNpi,floor.floorId,unixTime];
    
    while ([rs next])
    {
        [mutableRez addObject:[PatientVisit patientVisitWithResultSet:rs]];
    }
    
    NSArray *rez = [NSArray arrayWithArray:mutableRez];
    [mutableRez release];
    return rez;
}

-(NSArray*) getPatientVisitsForDos:(NSDate *)dateOfService forProvider:(QliqUser *) provider
{
    NSMutableArray *mutableRez = [[NSMutableArray alloc] init];
	NSNumber *unixTime = [NSNumber numberWithInt:[dateOfService timeIntervalSince1970]];

    NSString *selectQuery = @""
    "SELECT * FROM patient_visit WHERE careteam_id in (SELECT id from careteam WHERE user_id=?) "
	"AND ? BETWEEN admit_date AND (CASE WHEN discharge_date > 0 THEN discharge_date ELSE strftime('%s','now') END) ";
    
    FMResultSet *rs = [self.db executeQuery:selectQuery,provider.email,unixTime];
    
    while ([rs next])
    {
        [mutableRez addObject:[PatientVisit patientVisitWithResultSet:rs]];
    }
    
    NSArray *rez = [NSArray arrayWithArray:mutableRez];
    [mutableRez release];
    return rez;
}

-(NSArray*) getPatientVisitsForDos:(NSDate *)dateOfService forCareteamWithId:(NSNumber *)careteamId
{
    NSMutableArray *mutableRez = [[NSMutableArray alloc] init];
    NSNumber *unixTime = [NSNumber numberWithInt:[dateOfService timeIntervalSince1970]];
    NSString *selectQuery = @""
    "SELECT * FROM patient_visit WHERE careteam_id = ? "
	"AND ? BETWEEN admit_date AND (CASE WHEN discharge_date > 0 THEN discharge_date ELSE strftime('%s','now') END) ";
    
    FMResultSet *rs = [self.db executeQuery:selectQuery,careteamId,unixTime];
    
    while ([rs next])
    {
        [mutableRez addObject:[PatientVisit patientVisitWithResultSet:rs]];
    }
    
    NSArray *rez = [NSArray arrayWithArray:mutableRez];
    [mutableRez release];
    return rez;
}

-(Facility*) getFacilityOfVisit:(PatientVisit *)patientVisit
{
    NSString *selectQuery = @""
    "SELECT * FROM facility WHERE npi = ?";
    
    FMResultSet *rs = [self.db executeQuery:selectQuery, patientVisit.visitId];
    Facility *rez = nil;
    if ([rs next])
    {
        rez = [Facility facilityWithResultSet:rs];
    }
    [rs close];
    
    return rez;
}

-(QliqUser*) getAdmitPhysicianForPatientVisit:(PatientVisit *)patientVisit
{
    NSString *selectQuery = @""
    "SELECT * FROM qliq_user WHERE email IN "
    "(SELECT user_id FROM careteam WHERE id = ? AND admit = 1)";
    
    FMResultSet *rs = [self.db executeQuery:selectQuery, patientVisit.careteamId];
    QliqUser *rez = nil;
    if ([rs next])
    {
        rez = [QliqUser userWithResultSet:rs];
    }
    [rs close];
    
    return rez;
}

-(QliqUser*) getActivePhysicianForPatientVisit:(PatientVisit *)patientVisit
{
    NSString *selectQuery = @""
    "SELECT * FROM qliq_user WHERE email IN "
    "(SELECT user_id FROM careteam WHERE id = ? AND active = 1)";
    
    FMResultSet *rs = [self.db executeQuery:selectQuery, patientVisit.careteamId];
    QliqUser *rez = nil;
    if ([rs next])
    {
        rez = [QliqUser userWithResultSet:rs];
    }
    [rs close];
    
    return rez;
}

#pragma mark -
#pragma mark Private

-(BOOL) patientVisitExists:(PatientVisit *)patientVisit
{
    NSString *selectQuery = @""
    "SELECT * FROM patient_visit WHERE id = ?";

    FMResultSet *rs = [self.db executeQuery:selectQuery, patientVisit.visitId];
    
    BOOL rez = NO;
    if([rs next])
    {
        rez = YES;
    }
    
    [rs close];
    
    return rez;
}

-(BOOL) insertPatientVisit:(PatientVisit *)patientVisit
{
    NSString *insertQuery = @""
    "INSERT INTO patient_visit ("
    " id, "
    " careteam_id, "
    " type, "
    " patient_guid, "
    " facility_npi, "
    " consult, "
    " mrn, "
    " floor_id, "
    " room, "
    " admit_date, "
    " discharge_date, "
    " appt_start_date, "
    " duration, "
    " reminder, "
    " reason, "
    " active, "
    " uuid, "
    " rev, "
    " author, "
    " seq, "
    " is_rev_dirty "
    ") VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)";
    
    BOOL rez = NO;
    rez = [self.db executeUpdate:insertQuery,
           patientVisit.visitId,
           patientVisit.careteamId,
           patientVisit.type,
           patientVisit.patientGuid,
           patientVisit.facilityNpi,
           patientVisit.consult,
           patientVisit.mrn,
		   patientVisit.floorId,
           patientVisit.room,
           [NSNumber numberWithInt:[patientVisit.admitDate timeIntervalSince1970]],
           [NSNumber numberWithInt:[patientVisit.dischargeDate timeIntervalSince1970]],
           [NSNumber numberWithInt:[patientVisit.apptStartDate timeIntervalSince1970]],
           patientVisit.duration,
           patientVisit.reminder,
           patientVisit.reason,
           [NSNumber numberWithInt:patientVisit.active],
           patientVisit.uuid,
           patientVisit.rev,
           patientVisit.autor,
           patientVisit.seq,
           [NSNumber numberWithInt:patientVisit.isRevDirty]];
    
    if(rez)
    {
        patientVisit.visitId = [NSNumber numberWithInt: [self.db lastInsertRowId]];
    }
    
    return rez;
}

-(BOOL) updatePatientVisit:(PatientVisit *)patientVisit
{
    NSString *updateQuery = @""
    "UPDATE patient_visit SET"
    " careteam_id = ?, "
    " type = ?, "
    " patient_guid = ?, "
    " facility_npi = ?, "
    " consult = ?, "
    " mrn = ?, "
    " floor_id = ?, "
    " room = ?, "
    " admit_date = ?, "
    " discharge_date = ?, "
    " appt_start_date = ?, "
    " duration = ?, "
    " reminder = ?, "
    " reason = ?, "
    " active = ?, "
    " uuid = ?, "
    " rev = ?, "
    " author = ?, "
    " seq = ?, "
    " is_rev_dirty = ? "
    " WHERE id = ?";
    
    BOOL rez = NO;
    rez = [self.db executeUpdate:updateQuery,
           patientVisit.careteamId,
           patientVisit.type,
           patientVisit.patientGuid,
           patientVisit.facilityNpi,
           patientVisit.consult,
           patientVisit.mrn,
		   patientVisit.floorId,
           patientVisit.room,
           [NSNumber numberWithInt:[patientVisit.admitDate timeIntervalSince1970]],
           [NSNumber numberWithInt:[patientVisit.dischargeDate timeIntervalSince1970]],
           [NSNumber numberWithInt:[patientVisit.apptStartDate timeIntervalSince1970]],
           patientVisit.duration,
           patientVisit.reminder,
           patientVisit.reason,
           [NSNumber numberWithInt:patientVisit.active],
           patientVisit.uuid,
           patientVisit.rev,
           patientVisit.autor,
           patientVisit.seq,
           [NSNumber numberWithInt:patientVisit.isRevDirty],
           patientVisit.visitId];
    
    return rez;
}

@end

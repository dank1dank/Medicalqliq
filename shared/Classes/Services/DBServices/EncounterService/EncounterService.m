//
//  EncounterService.m
//  qliq
//
//  Created by Paul Bar on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EncounterService.h"
#import "Encounter.h"
#import "PatientVisit.h"

@interface EncounterService()

-(BOOL) encounterExists:(Encounter*)encounter;
-(BOOL) insertEncounter:(Encounter*)encounter;
-(BOOL) updateEncounter:(Encounter*)encounter;

@end

@implementation EncounterService

-(BOOL) saveEncounter:(Encounter *)encounter
{
    BOOL rez = NO;
    
    if([self encounterExists:encounter])
    {
        rez = [self updateEncounter:encounter];
    }
    else
    {
        rez = [self insertEncounter:encounter];
    }
    return rez;
}

-(NSArray*) getEncountersForPatientVisit:(PatientVisit *)patientVisit
{
    NSMutableArray *mutableRez = [[NSMutableArray alloc] init];
    
    NSString *selectQuery = @""
    "SELECT * FROM encounter WHERE patient_visit_id = ?";
    
    FMResultSet *rs = [self.db executeQuery:selectQuery, patientVisit.visitId];
    
    while ([rs next])
    {
        [mutableRez addObject:[Encounter encounterWithResultSet:rs]];
    }
    [rs close];
    
    NSArray *rez = [NSArray arrayWithArray:mutableRez];
    [mutableRez release];
    return rez;
}

-(Encounter*) getEncounterOfPatientVisit:(PatientVisit *)patientVisit forDate:(NSDate *)date
{
    NSString *selectQuery = @""
    "SELECT * FROM encounter WHERE patient_visit_id = ? AND date_of_service = ?";
    NSNumber *unixTime = [NSNumber numberWithInt:[date timeIntervalSince1970]];
    FMResultSet *rs = [self.db executeQuery:selectQuery, patientVisit.visitId, unixTime];
    Encounter *encounter = nil;
    
    if([rs next])
    {
        encounter = [Encounter encounterWithResultSet:rs];
    }
    return encounter;
}


#pragma mark -
#pragma mark Private

-(BOOL) encounterExists:(Encounter *)encounter
{
    BOOL rez = NO;
    
    NSString *selectQuery = @""
    "SELECT * FROM encounter WHERE id = ?";
    
    FMResultSet *resultSet = [self.db executeQuery:selectQuery, encounter.encounterId];
    
    if([resultSet next])
    {
        rez = YES;
    }
    [resultSet close];
    
    return rez;
}

-(BOOL) insertEncounter:(Encounter *)encounter
{
    NSString *insertQuery = @""
    "INSERT INTO encounter ("
    " id, "
    " patient_visit_id, "
    " date_of_service, "
    " status, "
    " data "
    ") VALUES (?,?,?,?,?)";
    
    BOOL rez = [self.db executeUpdate:insertQuery,
                encounter.encounterId,
                encounter.patietnVisitId,
                [NSNumber numberWithInt:[encounter.dateOfService timeIntervalSince1970]],
                encounter.status,
                encounter.data];
    
    if(rez)
    {
        encounter.encounterId = [NSNumber numberWithInt:[self.db lastInsertRowId]];
    }
    
    return rez;
}

-(BOOL) updateEncounter:(Encounter *)encounter
{
    NSString *updateQuery = @""
    "UPDATE encouner SET"
    " patient_visit_id = ?, "
    " date_of_service = ?, "
    " status = ?, "
    " data = ? "
    " WHERE id = ?";
    
    BOOL rez = [self.db executeUpdate:updateQuery,
                encounter.patietnVisitId,
                [NSNumber numberWithInt:[encounter.dateOfService timeIntervalSince1970]],
                encounter.status,
                encounter.data,
                encounter.encounterId];
    
    return rez;
}

@end

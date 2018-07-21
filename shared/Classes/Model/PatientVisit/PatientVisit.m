//
//  Observation.m
//  qliq
//
//  Created by Paul Bar on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PatientVisit.h"
#import "NSObject+AutoDescription.h"
#import "FMResultSet.h"

@implementation PatientVisit

@synthesize visitId;
@synthesize careteamId;
@synthesize type;
@synthesize patientGuid;
@synthesize facilityNpi;
@synthesize consult;
@synthesize mrn;
@synthesize floorId;
@synthesize room;
@synthesize admitDate;
@synthesize dischargeDate;
@synthesize apptStartDate;
@synthesize duration;
@synthesize reminder;
@synthesize reason;
@synthesize active;
@synthesize uuid;
@synthesize rev;
@synthesize autor;
@synthesize seq;
@synthesize isRevDirty;

-(void) dealloc
{
    [self.visitId release];
    [self.careteamId release];
    [self.type release];
    [self.patientGuid release];
    [self.facilityNpi release];
    [self.consult release];
    [self.mrn release];
    [self.floorId release];
    [self.room release];
    [self.admitDate release];
    [self.dischargeDate release];
    [self.apptStartDate release];
    [self.duration release];
    [self.reminder release];
    [self.reason release];
    [self.uuid release];
    [self.rev release];
    [self.autor release];
    [self.seq release];
    [super dealloc];
}

-(NSString*) description
{
    return [self autoDescription];
}

+(PatientVisit*) patientVisitWithResultSet:(FMResultSet *)resultSet
{
    PatientVisit *patientVisit = [[PatientVisit alloc] init];
    
    patientVisit.visitId = [NSNumber numberWithInt:[resultSet intForColumn:@"id"]];
    patientVisit.careteamId = [NSNumber numberWithInt:[resultSet intForColumn:@"careteam_id"]];
    patientVisit.type = [resultSet stringForColumn:@"type"];
    patientVisit.patientGuid = [resultSet stringForColumn:@"patient_guid"];
    patientVisit.facilityNpi = [NSNumber numberWithInt:[resultSet intForColumn:@"facility_npi"]];
    patientVisit.consult = [NSNumber numberWithInt:[resultSet intForColumn:@"consult"]];
    patientVisit.mrn = [resultSet stringForColumn:@"mrn"];
    patientVisit.floorId = [NSNumber numberWithInt:[resultSet intForColumn:@"floor_id"]];
    patientVisit.room = [resultSet stringForColumn:@"room"];
    patientVisit.admitDate = [NSDate dateWithTimeIntervalSince1970:[resultSet intForColumn:@"admit_date"]];
    patientVisit.dischargeDate = [NSDate dateWithTimeIntervalSince1970:[resultSet intForColumn:@"discharge_date"]];
    patientVisit.apptStartDate = [NSDate dateWithTimeIntervalSince1970:[resultSet intForColumn:@"appt_start_date"]];
    patientVisit.duration = [NSNumber numberWithInt:[resultSet intForColumn:@"duration"]];
    patientVisit.reminder = [NSNumber numberWithInt:[resultSet intForColumn:@"reminder"]];
    patientVisit.reason = [resultSet stringForColumn:@"reason"];
    patientVisit.active = [[NSNumber numberWithInt:[resultSet intForColumn:@"active"]] boolValue];
    patientVisit.uuid = [resultSet stringForColumn:@"uuid"];
    patientVisit.rev = [resultSet stringForColumn:@"rev"];
    patientVisit.autor = [resultSet stringForColumn:@"author"];
    patientVisit.seq = [NSNumber numberWithInt:[resultSet intForColumn:@"seq"]];
    patientVisit.isRevDirty = [[NSNumber numberWithInt:[resultSet intForColumn:@"is_rev_dirty"]] boolValue];
    
    return [patientVisit autorelease];
}

@end

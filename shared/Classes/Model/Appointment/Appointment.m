//
//  Appointment.m
//  CCiPhoneApp
//
//  Created by Ravi Ada on 4/12/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import "Appointment.h"
#import "DBPersist.h"
#import "AppointmentSchema.h"
#import "Helper.h"

@implementation Appointment
@synthesize isDirty,isDetailViewHydrated;
@synthesize appointmentId,patientId,patientName,physicianNpi,physicianInitials,facilityNpi,facilityName,facilityType,apptDate,apptStart,apptEnd;
@synthesize reason,room,gender,race,dateOfBirth,location,reminder,mrn,referringPhysicianNpi,referringPhysicianName,complete;


+ (NSMutableArray *) getAppointmentsToDisplay:(NSTimeInterval)apptDate :(double) physicianNpi
{
    return [[DBPersist instance] getAppointmentsToDisplay:apptDate :physicianNpi];
}

+ (NSMutableArray *) getAppointmentsForFacility:(NSTimeInterval)apptDate:(double) facilityNpi:(double) physicianNpi
{
    return [[DBPersist instance] getAppointmentsForFacility:apptDate:facilityNpi:physicianNpi];
}
+ (NSInteger) addAppointment:(Appointment *)appointment
{
    return [[DBPersist instance] addAppointment:appointment];
}
+ (BOOL) markAppointmentComplete:(Appointment *)appointment
{
    return [[DBPersist instance] markAppointmentComplete:appointment];
}

+ (NSInteger) getAppointmentId:(Appointment *)appointment
{
	return [[DBPersist instance] getAppointmentId:appointment];
}

+ (NSMutableArray *) getAppointmentObj:(NSInteger) apptId;
{
	return [[DBPersist instance] getAppointmentObj:apptId];
}

+ (Appointment *) appointmentFromDict:(NSDictionary *)dict
{
    Appointment *a = [[[Appointment alloc] initWithPrimaryKey:0] autorelease];
	NSString *strDate = [dict objectForKey:APPOINTMENT_DATE_TIME];
    NSTimeInterval dt = [Helper strDateTimeISO8601ToInterval:strDate];    
    a.apptDate = dt;
    a.apptStart = dt;
    
    NSNumber *durationNum = [dict objectForKey:APPOINTMENT_DURATION];
    if (durationNum) {
        int duration = [durationNum intValue];
        a.apptEnd = dt + duration;
    }
    
    NSDictionary *tmpDict = [dict objectForKey:APPOINTMENT_PATIENT];
    if (tmpDict) {
        Patient_old *patient = [Patient_old patientFromDict:tmpDict];
        NSInteger patientId = [Patient_old getPatientId:patient];
        a.patientId = patientId;
        a.patientName = [NSString stringWithFormat:@"%@, %@ %@", patient.lastName, patient.firstName, patient.middleName];
        a.gender = patient.gender;
        a.race = patient.race;
        a.dateOfBirth = patient.dateOfBirth;
    }

    tmpDict = [dict objectForKey:APPOINTMENT_PROVIDER];
    if (tmpDict) {
        Physician *physician = [Physician physicianFromDict:tmpDict];
        if ([Physician getPhysicianWithNPI:physician.physicianNpi] == nil)
            [Physician addPhysician:physician];
        
        a.physicianNpi = physician.physicianNpi;
    }

    tmpDict = [dict objectForKey:APPOINTMENT_FACILITY];
    if (tmpDict) {
        Facility_old *facility = [Facility_old facilityFromDict:tmpDict];
        a.facilityNpi = facility.facilityNpi;
        a.facilityName = facility.name;
    }
    
    a.room = [dict objectForKey:APPOINTMENT_ROOM];
    return a;
}

- (id) initWithPrimaryKey:(NSInteger) pk {
    
    [super init];
    appointmentId = pk;
    isDetailViewHydrated = NO;
    
    return self;
}

- (void) dealloc {
	[patientName release];
	[physicianInitials release];
    [facilityName release];
	[facilityType release];
    [mrn release];
    [room release];
    [gender release];
    [race release];
    [reason release];
    [location release];
    [mrn release];
    [referringPhysicianName release];
    [strApptStart release];
    [strApptEnd release];
	[super dealloc];
}


@end

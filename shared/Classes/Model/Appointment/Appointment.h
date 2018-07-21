//
//  Appointment.h
//  CCiPhoneApp
//
//  Created by Ravi Ada on 4/12/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Metadata.h"
#import "Physician.h"
#import "Facility_old.h"
#import "Patient_old.h"

@interface Appointment : NSObject {
   /*
    
    CREATE TABLE appointment (
    id            integer PRIMARY KEY AUTOINCREMENT,
    patient_id    integer,
    physician_npi  integer,
    facility_npi	integer,
    appt_date		date,
    appt_start    time,
    appt_end      time,
    reason        text,
    room          varchar(50),
    location      varchar(50),
    reminder      integer,
    mrn           varchar(50), 
    referring_physician_npi INTEGER,
    FOREIGN KEY (referring_physician_npi)
    REFERENCES referring_physician(id),
    FOREIGN KEY (patient_id)
    REFERENCES patient(id),
    FOREIGN KEY (facility_npi)
    REFERENCES facility(id),
    FOREIGN KEY (physician_npi)
    REFERENCES physician(id)
    );
    */
    NSInteger appointmentId;
    NSInteger patientId;
    NSString  *patientName;
    double physicianNpi;
    NSString  *physicianInitials;
    double facilityNpi;
    NSString *facilityName;
    NSString *facilityType;
    NSTimeInterval apptDate;
    NSTimeInterval apptStart;
    NSTimeInterval apptEnd;
    NSString *strApptStart;
    NSString *strApptEnd;
    NSString *reason;
    NSString *room;
    NSString *gender;
    NSString *race;
    NSTimeInterval dateOfBirth;
    NSString *location;
    NSInteger reminder;
    NSString *mrn;
    double referringPhysicianNpi;
    NSString *referringPhysicianName;
    BOOL complete;
    
    Patient_old *patient;
    Physician *physician;
    Facility_old *facility;
    Metadata *metadata;
    //Nurse *nurse;
    
    
	//Intrnal variables to keep track of the state of the object.
	BOOL isDirty;
	BOOL isDetailViewHydrated;
    
}
@property (nonatomic, readonly) NSInteger appointmentId;
@property (nonatomic, readwrite) NSInteger patientId;
@property (nonatomic, retain) NSString  *patientName;
@property (nonatomic, readwrite) double physicianNpi;
@property (nonatomic, retain) NSString  *physicianInitials;
@property (nonatomic, readwrite) double facilityNpi;
@property (nonatomic, retain) NSString *facilityName;
@property (nonatomic, retain) NSString *facilityType;
@property (nonatomic, readwrite) NSTimeInterval apptDate;
@property (nonatomic, readwrite) NSTimeInterval apptStart;
@property (nonatomic, readwrite) NSTimeInterval apptEnd;
@property (nonatomic, retain) NSString *reason;
@property (nonatomic, retain) NSString *room;
@property (nonatomic, retain) NSString *gender;
@property (nonatomic, retain) NSString *race;
@property (nonatomic, readwrite) NSTimeInterval dateOfBirth;
@property (nonatomic, retain) NSString *location;
@property (nonatomic, readwrite) NSInteger reminder;
@property (nonatomic, retain) NSString *mrn;
@property (nonatomic, readwrite) double referringPhysicianNpi;
@property (nonatomic, retain) NSString *referringPhysicianName;
@property (nonatomic, readwrite) BOOL complete;


@property (nonatomic, readwrite) BOOL isDirty;
@property (nonatomic, readwrite) BOOL isDetailViewHydrated;

//Static methods.
+ (NSMutableArray *) getAppointmentsToDisplay:(NSTimeInterval)apptDate :(double) physicianNpi;
+ (NSMutableArray *) getAppointmentsForFacility:(NSTimeInterval)apptDate:(double) facilityNpi :(double) physicianNpi;
+ (NSInteger) addAppointment:(Appointment *)appointment;
+ (BOOL) markAppointmentComplete:(Appointment *)appointment;
+ (NSInteger) getAppointmentId:(Appointment *)appointment;
+ (NSMutableArray *) getAppointmentObj:(NSInteger) apptId;
+ (Appointment *) appointmentFromDict:(NSDictionary *)dict;

//Instance methods.
- (id) initWithPrimaryKey:(NSInteger)pk;
// Serialization for JSONKit
//- (NSMutableDictionary *) toDict;

@end

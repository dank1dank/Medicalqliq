//
//  Census.h
//  CCiPhoneApp
//
//  Created by Ravi Ada on 4/12/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Encounter_old.h"
#import "Metadata.h"
#import "Physician.h"
#import "Facility_old.h"
#import "Patient_old.h"

typedef enum {
    CodesExistPriorToAdmitDate = 0,
    CodesExistBeyondDischargeDate = 1,
    NoCodesPriorBeyondDischargeDate = 2
} CensusDischargeStatus;

typedef enum {
    NonConsult = 0,
    Consult = 1
} CensusType;


@interface AllCharges : NSObject {
	NSInteger censusId;
	NSTimeInterval dateOfService;
	EncounterStatus encounterStatus;
	NSString *strCptCodes;
	NSString *strIcdCodes;
}
@property (nonatomic, readwrite) NSInteger censusId;
@property (nonatomic, readwrite) NSTimeInterval dateOfService;
@property (nonatomic, readwrite) EncounterStatus encounterStatus;
@property (nonatomic, retain) NSString *strCptCodes;
@property (nonatomic, retain) NSString *strIcdCodes;
@end

@interface Census_old : NSObject {
    /*
     CREATE TABLE census (
     id		integer  PRIMARY KEY AUTOINCREMENT,
     patient_id              integer,
     physician_npi  integer,
     facility_npi			  integer,
     mrn                     varchar(50),
     room                    integer,
     admit_date              date,
     discharge_date          date,
     referring_physician_npi  integer,
     active				  integer,
     FOREIGN KEY (patient_id)
     REFERENCES patient(id), 
     FOREIGN KEY (physician_npi)
     REFERENCES physician(id), 
     FOREIGN KEY (facility_npi)
     REFERENCES facility(id),
     FOREIGN KEY (referring_physician_npi)
     REFERENCES referring_physician(id)
     );
     */
    NSInteger censusId;
    NSInteger patientId;
    NSString *patientLastName;
    NSString *patientFirstName;
    NSString *patientMiddleName;
    NSString *patientName;
    double physicianNpi;
	double activePhysicianNpi;
    NSString *physicianInitials;
    NSString *physicianSpecialty;
    double facilityNpi;
    NSString *facilityName;
	CensusType censusType;
    NSString *mrn;
    NSString *room;
    NSString *gender;
    NSString *race;
    NSString *insurance;
    NSTimeInterval dateOfBirth;
    NSTimeInterval dateOfService;
	NSTimeInterval selectedDos;
    NSTimeInterval admitDate;
    NSTimeInterval dischargeDate;
    double referringPhysicianNpi;
    NSString *referringPhysicianName;
    BOOL active;
    NSTimeInterval lastUpdated;
    NSString *lastUpdatedUser;
    
    Patient_old *patient;
    Physician *admittingPhysician;
    Physician *activePhysician;
    Physician *referringPhysician;
    Facility_old *facility;
    Metadata *metadata;
    
	//Intrnal variables to keep track of the state of the object.
	BOOL isDirty;
	BOOL isDetailViewHydrated;    
}

@property (nonatomic, readwrite) NSInteger censusId;
@property (nonatomic, readwrite) NSInteger patientId;
@property (nonatomic, retain) NSString *patientLastName;
@property (nonatomic, retain) NSString *patientFirstName;
@property (nonatomic, retain) NSString *patientMiddleName;
@property (nonatomic, retain) NSString *patientName;
@property (nonatomic, readwrite) double physicianNpi;
@property (nonatomic, readwrite) double activePhysicianNpi;
@property (nonatomic, retain) NSString *physicianInitials;
@property (nonatomic, retain) NSString *physicianSpecialty;
@property (nonatomic, readwrite) double facilityNpi;
@property (nonatomic, retain) NSString *facilityName;
@property (nonatomic, readwrite) CensusType censusType;
@property (nonatomic, retain) NSString *mrn;
@property (nonatomic, retain) NSString *room;
@property (nonatomic, retain) NSString *gender;
@property (nonatomic, retain) NSString *race;
@property (nonatomic, retain) NSString *insurance;
@property (nonatomic, readwrite) NSTimeInterval dateOfBirth;
@property (nonatomic, readwrite) NSTimeInterval dateOfService;
@property (nonatomic, readwrite) NSTimeInterval selectedDos;
@property (nonatomic, readwrite) NSTimeInterval admitDate;
@property (nonatomic, readwrite) NSTimeInterval dischargeDate;
@property (nonatomic, readwrite) double referringPhysicianNpi;
@property (nonatomic, retain) NSString *referringPhysicianName;
@property (nonatomic, readwrite) BOOL active;
@property (nonatomic, retain) Patient_old *patient;
@property (nonatomic, retain) Physician *admittingPhysician;
@property (nonatomic, retain) Physician *activePhysician;
@property (nonatomic, retain) Physician *referringPhysician;
@property (nonatomic, retain) Facility_old *facility;
@property (nonatomic, retain) Metadata *metadata;
@property (nonatomic, readwrite) NSTimeInterval lastUpdated;
@property (nonatomic, retain) NSString *lastUpdatedUser;
@property (nonatomic, readwrite) BOOL isDirty;
@property (nonatomic, readwrite) BOOL isDetailViewHydrated;

//Static methods.
+ (NSMutableArray *) getCensusToDisplay:(NSString *)dateOfService andPhysicianId:(double) physicianNpi andFacilityId:(double) facilityNpi andBtnPressed:(NSString*)btnLabel  andSortBy:(NSString*) sortOrder;
+ (NSInteger) addPatientToCensus:(Census_old *)census;
+ (BOOL) updateCensus:(Census_old *) census;
+ (BOOL) dischargePatient:(Census_old *)census;
+ (Census_old *) getCensusObject:(NSInteger) censusId;
+ (NSInteger) getPendingCountForFacility:(NSMutableArray*) censusArray;
+ (NSInteger) getPendingCount:(NSInteger)phyId andFacilityId:(NSInteger)facId andDos:(NSTimeInterval) dos;
+ (NSInteger) getCensusId:(Census_old *) census;
+ (NSInteger) getCensusIdOrInsert:(Census_old *) census;
+ (NSMutableArray *) getActiveCensusObjects:(double) physicianNpi andBtnPressed:(NSString *)btnPressed;
+ (void) createEncounter:(Census_old*) censusObj;
+ (BOOL) hasPriorChargesToAdmitDate:(Census_old *) censusObj andNewAdmitDate:(NSTimeInterval)admitDateInSecs;
+ (BOOL) hasLaterChargesToDischargeDate:(Census_old *) censusObj andNewDischargeDate:(NSTimeInterval)dischargeDateInSecs;
+ (id) censusFromDict:(NSDictionary *)dict;

//Instance methods.
- (id) initWithPrimaryKey:(NSInteger)pk;

// Serialization for JSONKit
- (NSMutableDictionary *) toDict;
- (void) addEncountersToDict:(NSMutableDictionary *)dict;

// Set the author for this object.
// If censusId > 0 it will save new metadata in db.
// If metadata is nil it will be created [Metadata createNew].
- (void) setMetadataAuthor:(NSString *)author;
- (BOOL) isValid;

// Sets the census as dirty.
// It will set the metadata.author to current user.
- (void) setRevisionDirty:(BOOL) dirty;
- (BOOL) isRevisionDirty;

- (BOOL) isPatientDirty;
- (BOOL) isCensusPartDirty;

@end

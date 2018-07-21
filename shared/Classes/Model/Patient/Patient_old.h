//
//  Patient.h
//  CCiPhoneApp
//
//  Created by Ravi Ada on 4/12/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Patient_old : NSObject {
    NSInteger patientId;
    NSString *firstName;
    NSString *middleName;
    NSString *lastName;
	NSString *fullName;
    NSTimeInterval dateOfBirth;
    NSString *race;
    NSString *gender;
    NSString *phone;
    NSString *email;
    NSString *insurance;
	NSInteger censusId;
	NSInteger apptId;
    
	//Intrnal variables to keep track of the state of the object.
	BOOL isDirty;
	BOOL isDetailViewHydrated;
    
}
@property (nonatomic, readwrite) NSInteger patientId;
@property (nonatomic, retain) NSString *firstName;
@property (nonatomic, retain) NSString *middleName;
@property (nonatomic, retain) NSString *lastName;
@property (nonatomic, retain) NSString *fullName;
@property (nonatomic, readwrite) NSTimeInterval dateOfBirth;
@property (nonatomic, retain) NSString *race;
@property (nonatomic, retain) NSString *gender;
@property (nonatomic, retain) NSString *phone;
@property (nonatomic, retain) NSString *email;
@property (nonatomic, retain) NSString *insurance;
@property (nonatomic, readwrite) NSInteger censusId;
@property (nonatomic, readwrite) NSInteger apptId;

@property (nonatomic, readwrite) BOOL isDirty;
@property (nonatomic, readwrite) BOOL isDetailViewHydrated;

//Static methods.
+ (Patient_old *) getPatientToDisplay:(NSInteger)patientId;
+ (NSMutableArray *) getAllPatientsToDisplay;
+ (NSInteger) addPatient:(Patient_old *)patient;
+ (NSInteger) getPatientId:(Patient_old*)patient;
+ (BOOL) updatePatient:(Patient_old *)patient;
+ (id) patientFromDict:(NSDictionary *)dict;

//Instance methods.
- (id) initWithPrimaryKey:(NSInteger)pk;
- (NSMutableDictionary *) toDict;
- (BOOL) isValid;


@end

@interface PatientContact : NSObject {
    NSInteger patientContactId;
    NSInteger patientId;
    NSString *name;
	NSString *relation;
    NSString *phone;
    NSString *mobile;
    NSString *email;
    NSString *isPrimary;
}
@property (nonatomic, readwrite) NSInteger patientContactId;
@property (nonatomic, readwrite) NSInteger patientId;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *relation;
@property (nonatomic, retain) NSString *phone;
@property (nonatomic, retain) NSString *mobile;
@property (nonatomic, retain) NSString *email;
@property (nonatomic, retain) NSString *isPrimary;

//Instance methods.
- (id) initWithPrimaryKey:(NSInteger)pk;

@end


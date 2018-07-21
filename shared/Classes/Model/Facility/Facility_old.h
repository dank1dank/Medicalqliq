//
//  Facility.h
//  CCiPhoneApp
//
//  Created by Ravi Ada on 4/12/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *FacilityInfoNotification;

@interface Facility_old : NSObject {
    /*
     CREATE TABLE facility (
     id           integer PRIMARY KEY AUTOINCREMENT,
     facility_type_id integer,
     medicare_id  numeric(15),
     name         char(50),
     address      char(50),
     city         char(50),
     state        char(5),
     zip          char(10),
     county       char(50),
    FOREIGN KEY (facility_type_id)
    REFERENCES facility_type(id)
    );     
     */
    double facilityNpi;
    NSInteger facilityTypeId;
    NSString *medicareId;
    NSString *name;
    NSString *address;
    NSString *city;
    NSString *state;
    NSString *zip;
	NSString *phone;
    NSString *county;
    NSString *facilityType;
    NSString *facilityTypeClassification;
    NSString *facilityTypeSpecialization;
	
    
	NSInteger sectionIndex;
	BOOL isDirty;
	BOOL isDetailViewHydrated;
    
}
@property (nonatomic, readwrite) double facilityNpi;
@property (nonatomic, readwrite) NSInteger facilityTypeId;
@property (nonatomic, retain) NSString *medicareId;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *address;
@property (nonatomic, retain) NSString *city;
@property (nonatomic, retain) NSString *state;
@property (nonatomic, retain) NSString *zip;
@property (nonatomic, retain) NSString *phone;
@property (nonatomic, retain) NSString *county;
@property (nonatomic, retain) NSString *facilityType;
@property (nonatomic, retain) NSString *facilityTypeClassification;
@property (nonatomic, retain) NSString *facilityTypeSpecialization;
@property (nonatomic, readwrite) NSInteger sectionIndex;

@property (nonatomic, readwrite) BOOL isDirty;
@property (nonatomic, readwrite) BOOL isDetailViewHydrated;

//Static methods.
+ (NSMutableArray *) getFacilitiesToDisplay:(NSString *)btnPressed;
+ (NSMutableArray *) getDefaultFacility:(double) physicianNpi;
+ (double) addFacility:(Facility_old *)facility andPhysicianId:(double) physicianNpi;
+ (NSInteger) getFacilityTypeId:(double) facilityNpi;
+ (double) getFacilityId:(Facility_old *) facility;
+ (double) getFacilityIdByNpi:(double) npi;
+ (Facility_old *) getFacility:(double) facilityNpi;
+ (id) facilityFromDict:(NSDictionary *)dict;


//Instance methods.
- (id) initFacilityWithPrimaryKey:(double)pk;
- (NSMutableDictionary *) toDict;
- (BOOL) isValid;

@end

//
//  FacilityType.h
//  CCiPhoneApp
//
//  Created by Ravi Ada on 4/12/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//


@interface FacilityType : NSObject {
    /*
     CREATE TABLE facility_type (
     id           integer PRIMARY KEY AUTOINCREMENT,
     name         char(50)
     );
     */
    NSInteger facilityTypeId;
    NSString *name;
    
	BOOL isDetailViewHydrated;
    
}
@property (nonatomic, readwrite) NSInteger facilityTypeId;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, readwrite) BOOL isDetailViewHydrated;

//Static methods.
+ (NSMutableArray *) getFacilityTypesToDisplay;
+ (NSInteger) getFacilityTypePk:(NSString *) facilityType;


//Instance methods.
- (id) initWithPrimaryKey:(NSInteger)pk;

@end

@interface Room : NSObject {
    NSInteger roomId;
	NSString *room;
    NSInteger floorId;
    NSInteger numberOfBeds;
}
@property (nonatomic, readwrite) NSInteger roomId;
@property (nonatomic, retain) NSString *room;
@property (nonatomic, readwrite) NSInteger floorId;
@property (nonatomic, readwrite) NSInteger numberOfBeds;

//Static methods.
+ (NSMutableArray *) getPatientsInRoom:(NSString *)room;

//Instance methods.
- (id) initWithPrimaryKey:(NSInteger)pk;

@end

@interface Floor_old : NSObject {
    NSInteger floorId;
	NSString *facilityNpi;
    NSString *name;
    
}
@property (nonatomic, readwrite) NSInteger floorId;
@property (nonatomic, retain) NSString *facilityNpi;
@property (nonatomic, retain) NSString *name;

//Static methods.
+ (NSMutableArray *) getFloors:(NSString *)facilityNpi;
+ (NSMutableArray *) getRooms:(NSInteger)floorId;
+ (NSMutableArray *) getPatientsOnFloor:(NSInteger)floorId;

//Instance methods.
- (id) initWithPrimaryKey:(NSInteger)pk;

@end

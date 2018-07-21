//
//  Physician.h
//  CCiPhoneApp
//
//  Created by Ravi Ada on 4/12/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Contact.h"
#import "ContactGroup.h"
#import "FMResultSet.h"

@interface Physician : NSObject
{
    double physicianNpi;
    NSInteger groupId;
	NSString *groupName;
    NSInteger groupFlag;
    NSString *name;
    NSString *initials;
	NSString *specialty;
	NSString *classification;
	NSString *specialization;
    NSString *state;
    NSString *zip;
    NSString *mobile;
    NSString *phone;
    NSString *fax;
    NSString *email;
    NSString *address;
    NSString *city;
    
	//Intrnal variables to keep track of the state of the object.
	BOOL isDirty;
	BOOL isDetailViewHydrated;
    
}
@property (nonatomic, readwrite) double physicianNpi;
@property (nonatomic, readwrite) NSInteger groupId;
@property (nonatomic, retain) NSString *groupName;
@property (nonatomic, readwrite) NSInteger groupFlag;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *initials;
@property (nonatomic, retain) NSString *specialty;
@property (nonatomic, retain) NSString *classification;
@property (nonatomic, retain) NSString *specialization;
@property (nonatomic, retain) NSString *state;
@property (nonatomic, retain) NSString *zip;
@property (nonatomic, retain) NSString *mobile;
@property (nonatomic, retain) NSString *phone;
@property (nonatomic, retain) NSString *fax;
@property (nonatomic, retain) NSString *email;
@property (nonatomic, retain) NSString *address;
@property (nonatomic, retain) NSString *city;

@property (nonatomic, readwrite) BOOL isDirty;
@property (nonatomic, readwrite) BOOL isDetailViewHydrated;

//Static methods.
+ (double) addPhysician:(Physician *)physician;
+ (double) getPhysicianId:(Physician *) physician;
+ (Physician *) getPhysician:(NSString*)emailid;
+ (BOOL) deleteAllCharges;
// Returns the Physician object for the currently logged in user
+ (Physician *) currentPhysician;
+ (NSArray *) getGroupmatesForPhysicianWithNPI:(double)npi;
+ (Physician *) getPhysicianWithNPI:(double)npi;
+ (id) physicianFromDict:(NSDictionary *)dict;
+ (NSArray*) getPhysiciansForGroupWithId: (NSInteger)groupId;

//Instance methods.
- (id) initPhysicianWithPrimaryKey:(double)pk;
- (NSMutableDictionary *) toDict;
- (BOOL) isValid;
- (NSString*) credentials;

@end

//Physician Superbill

@interface PhysicianSuperbill : NSObject {
	
    double physicianNpi;
    NSString *taxonomyCode;
    NSInteger preferred;
	
    
	BOOL isDirty;
	BOOL isDetailViewHydrated;
    
}
@property (nonatomic, readwrite) double physicianNpi;
@property (nonatomic, retain) NSString *taxonomyCode;
@property (nonatomic, readwrite) NSInteger preferred;
@property (nonatomic, readwrite) BOOL isDirty;
@property (nonatomic, readwrite) BOOL isDetailViewHydrated;

//Static methods.
+ (BOOL) assignPhysicianSuperbill:(PhysicianSuperbill *) physicianSuperbill;
+ (NSString *) getTaxonomyCodeForSpecialty:(NSString*)specialty;

//Instance methods.
- (id) initPhysicianSuperbillWithPrimaryKey:(double)pkPhysicianSuperbill;
@end

//Physician Preferences
@interface PhysicianPref : NSObject {
	
    double physicianNpi;
	NSInteger numberOfDaysToBill;
	NSInteger faxToPrimary;
	NSInteger defactoFacilityId;
	NSString *lastUsedPatientSortOrder;
	NSInteger lastOpenedFacilityId;
	NSInteger lastUsedFacilityId;
	NSInteger lastUsedSuperbillId;
	NSString *lastUsedCptCode;
	NSInteger lastSelectedCptGroupIndex;
	NSInteger lastSelectedCptCodeIndex;
	NSInteger lastSelectedModifierIndex;
	
    
	BOOL isDirty;
	BOOL isDetailViewHydrated;
    
}
@property (nonatomic, readwrite) double physicianNpi;
@property (nonatomic, readwrite) NSInteger numberOfDaysToBill;
@property (nonatomic, readwrite) NSInteger faxToPrimary;
@property (nonatomic, readwrite) NSInteger defactoFacilityId;
@property (nonatomic, retain) NSString *lastUsedPatientSortOrder;
@property (nonatomic, readwrite) NSInteger lastOpenedFacilityId;
@property (nonatomic, readwrite) NSInteger lastUsedFacilityId;
@property (nonatomic, readwrite) NSInteger lastUsedSuperbillId;
@property (nonatomic, retain) NSString *lastUsedCptCode;
@property (nonatomic, readwrite) NSInteger lastSelectedCptGroupIndex;
@property (nonatomic, readwrite) NSInteger lastSelectedCptCodeIndex;
@property (nonatomic, readwrite) NSInteger lastSelectedModifierIndex;
@property (nonatomic, readwrite) BOOL isDirty;
@property (nonatomic, readwrite) BOOL isDetailViewHydrated;

//Static methods.
+ (PhysicianPref *) getPhysicianPrefs:(double) physicianNpi;
+ (BOOL) updatePhysicianPrefs:(PhysicianPref*) physicianPrefObj;

//Instance methods.
- (id) initPhysicianPrefWithPrimaryKey:(double) pkPhysicianPref;
@end



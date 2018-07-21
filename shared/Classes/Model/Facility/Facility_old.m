//
//  Facility.m
//  CCiPhoneApp
//
//  Created by Ravi Ada on 4/12/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import "Facility_old.h"
#import "DBPersist.h"
#import "FacilitySchema.h"
#import "DBHelperNurse.h"

NSString *FacilityInfoNotification = @"FacilityInfoNotification";

@implementation Facility_old
@synthesize facilityNpi,facilityTypeId,medicareId,name,address,city,state,zip,phone,county,facilityType,sectionIndex;
@synthesize facilityTypeClassification,facilityTypeSpecialization; 
@synthesize isDirty,isDetailViewHydrated;


+ (NSMutableArray *) getFacilitiesToDisplay:(NSString *)btnPressed 
{
    return [[DBPersist instance] getFacilitiesToDisplay:btnPressed];
}
+ (NSMutableArray *) getDefaultFacility:(double) physicianNpi
{
    return [[DBPersist instance] getDefaultFacility:physicianNpi];
}

+ (double) addFacility:(Facility_old *)facility andPhysicianId:(double) physicianNpi;
{
    return [[DBPersist instance] addFacility:facility andPhysicianId:physicianNpi];
}

+ (NSInteger) getFacilityTypeId:(double) facilityNpi
{
    return [[DBPersist instance] getFacilityTypeId:facilityNpi];
}
+ (double) getFacilityId:(Facility_old *) facility
{
	return [[DBPersist instance] getFacilityId:facility];
}

+ (double) getFacilityIdByNpi:(double) npi
{
	return [[DBPersist instance] getFacilityIdByNpi:npi];
}

+ (Facility_old *) getFacility:(double) facilityNpi
{
	return [[DBPersist instance] getFacility:facilityNpi];
}

+ (id) facilityFromDict:(NSDictionary *)dict
{
	Facility_old *facility = [[[Facility_old alloc] init] autorelease];
    
	facility.name = [dict objectForKey:FACILITY_NAME];
	facility.address = [dict objectForKey:FACILITY_ADDRESS];
	facility.city = [dict objectForKey:FACILITY_CITY];
	facility.state = [dict objectForKey:FACILITY_STATE];
	facility.zip = [dict objectForKey:FACILITY_ZIP];
	facility.phone = [dict objectForKey:FACILITY_PHONE];
	
	NSString *npi = [dict objectForKey:FACILITY_NPI];
	if ([npi length] > 0)
		facility.facilityNpi = [npi doubleValue];	
	
	return facility;
}

- (NSMutableDictionary *) toDict
{
    NSMutableDictionary *dict = [[[NSMutableDictionary alloc] init] autorelease];
    [dict setObject:name forKey:FACILITY_NAME];
    [dict setObject:[NSString stringWithFormat:@"%0.0f", facilityNpi] forKey:FACILITY_NPI];
    
    if (address)
        [dict setObject:address forKey:FACILITY_ADDRESS];
    
    if (city)
        [dict setObject:city forKey:FACILITY_CITY];
    
    if (state)
        [dict setObject:state forKey:FACILITY_STATE];
    
    if (zip)    
        [dict setObject:zip forKey:FACILITY_ZIP];
    
    if (phone)
        [dict setObject:phone forKey:FACILITY_PHONE];

    return dict;
}

- (BOOL) isValid
{
    return ([name length] > 0) && (facilityNpi > 0);
}

- (id) initFacilityWithPrimaryKey:(double) pk {
    
    [super init];
    facilityNpi = pk;
    isDetailViewHydrated = NO;
    
    return self;
}
- (void) dealloc {
 	[medicareId release];
    [name release];
    [address release];
    [city release];
    [state release];
    [zip release];
    [county release];
    [facilityType release];
	[facilityTypeClassification release];
	[facilityTypeSpecialization release];
	[super dealloc];
}
@end


@implementation FacilityType
@synthesize facilityTypeId,name,isDetailViewHydrated;

//Static methods.
+ (NSMutableArray *) getFacilityTypesToDisplay
{
    return [[DBPersist instance] getFacilityTypesToDisplay];
}
+ (NSInteger) getFacilityTypePk:(NSString *) facilityType
{
	return [[DBPersist instance] getFacilityTypePk:facilityType];
}

- (id) initWithPrimaryKey:(NSInteger) pk {
    
    [super init];
    facilityTypeId = pk;
    isDetailViewHydrated = NO;
    
    return self;
}
- (void) dealloc {
 	[name release];
	[super dealloc];
}
@end

@implementation Room
@synthesize roomId,room,floorId,numberOfBeds;


//Static methods.
+ (NSMutableArray *) getPatientsInRoom:(NSString *)room
{
    return [DBHelperNurse getPatientsInRoom:room];
}

- (id) initWithPrimaryKey:(NSInteger) pk {
    
    [super init];
    roomId = pk;
    return self;
}
- (void) dealloc {
    [room release];
	[super dealloc];
}
@end

@implementation Floor_old
@synthesize floorId,name,facilityNpi;

//Static methods.
+ (NSMutableArray *) getFloors:(NSString *)facilityNpi
{
    return [DBHelperNurse getFloors:facilityNpi];
}

+ (NSMutableArray *) getRooms:(NSInteger)floorId
{
    return [DBHelperNurse getRooms:floorId];
}
+ (NSMutableArray *) getPatientsOnFloor:(NSInteger)floorId
{
    return [DBHelperNurse getPatientsOnFloor:floorId];
	
}

- (id) initWithPrimaryKey:(NSInteger) pk {
    
    [super init];
    floorId = pk;
    return self;
}
- (void) dealloc {
 	[name release];
    [facilityNpi release];
	[super dealloc];
}
@end
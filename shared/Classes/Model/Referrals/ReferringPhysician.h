///
//  ReferringPhysician.h
//  CCiPhoneApp
//
//  Created by Ravi Ada on 4/12/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//
#import "Contact.h"
#import "ContactGroup.h"
#import "FMResultSet.h"

@interface ReferringPhysician : NSObject 
{
	double referringPhysicianNpi;
	NSString *name;
    NSString *address;
    NSString *city;
    NSString *state;
    NSString *zip;
    NSString *mobile;
    NSString *phone;
    NSString *fax;
    NSString *email;
	NSString *specialty;
	NSString *classification;
	NSString *specialization;
	
	BOOL isDirty;
	BOOL isDetailViewHydrated;
    
}
@property (nonatomic, readwrite) double referringPhysicianNpi;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *address;
@property (nonatomic, retain) NSString *state;
@property (nonatomic, retain) NSString *city;
@property (nonatomic, retain) NSString *zip;
@property (nonatomic, retain) NSString *mobile;
@property (nonatomic, retain) NSString *phone;
@property (nonatomic, retain) NSString *fax;
@property (nonatomic, retain) NSString *email;
@property (nonatomic, retain) NSString *specialty;
@property (nonatomic, retain) NSString *classification;
@property (nonatomic, retain) NSString *specialization;


@property (nonatomic, readwrite) BOOL isDirty;
@property (nonatomic, readwrite) BOOL isDetailViewHydrated;

//Static methods.
+ (NSMutableArray *) getReferralPhysiciansToDisplay;
+ (double) addReferringPhysician: (ReferringPhysician *) referringPhysician;
+ (double) getReferringPhysicianId:(ReferringPhysician *) referringPhysician;
+ (ReferringPhysician *) getReferringPhysician:(double) referringPhysicianNpi;
+ (id) referringPhysicianFromDict:(NSDictionary *)dict;

//Instance methods.
- (id) initReferringPhysicianWithPrimaryKey:(double)pk;
- (id) initReferringPhysicianWithResultSet:(FMResultSet*)resultSet;


@end

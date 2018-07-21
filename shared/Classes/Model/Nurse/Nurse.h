//
//  Nurse.h
//  CCiPhoneApp
//
//  Created by Ravi Ada on 11/30/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Contact.h"

@interface Nurse : NSObject 
{
	NSString *nurseId;
	NSString *nurseNpi;
	NSString *facilityNpi;
	NSString *facilityName;
	NSString *prefix;
	NSString *name;
	NSString *suffix;
	NSString *initials;
	NSString *specialty;
	NSString *credentials;
	NSString *mobile;
	NSString *phone;
	NSString *fax;
	NSString *email;
    NSInteger groupId;
}
@property (nonatomic, retain) NSString *nurseId;
@property (nonatomic, retain) NSString *nurseNpi;
@property (nonatomic, retain) NSString *facilityNpi;
@property (nonatomic, retain) NSString *facilityName;
@property (nonatomic, retain) NSString *prefix;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *suffix;
@property (nonatomic, retain) NSString *initials;
@property (nonatomic, retain) NSString *taxonomyCode;
@property (nonatomic, retain) NSString *credentials;
@property (nonatomic, retain) NSString *mobile;
@property (nonatomic, retain) NSString *phone;
@property (nonatomic, retain) NSString *fax;
@property (nonatomic, retain) NSString *email;
@property (nonatomic, assign) NSInteger groupId;

//Static methods.
+ (Nurse *) getNurseWithUsername:(NSString *)username;
+ (Nurse *) getNurseWithId:(NSNumber*)entity_id;
+ (BOOL) addOrUpdateNurse:(Nurse *)nurseObj;
+ (NSArray*) getAllNurses;
+ (NSArray*) getNursesForGroupWithId:(NSInteger)groupId;
//+ (Nurse *) nurseFromDict:(NSDictionary *)dict;

@end


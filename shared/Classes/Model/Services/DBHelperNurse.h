//
//  DBHelperNurse.h
//  CCiPhoneApp
//
//  Created by Ravi Ada on 11/29/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Facility_old.h"
#import "User.h"
#import "Nurse.h"
#import "CareTeamMember_old.h"
#import "Taxonomy.h"

@interface DBHelperNurse : NSObject

+ (User *) getUser:(NSString *)username;
+ (NSInteger) getRoleTypeId:(NSString *)role;
+ (NSMutableArray *) getFloors:(NSString *)facilityNpi;
+ (NSMutableArray *) getRooms:(NSInteger)floorId;
+ (Nurse *) getNurseWithUsername:(NSString *)username;
+ (BOOL) addOrUpdateNurse:(Nurse *)nurseObj;
+ (NSMutableArray *) getPatientsInRoom:(NSString *)room;
+ (NSMutableArray *) getPatientsOnFloor:(NSInteger)floorId;
+ (NSMutableDictionary *) getCareTeamForCensus:(NSInteger) censusId;
+ (Taxonomy *) getTaxonomy:(NSString *) code;
+ (NSMutableArray *) getPatientContacts:(NSInteger)patientId;
+ (NSInteger) addFloor: (Floor_old *)floor;
+ (NSInteger) addRoom: (NSInteger)roomId: (Room *)room;
+ (void) deleteRoomsForFloor: (NSInteger)floorId;
+ (void) deleteFloor: (NSInteger)floorId;
+ (void) deleteFloorsAndRooms;
@end

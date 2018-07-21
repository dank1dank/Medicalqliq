//
//  QliqGroupService.h
//  qliq
//
//  Created by Paul Bar on 2/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//


#import "QliqDBService.h"

#import "QliqGroup.h"
#import "QliqUser.h"

@class Facility;

@interface QliqGroupDBService : QliqDBService

+ (QliqGroupDBService *)sharedService;

- (BOOL)saveGroup:(QliqGroup *)group;
- (BOOL) safeDeleteGroup:(NSString *)qliqId;
- (BOOL) removeAllUsersFromGroup:(NSString *)qliqId;
- (void)safeDeleteUsersForGroupID:(NSString *)groupQliqId;
- (NSArray *)getGroups;
- (NSArray *)getJoinGroups;
- (NSArray *)getLeaveGroups;
- (NSArray *)getGroupsOfUser:(QliqUser *)user;
- (NSArray *)getGroupmatesOfUser:(QliqUser *)user inGroup:(QliqGroup *)group;
- (QliqGroup *)getGroupWithId:(NSString *)qliqId;
- (NSArray *)getSubGroupsWithParentId:(NSString *)parentId;

- (BOOL)addUser:(QliqUser *)user toGroup:(QliqGroup *)group;
- (NSArray *)getUsersOfGroup:(QliqGroup *)group;
- (NSArray *)getUsersOfGroup:(QliqGroup *)group withLimit:(NSUInteger)limit;
- (NSArray *)getOnlyUsersOfGroup:(QliqGroup *)group;

- (BOOL)removeAllGroupMembershipsForUser:(NSString *)qliqId;

- (BOOL)removeGroupMembershipForUser:(NSString *)qliqId inGroup:(QliqGroup *)group;


- (BOOL)setQliqStorForGroup:(QliqGroup *)group qliqStor:(QliqUser *)aStor;
- (BOOL)deleteQliqStorForGroup:(QliqGroup *)group;
+ (NSString *)getQliqStorIdForGroup:(QliqGroup *)group;
+ (NSSet *)getAllQliqStorIds;
+ (NSString *)getFirstQliqStorId;
+ (BOOL) hasAnyQliqStor;

- (BOOL)isPagerUsersContainsInGroup:(QliqGroup *)group;
- (NSUInteger)getCountOfParticipantsFor:(QliqGroup *)group;

@end

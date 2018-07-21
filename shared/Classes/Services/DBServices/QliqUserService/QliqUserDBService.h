//
//  QliqUserService.h
//  qliq
//
//  Created by Paul Bar on 2/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//


#import "QliqUser.h"
#import "QliqDBService.h"

extern NSString *QliqUserDBServiceNotificationCurrentUserDidSaved;

@interface QliqUserDBService : QliqDBService

+ (QliqUserDBService *) sharedService;

-(BOOL) saveUser:(QliqUser*)qliqUser;
-(QliqUser*) saveContactFromJsonDictionary:(NSDictionary *)userDict andNotifyAboutNew:(BOOL)notifyAboutNew;
-(NSArray*) getUsers;
-(NSArray*) getAllOtherUsers;
-(NSInteger) getAllOtherUsersCount;
-(NSArray *) getAllOtherVisibleUsers;
-(QliqUser*) getUserWithId:(NSString*)qliqId;
-(QliqUser*) getUserWithEmail:(NSString*)email;
-(QliqUser*) getUserWithMobile:(NSString*)mobile;
-(QliqUser*) getUserWithContactId:(NSInteger)contactId;
-(QliqUser*) getUserMinInfoWithContactId:(NSInteger)contactId;
-(QliqUser*) getUserWithSipUri:(NSString*)sipUri;
-(QliqUser *) getUserForContact:(Contact *) contact;
+(NSString *) getFirstQliqStorIdForUserId:(NSString *)qliqId;
-(NSMutableSet *) qliqStorsForUserId:(NSString *)qliqId;
-(NSMutableSet *) qliqStorsForGroupId:(NSString *)qliqId;

-(QliqUser*) getUserWithId:(NSString*)qliqId inDB:(FMDatabase*)database UNAVAILABLE_ATTRIBUTE;
-(QliqUser*) getUserWithEmail:(NSString*)email inDB:(FMDatabase *)database UNAVAILABLE_ATTRIBUTE;
-(QliqUser*) getUserWithSipUri:(NSString*)sipUri inDB:(FMDatabase*)database UNAVAILABLE_ATTRIBUTE;
-(BOOL) setAllOtherUsersAsDeleted:(NSSet *)activeUserQliqIds;
-(BOOL) setUsersBelongingToThisGroupOnlyAsDeleted:(NSString *)groupQliqId;
-(BOOL) updateStatusAsDeletedForUsersWithoutSharedGroups:(NSString *)myQliqId;
// We don't delete users from db, we mark the status as 'deleted'
-(void) setUserDeleted:(QliqUser *)user;
- (NSMutableSet *) getGroupIds:(QliqUser *)qliqUser;
/// Returns a list of qliqStors for all groups that the user belongs to
-(NSSet *) qliqStorsForUserId:(NSString *)qliqId inDB:(FMDatabase*)database UNAVAILABLE_ATTRIBUTE;
// Detects if the database contains qliq_user rows without matching contact rows
- (BOOL) containsQliqUsersWitoutContactRows;

- (void) resetCounterTimes;
- (void) printCounterTimes;

@end

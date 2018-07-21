//
//  UserAccountService.h
//  qliq
//
//  Created by Paul Bar on 2/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QliqApiManagerDelegate.h"
#import "ApiServiceBase.h"
#import "LoginService.h"

#import "GetUserConfigService.h"
#import "GetAllContacts.h"

#import "Constants.h"

//#import "UserSession.h"

@class UserSession;
@class QliqUser;
@class QliqGroup;

@protocol UserSessionServiceDelegate <NSObject>

- (void)didStartProcessingGroupInfo;
- (void)didLogIn;
- (void)didFailLogInWithReason:(NSString*)reason;
- (BOOL)showNewPinQuestion;

@end

@interface UserSessionService : ApiServiceBase <GetUserConfigServiceDelegate, GetAllContactsDelegate>

@property (nonatomic, assign) id<UserSessionServiceDelegate> delegate;

@property (nonatomic, assign) BOOL shouldStopSyncFlag;


+ (UserSession *)currentUserSession;
+ (NSString *)currentUsersDirPath;
+ (void)clearLastLoginDate;

+ (BOOL)isLogoutInProgress;
+ (BOOL)isOfflineDueToBatterySavingMode;
+ (void)setIsOfflineDueToBatterySavingMode:(BOOL)on;
+ (BOOL)isFirstRun;
+ (void) saveFileServerInfo:(NSDictionary *)dataDict;

//----------------- Login -------------------

- (void)logInWithUsername:(NSString *)username andPassword:(NSString *)password completitionBlock:(CompletionBlock)completition;

- (BOOL)loggedInWithDictionary:(NSDictionary *)dict withCompletion:(CompletionBlock)completion;

//----------------- Logout -------------------

- (void)logoutSessionWithCompletition:(void(^)(void))completition;

//----------------- Get/Save Data -------------------

- (void)saveLastLoggedInUser:(QliqUser *)user;
- (QliqUser *)getLastLoggedInUser;

- (void)saveLastLoggedInUserGroup:(QliqGroup *)group;
- (QliqGroup *)getLastLoggedInUserGroup;

- (void)saveLastUserSession:(UserSession *)userSession;
- (BOOL)loadLastUserSession;

//----------------- Work with synchronization -------------------

- (void)resumePagedContactsIfNeeded;

@end

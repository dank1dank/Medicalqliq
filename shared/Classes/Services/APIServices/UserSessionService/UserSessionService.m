	//
//  UserAccountService.m
//  qliq
//
//  Created by Paul Bar on 2/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UserSessionService.h"
#import "QliqApiManager.h"
#import "StringMd5.h"
#import "JSONSchemaValidator.h"
#import "GetGroupInfoResponseSchema.h"
#import "JSONKit.h"
#import "UserSession.h"
#import "DBUtil.h"
#import "KeychainService.h"
#import "SipServerInfo.h"

#import "QliqGroup.h"
#import "QliqGroupDBService.h"
#import "QliqUser.h"
#import "QliqUserDBService.h"
#import "TaxonomyDbService.h"

#import "Metadata.h"
#import "QliqSip.h"
#import "Taxonomy.h"
#import "QliqUserNotifications.h"
#import "LoginService.h"
#import "QliqJsonSchemaHeader.h"
#import "UserSettingsService.h"
#import "AppDelegate.h"
#import "MigrationService.h"
#import "QliqConnectModule.h"
#import "Constants.h"

#import "Helper.h"
#import "LogoutService.h"

#import "SetPresenceStatusService.h"
#import "GetQuickMessagesService.h"
#import "GetContactsPaged.h"
#import "GetAllOnCallGroupsService.h"

#import "NotificationUtils.h"
#import "QliqStorClient.h"
#import "OnCallGroup.h"

#import "Login.h"
#import "RestClient.h"
#import "QxPlatfromIOS.h"

#define ARC4RANDOM_MAX      0x100000000

//TODO: when user model will be implemented, save that model instead of partial id,name,group saving
#define kLastLoggedInUserKey        @"lastLoggedUser"
#define kLastLoggedInUserGroupKey   @"lastLoggedUserGroup"
#define kLastUserSession            @"LastUserSession"

#define kRescheduleChimeNotifications @"RescheduleChimeNotifications"

static __strong UserSession *s_currentUserSession = nil;
static BOOL _isLogoutInProgress;
static BOOL _isOfflineDueToBatterySavingMode;
static BOOL _isFirstRun;

@interface UserSessionService()

@property (nonatomic, strong) LoginService *loginService;

@end

@implementation UserSessionService
@synthesize delegate;
@synthesize loginService;

#pragma mark - Lifycycle

- (id)init
{
    self = [super init];
    if (self) {
        [self registerForNotification:QliqUserDBServiceNotificationCurrentUserDidSaved selector:@selector(userDidChanged:)];
    }
    return self;
}

- (void)dealloc {
    [self unregisterForNotification:QliqUserDBServiceNotificationCurrentUserDidSaved];
}

#pragma mark - Public -

+ (UserSession *)currentUserSession
{
    if(s_currentUserSession == nil) {
        s_currentUserSession = [[UserSession alloc] init];
    }
    return s_currentUserSession;
}

+ (NSString *)currentUsersDirPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *dirPath = [NSString stringWithFormat:@"%@/%@", documentsDirectory, [self currentUserSession].user.qliqId];
    
    return dirPath;
}

+ (BOOL)isLogoutInProgress {
    return _isLogoutInProgress;
}

+ (BOOL)isOfflineDueToBatterySavingMode {
    return _isOfflineDueToBatterySavingMode;
}

+ (BOOL)isFirstRun {
    return _isFirstRun;
}

+ (void) saveFileServerInfo:(NSDictionary *)dataDict
{
    NSDictionary *fileServerInfo = dataDict[@"file_server_info"];
    if (fileServerInfo) {
        NSString *fileServerUrl = fileServerInfo[@"url"];
        [[KeychainService sharedService] saveFileServerUrl:fileServerUrl];
        //[RestClient setFileServerUrl:fileServerUrl];
    }
}

+ (void)setIsOfflineDueToBatterySavingMode:(BOOL)on {
    _isOfflineDueToBatterySavingMode = on;
}

+ (void)clearLastLoginDate {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObjectForKey:kLastLoggedIn];
    [userDefaults setValue:@NO forKey:kLoginWithPin];
    [userDefaults synchronize];
}

- (void)stopGetUserConfig {
    
    [[GetContactsPaged sharedService] stopProgress];
    [self setGettingDataForCurrentUserFinished:YES];
}

- (void)resumePagedContactsIfNeeded
{
    NSString *qliqId = [UserSessionService currentUserSession].user.qliqId;
    NSInteger startPage = [GetContactsPaged lastSavedPageForQliqId:qliqId];
    
    BOOL wasStopped = [GetContactsPaged getPageContactsOperationStateForQliqId:qliqId];
    
    if (startPage > 0 && wasStopped) {
        //Resume PagedContacts download if [GetContactsPaged sharedService] was stopped with logout or terminate
        DDLogSupport(@"Resuming get_paged_contacts calls");
//        [self getUserConfigSuccess:YES];
        [self getAllContactsPaged:wasStopped withCompletitionBlock:^(CompletitionStatus status, id result, NSError *error) {
            
            if (status == CompletitionStatusError) {
                 DDLogSupport(@"Cannot get all contacts page. Error: %@", [error localizedDescription]);
            }
        }];//Was "NO" - *16_02_2016*
    }
}

#pragma mark Login

- (void)logInWithUsername:(NSString *)username andPassword:(NSString *)password completitionBlock:(CompletionBlock) completition {
    
    [UserSessionService currentUserSession].sipAccountSettings.username = username;
    [UserSessionService currentUserSession].sipAccountSettings.password = password;
    
    self.shouldStopSyncFlag = NO;
    
    self.loginService = [[LoginService alloc] initWithUsername:username andPassword:password];
    
    __weak __block typeof(self) weakSelf = self;
    
    [self.loginService callServiceWithCompletition:^(CompletitionStatus statusOfServiceResponse, NSDictionary *dictOfServiceResponse, NSError *errorOfServiceResponse) {
        
        if (statusOfServiceResponse == CompletitionStatusSuccess) {
            
            if (dictOfServiceResponse) {
                
                if ([self.delegate respondsToSelector:@selector(showNewPinQuestion)]) {
                    
                    /*
                     saving server responce dictionary for LoginWithPassword login way
                     !IMPORTANT!
                     */
                   [UserSessionService currentUserSession].loggedInDictionary = dictOfServiceResponse;
                    
                    if (![weakSelf.delegate showNewPinQuestion]) {
                        [weakSelf loggedInWithSuccess:dictOfServiceResponse withCompletion:^(CompletitionStatus status, id result, NSError *error) {
                            if (completition) {
                                completition(status, result, error);
                            }
                            return;
                        }];
                    }
                    
                } else {
                    [weakSelf loggedInWithSuccess:dictOfServiceResponse withCompletion:^(CompletitionStatus status, id result, NSError *error) {
                        if (completition) {
                            completition(status, result, error);
                        }
                         return;
                    }];
                }
            }
        } else if (statusOfServiceResponse == CompletitionStatusError) {
            
            [weakSelf.delegate didFailLogInWithReason:[errorOfServiceResponse localizedDescription]];
            
        }
        
        if (completition) {
            completition(statusOfServiceResponse, dictOfServiceResponse, errorOfServiceResponse);
        }
    }];
}

/*
 method for executing "after login" operations after press on "Setup Pin Later" or PIN Confirmation after press "Next" button on SetNewPinQuestion screen
 */
- (BOOL)loggedInWithDictionary:(NSDictionary *)dict withCompletion:(CompletionBlock)completion {
    __block BOOL success = NO;
    
    if (dict) {
        [self loggedInWithSuccess:dict withCompletion:^(CompletitionStatus status, id result, NSError *error) {
            if (error)
                success = NO;
            else
                success = YES;
            
            if (completion) {
                completion(status, result, error);
            }
        }];
        
    } else {
        DDLogError(@"\n\n\n---------------ERROR: Nil server response dictionary for login request-----------\n\n\n");
        success = NO;
    }
    
    dict = nil;
    return success;
}

#pragma mark Logout

- (void)logoutSessionWithCompletition:(void(^)(void))completition {
    
    if (!_isLogoutInProgress) {
        
        _isLogoutInProgress = YES;
        s_currentUserSession.isLoginSeqeuenceFinished = NO;
        
        /*
         This block calls when logout request to server was send
         */
        void(^logoutSessionCompletion)(void) = ^(void) {
            
            //Need Clear Data
            [[QliqSip instance] sipStop];
            
            [Helper setMyQliqId:nil];
            [OnCallGroup setOnCallGroups:nil];
            //            [[KeychainService sharedService] clearPin];
            
            
            if ([appDelegate.idleController lockedIdle]) {
                [appDelegate.idleController unlockIdle];
            }

            [[Login sharedService] settingShouldSkipAutoLogin:YES];
            
            // If the user requested logout then clear last login date, so we don't do local login next time
            [UserSessionService clearLastLoginDate];
            
            [[QliqUserNotifications getInstance] cancelChimeNotifications:YES];
            
            s_currentUserSession = nil;
            
            //Mark that the user has logged out
            [appDelegate userLoggedout];
            
            if (completition)
                completition();
            
             _isLogoutInProgress = NO;
            DDLogSupport(@"Logout complete...");
        };
        
        //Need to stop PUSH Notifications
        // Krishna. This will create more problems
        //
        // [[UIApplication sharedApplication] unregisterForRemoteNotifications];
        
        [self stopGetUserConfig];
        
        if ([[QliqSip sharedQliqSip] isRegistered])
            [[QliqSip sharedQliqSip] logout];
        
        [[QliqSip instance] endAllCalls];
        
        
        [appDelegate.network.reachability stopNotifications];
        [appDelegate.network.progressHandlers cancelAllProgressHandlers];

        [[QliqStorClient sharedDataServerClient] logout];

        [[NSNotificationCenter defaultCenter] postNotificationName:@"RemoveNotifications" object:nil];

        double delayInSeconds = 0.5;    //Used this delay just to show loading circle in SettingsView
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            // 8/6/2014 Krishna
            // Always call Logout service
            [[LogoutService sharedService] sentLogoutRequest];
            logoutSessionCompletion();
        });
    } else if (completition) {
        
        if ([appDelegate.idleController lockedIdle]) {
            [appDelegate.idleController unlockIdle];
        }
        
        [[Login sharedService] settingShouldSkipAutoLogin:YES];
        
        completition();
    }
}

#pragma mark Save/Get Data

- (void)clearLastLoggedInUser
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:nil forKey:kLastLoggedInUserKey];
    [defaults synchronize];
}

- (void)saveLastLoggedInUser:(QliqUser *)user
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *encodedUser = [NSKeyedArchiver archivedDataWithRootObject:user];
    [defaults setObject:encodedUser forKey:kLastLoggedInUserKey];
    [defaults synchronize];
    
    // Whenever we update user we need to update it in qxlib also
    [QxPlatfromIOS setMyUser:user];
}

- (QliqUser *)getLastLoggedInUser
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *encodedUser = [defaults objectForKey:kLastLoggedInUserKey];
    
    QliqUser *user = nil;
    if (encodedUser){
        @try {
            user = (QliqUser *)[NSKeyedUnarchiver unarchiveObjectWithData:encodedUser];
        }
        @catch (NSException *exception) {
            DDLogError(@"Error during loading user: %@",exception);
            user = nil;
        }
    }
    
    return user;
}

- (void)saveLastLoggedInUserGroup:(QliqGroup *)group
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *encodedUser = [NSKeyedArchiver archivedDataWithRootObject:group];
    [defaults setObject:encodedUser forKey:kLastLoggedInUserGroupKey];
    [defaults synchronize];
}

- (QliqGroup *)getLastLoggedInUserGroup
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *encodedUser = [defaults objectForKey:kLastLoggedInUserGroupKey];
    
    QliqGroup *group = nil;
    if (encodedUser){
        @try {
            group = (QliqGroup *)[NSKeyedUnarchiver unarchiveObjectWithData:encodedUser];
        }
        @catch (NSException *exception) {
            DDLogError(@"Error during loading group: %@",exception);
            group = nil;
        }
    }
    
    return group;
}

- (void)saveLastUserSession:(UserSession *)userSession
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *encodedUserSession = [NSKeyedArchiver archivedDataWithRootObject:userSession];
    [defaults setObject:encodedUserSession forKey:kLastUserSession];
    [defaults synchronize];
}

- (BOOL)loadLastUserSession
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *encodedUserSession = [defaults objectForKey:kLastUserSession];
    
    UserSession *userSession = nil;
    if (encodedUserSession){
        @try {
            userSession = (UserSession *) [NSKeyedUnarchiver unarchiveObjectWithData:encodedUserSession];
        }
        @catch (NSException *exception) {
            DDLogError(@"Error during loading settings: %@",exception);
            userSession = nil;
        }
    }
    
    s_currentUserSession = userSession;
    return (userSession != nil);
}

#pragma mark - Private -
///**
 //*  This Method Continue Login and Setup Usser Session
// *
 //*  @param loginDataResponse <#loginDataResponse description#>
 //*/
- (void)loggedInWithSuccess:(NSDictionary *)loginDataResponse withCompletion:(CompletionBlock)completion {
    
    //Save the date of last successfull login.
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kLastLoggedIn];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    //check for temp_password. If =true then stop doing any calls
    NSNumber *isTempPassword = loginDataResponse[kLoginResponseShowResetPasswordAlertKey];
    
    if (isTempPassword && [isTempPassword isKindOfClass:[NSNumber class]] && (YES == [isTempPassword boolValue])) {
        self.shouldStopSyncFlag = YES;
    }
    
    if (self.shouldStopSyncFlag) {
        NSLog(@"User cancelled initial synchronization or temp_password=true");
        
        [NSNotificationCenter postNotification:kHideProgressHUDNotificationName userInfo:nil];
        
        return;
    }
    
    
    NSString *showAlertValue = loginDataResponse[kLoginResponseShowAlertKey];
    
    if ([showAlertValue isEqualToString:kLoginResponseShowInviteAlert]) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kShowInviteAlertOnceLoggedInKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    else if ([showAlertValue isEqualToString:kLoginResponseShowResendAlert]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kShowResendInvitationsAlertOnceLoggedIn];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    else if ([showAlertValue isEqualToString:kLoginResponseShowProfileAlert]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kShowEditProfileAlertOnceLoggedIn];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    else if ([showAlertValue isEqualToString:kLoginResponseShowSoundSettings]) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kShowSoundSettings];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    NSString *qliqId = loginDataResponse[QLIQ_ID];
    QliqUser *lastLoggedInUser = [self getLastLoggedInUser];
    NSString *prevQliqId = lastLoggedInUser.qliqId;
    
    QliqUser *loggingUser = nil;
    
    if (![qliqId isEqualToString:prevQliqId]) {
        loggingUser = [[QliqUser alloc] init];
        loggingUser.qliqId = qliqId;
    }
    else {
        loggingUser = lastLoggedInUser;
    }
    
    NSString *apiKey = loginDataResponse[API_KEY];
    [[KeychainService sharedService] saveApiKey:apiKey];
    [RestClient setApiKey:apiKey];
    
    [UserSessionService saveFileServerInfo:loginDataResponse];

    UserSessionService *service = [[UserSessionService alloc] init];
    [UserSessionService currentUserSession].user = loggingUser;
    [service saveLastLoggedInUser:loggingUser];
    [service saveLastUserSession:[UserSessionService currentUserSession]];
    
    NSString *appstoreVersion = [loginDataResponse objectForKey:CURRENT_VERSION];
    //NSString *releaseDate = [loginDataResponse objectForKey:RELEASE_DATE];
    //NSString *configChanged = [loginDataResponse objectForKey:CONFIG_CHANGED];
    
    NSDictionary *securitySettingsDict = [loginDataResponse objectForKey:SECURITY_SETTINGS];
    //NSString *inactivityTime = [securitySettingsDict objectForKey:INACTIVITY_TIME];
    //NSString *enforcePin = [securitySettingsDict objectForKey:ENFORCE_PIN];
    
    [UserSessionService currentUserSession].publicKeyMd5FromWebServer = [loginDataResponse objectForKey:PUBKEY_MD5];
    
    AppDelegate *appDelegate = [AppDelegate sharedInstance];
    NSString *currentAppVersion = [AppDelegate currentBuildVersion];
    appDelegate.availableVersion = appstoreVersion;
    DDLogSupport(@"appStoreVersion: %@", appstoreVersion);
    
    NSArray *appSubscriptions = [loginDataResponse objectForKey:APP_SUBSCRIPTIONS];
    
    [UserSessionService currentUserSession].subscriprion = [ApplicationsSubscription applicationSubscriptionWithArray:appSubscriptions];
    
    NSString *username = [UserSessionService currentUserSession].sipAccountSettings.username;
    [UserSessionService currentUserSession].dbKey = [[KeychainService sharedService] dbKeyForUserWithId:username];

    BOOL wasDatabaseReset = NO;
    
    if ([[DBUtil sharedInstance] prepareDBForUserSession:[UserSessionService currentUserSession]] == NO) {
        DDLogError(@"Failed to prepare database for user session, deleting file and retrying");
        [[DBUtil sharedInstance] deleteOpenDatabase];
        wasDatabaseReset = YES;
        if ([[DBUtil sharedInstance] prepareDBForUserSession:[UserSessionService currentUserSession]] == NO) {
            DDLogError(@"This was already a retry, giving up");
            [NSNotificationCenter postNotification:kHideProgressHUDNotificationName userInfo:nil];
            // TODO: show 'Cannot open database' alert here?
            // if we got here then app cannot recover and cannot proceed
            
            if (completion) {
                NSString *errCode = dbCanNotBeOpenErrorCode;
                
                NSError *error = [NSError errorWithDomain:errorCurrentDomain
                                                     code:errCode.intValue
                                                 userInfo:userInfoWithDescription(@"DB cannot be opened. DB was corrupted on 'prepare database for user session' after deleting and retry")];
                
                DDLogError(@"%@", [error localizedDescription]);
                
                __weak __block typeof(self) welf = self;
                [self logoutSessionWithCompletition:^{
                    [[KeychainService sharedService] clearPin];
                    [welf clearLastLoggedInUser];
                }];
                
                completion(CompletitionStatusError, nil, error);
            }
            return;
        }
    }
    
    if (!wasDatabaseReset) {
        DDLogSupport(@"Empty DB detected, will call all webservices");
        wasDatabaseReset = ([[QliqUserDBService sharedService] getAllOtherUsersCount] == 0);
    }
    
    // Since 'fastLogin' branch we have user info in login response
    NSMutableDictionary *userInfoDict = [loginDataResponse objectForKey:USER];
    loggingUser = [GetUserConfigService parseAndSaveUser:userInfoDict];
    
    [UserSessionService currentUserSession].user = loggingUser;
    [service saveLastLoggedInUser:loggingUser];
    [service saveLastUserSession:[UserSessionService currentUserSession]];
    
    
    UserSettingsService *userSettingsService = [[UserSettingsService alloc] init];
    UserSettings *userSettings = [userSettingsService getSettingsForUser:[UserSessionService currentUserSession].user];
    
    NSInteger appStoreVersionInt = [appstoreVersion integerValue];
    [UserSessionService currentUserSession].userSettings.currentAppVersionFromWebServer = appStoreVersionInt;
    
    [[NSUserDefaults standardUserDefaults] setInteger:appStoreVersionInt forKey:@"AppStoreVersion"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    userSettings.securitySettings = [SecuritySettings securitySettingsWithDictionary:securitySettingsDict];
    [userSettings write];
    
//    [appDelegate configureInactivityLock];
    
    NSNumber *optionalBatterySave = [loginDataResponse objectForKey:@"battery_save"];
    if (optionalBatterySave != nil) {
        userSettings.isBatterySavingModeEnabled = [optionalBatterySave boolValue];
    }
    
    /* setup presence */
    Presence * presence = [[Presence alloc] init];
    presence.presenceType = [loginDataResponse objectForKey:PRESENCE_STATUS];
    presence.message = [loginDataResponse objectForKey:PRESENCE_MESSAGE];
    presence.forwardingUser = [[QliqUserDBService sharedService] getUserWithId:[loginDataResponse objectForKey:FORWARDING_QLIQ_ID]];
    
    userSettings.presenceSettings.prevPresenceType = userSettings.presenceSettings.currentPresenceType;
    userSettings.presenceSettings.currentPresenceType = presence.presenceType;
    
    Presence * presenceInSettings = [userSettings.presenceSettings presenceForType:presence.presenceType];
    presenceInSettings.message = presence.message;
    presenceInSettings.forwardingUser = presence.forwardingUser;
    
    [[UserSessionService currentUserSession].userSettings write];
    
    [appDelegate.network.presences setPresence:presence forUser:loggingUser];
    
    userSettings.currentAppVersionFromWebServer = appStoreVersionInt;
    if ([currentAppVersion intValue] == appStoreVersionInt) {
        userSettings.lastUpgradeAlertDate = nil;
    }
    
    // Update the Feature Info in userSettings
    [UserSettingsService parseAndUpdateFeatureInfo:loginDataResponse[FEATURES_INFO] forUserSettings:userSettings];
    
    
    [userSettingsService saveUserSettings:userSettings forUser:loggingUser];
    [UserSessionService currentUserSession].userSettings = userSettings;
    
    //Presence * currentPresence = [userSettings.presenceSettings presenceForType:userSettings.presenceSettings.currentPresenceType];
    //SetPresenceStatusService * presenceService = [[SetPresenceStatusService alloc] initWithPresence:currentPresence ofType:userSettings.presenceSettings.currentPresenceType];
    //[presenceService callServiceWithCompletition:nil];
    
    [NSNotificationCenter postNotificationToMainThread:kRescheduleChimeNotifications];
    
    /* Force cancel chimes if no unread messages. Useful when app reinstalled and system have scheduled notification from old version  */
    if ([ChatMessage unreadMessagesCount] == 0){
        [[QliqUserNotifications getInstance] cancelChimeNotifications:YES];
    }
    
    
    BOOL aHasSipServerFqdnChanged, aHasSipServerConfigChanged;
    NSMutableDictionary *sipServerDict = [loginDataResponse objectForKey:SIP_SERVER_INFO];
    SipServerInfo *sipServerInfo = [GetUserConfigService parseAndSaveSipServerInfo:sipServerDict hasSipServerFqdnChanged:&aHasSipServerFqdnChanged hasSipServerConfigChanged:&aHasSipServerConfigChanged];
    [UserSessionService currentUserSession].sipAccountSettings.serverInfo = sipServerInfo;
    [UserSessionService currentUserSession].sipAccountSettings.sipUri = [userInfoDict objectForKey:SIP_URI];
    
    _isFirstRun = wasDatabaseReset || [self isGettingDataForCurrentUserFinished] == NO;

    //    dispatch_async_background(^{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        //*
        if (_isFirstRun) {
            // Make sure we start get_paged_contacts from beginning
            
            BOOL wasStopped = NO;
            [GetContactsPaged setPageContactsOperationState:wasStopped forQliqId:[UserSessionService currentUserSession].user.qliqId];
            
            [GetContactsPaged setLastSavedPage:0 forQliqId:[UserSessionService currentUserSession].user.qliqId];
            
            [[GetUserConfigService sharedService] getUserConfig:!_isFirstRun withCompletitionBlock:^(CompletitionStatus status, id result, NSError *error) {
                
                [NSNotificationCenter postNotification:kHideProgressHUDNotificationName userInfo:nil];
                
                if (self.shouldStopSyncFlag) {
                    DDLogSupport(@"User cancelled initial synchronization or temp_password=true");
                    return;
                }
                
                switch (status) {
                    case CompletitionStatusSuccess:
                    {
                        if (_isFirstRun) {
                            // didn't load contacts and session info previously for this user
                            // This will call get_all_contacts
//                            [self getUserConfigSuccess:YES];
                            dispatch_async_background(^{
                                [self getAllContactsPaged:YES withCompletitionBlock:^(CompletitionStatus status, id result, NSError *error) {
                                    
                                    if (status == CompletitionStatusError) {
                                        DDLogSupport(@"Cannot get all contacts page. Error: %@", [error localizedDescription]);
                                    }
                                }];
                            });
                        } else {
                            [self getAllContactsSuccess];
                        }
                        break;
                    }
                    case CompletitionStatusError:
                        [self didFailToGetUserConfigWithReason:[error localizedDescription]];
                        break;
                    case CompletitionStatusCancel:
                        break;
                }
            }];
            
            
            GetQuickMessagesService *getQuickMessages = [[GetQuickMessagesService alloc] initWithQliqId: qliqId];
            [getQuickMessages callServiceWithCompletition:^(CompletitionStatus status, id result, NSError *error) {
            }];
            [[[GetAllOnCallGroupsService alloc] init] getWithCompletionBlock:nil];
        }
        else {
            if (aHasSipServerFqdnChanged) {
                DDLogSupport(@"First run or SIP server fqdn change detected will call get_all_contacts");
                // didn't load contacts and session info previously for this user
                // This will call get_all_contacts
                
//                [self getUserConfigSuccess:YES];
                [self getAllContactsPaged:YES withCompletitionBlock:^(CompletitionStatus status, id result, NSError *error) {
                    
                    if (status == CompletitionStatusError) {
                        DDLogSupport(@"Cannot get all contacts page. Error: %@", [error localizedDescription]);
                    }
                }];
            }
            else {
                [self getAllContactsSuccess];
            }
        }
        //    */
    });
    
    [self.delegate didLogIn];
}

- (BOOL)isGettingDataForCurrentUserFinished {
    return [[NSUserDefaults standardUserDefaults] boolForKey:[UserSessionService currentUserSession].user.qliqId];
}

- (void)setGettingDataForCurrentUserFinished:(BOOL)isFinished {
    [[NSUserDefaults standardUserDefaults] setBool:isFinished forKey:[UserSessionService currentUserSession].user.qliqId]; // set user defaults for checking app "isFirstRun" for current user
}

#pragma mark Notifications

- (void)userDidChanged:(NSNotification *)notification
{
    QliqUser *updatedUser = notification.object;
    UserSession *currentSession = [[self class] currentUserSession];
    
    if ([currentSession.user.qliqId isEqualToString:updatedUser.qliqId]) {
        [self saveLastLoggedInUser:updatedUser];
    }
}

#pragma mark - Delegates -

#pragma mark GetUserConfigServiceDelegate


//- (void)getUserConfigSuccess:(BOOL)isLogin
//{
//    NSString *qliqId = [UserSessionService currentUserSession].user.qliqId;
//    NSInteger savedPage = [GetContactsPaged lastSavedPageForQliqId:qliqId];
//    NSInteger startPage = savedPage;
//    
//    /*
//     operation which perform Contacts download was stopped
//     at last login session for current user,
//     contacts download didn't complete.
//     set new start page for downloading
//     */
//    if ([GetContactsPaged getPageContactsOperationStateForQliqId:qliqId]) {
//        
//        BOOL wasStopped = NO;
//        [GetContactsPaged setPageContactsOperationState:wasStopped forQliqId:qliqId];
//        
//        startPage = savedPage + 1; //new start page
//    }
//    
//    [GetContactsPaged getAllPagesStartingFrom:(unsigned int)startPage completion:^(CompletitionStatus status, id result, NSError *error) {
//        
//        if (error || CompletitionStatusError == status) {
//            if (isLogin) {
//                [self didFailToGetAllContactsWithReason:[error localizedDescription]];
//            }
//        }
//        else {
//            [SVProgressHUD dismiss];
//            
//            dispatch_async_background(^{
//                [self getAllContactsSuccess]; //AIIII
//            });
//        }
//    }];
//}

- (void)getAllContactsPaged:(BOOL)isFirstRun withCompletitionBlock:(CompletionBlock) completition
{
    NSString *qliqId = [UserSessionService currentUserSession].user.qliqId;
    NSInteger savedPage = [GetContactsPaged lastSavedPageForQliqId:qliqId];
    NSInteger startPage = savedPage;
    
    /*
     operation which perform Contacts download was stopped
     at last login session for current user,
     contacts download didn't complete.
     set new start page for downloading
     */
    if ([GetContactsPaged getPageContactsOperationStateForQliqId:qliqId]) {
        
        BOOL wasStopped = NO;
        [GetContactsPaged setPageContactsOperationState:wasStopped forQliqId:qliqId];
        
        startPage = savedPage + 1; //new start page
    }
    
    [GetContactsPaged getAllPagesStartingFrom:(unsigned int)startPage completion:^(CompletitionStatus status, id result, NSError *error) {
        
        if (error || CompletitionStatusError == status) {
            if (isFirstRun) {
                [self didFailToGetAllContactsWithReason:[error localizedDescription]];
            }
            if (completition) {
                completition(CompletitionStatusError, nil, error);
            }
        }
        else {
            dispatch_async_main(^{
                [SVProgressHUD dismiss];
            });
        
            [self getAllContactsSuccess];
            
            if (completition) {
                completition(CompletitionStatusSuccess, nil, nil);
            }
        }
    }];
}

- (void)didFailToGetUserConfigWithReason:(NSString *)reason {
    [self.delegate didFailLogInWithReason:reason];
}

#pragma mark GetAllContactsDelegate

- (void)getAllContactsSuccess {
    
    [self setGettingDataForCurrentUserFinished:YES];
    
    //set the vibrate to on initially
    [[QliqUserNotifications getInstance] setCanVibrate:YES];
    
    //Should Update Contacts List
    dispatch_async_main(^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kUpdateContactsListNotificationName object:nil userInfo:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"AllContactsAreSyncedNotification" object:nil userInfo:nil];
        
    });
}

- (void)didFailToGetAllContactsWithReason:(NSString *)reason {
    //Store NO, so contacts will be loaded next time
    [self setGettingDataForCurrentUserFinished:NO];
    
    [self.delegate didFailLogInWithReason:reason];
}

#pragma mark  QliqApiManagerDelegate

- (void)apiManagerDidFailLogInWithReason:(NSString *)reason {
    [self.delegate didFailLogInWithReason:reason];
}


@end

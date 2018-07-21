//
//  GetUserConfigService.h
//  qliq
//
//  Created by Ravi Ada on 06/05/12.
//  Copyright (c) 2012 qliqSoft Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QliqApiManagerDelegate.h"
#import "ApiServiceBase.h"

@class UserSession;
@class QliqUser;
@class SipServerInfo;

/* Notifications
*/
extern NSString *UserConfigDidRefreshedNotification;
extern NSString *SipServerFqdnChangedKey;
extern NSString *SipServerConfigChangedKey;

@protocol GetUserConfigServiceDelegate <NSObject>

- (void)getUserConfigSuccess:(BOOL)isLogin;
- (void)didFailToGetUserConfigWithReason:(NSString *)reason;
                
@end

@interface GetUserConfigService : ApiServiceBase

+ (GetUserConfigService *)sharedService;

+ (SipServerInfo *)parseAndSaveSipServerInfo:(NSDictionary *)sipServerDict
                     hasSipServerFqdnChanged:(BOOL *)aHasSipServerFqdnChanged
                   hasSipServerConfigChanged:(BOOL *)aHasSipServerConfigChanged;

+ (QliqUser *)parseAndSaveUser:(NSDictionary *)userInfoDict;

- (void)getUserConfig:(BOOL)callGetGroupContacts withCompletitionBlock:(CompletionBlock)completition;
- (void)getUserConfig:(BOOL)callGetGroupContacts;
- (void)getUserConfigFromDB;

@property (nonatomic, assign) id<GetUserConfigServiceDelegate> delegate UNAVAILABLE_ATTRIBUTE; //Use block interface instead

@end

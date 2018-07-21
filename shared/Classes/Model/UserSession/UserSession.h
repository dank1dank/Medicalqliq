//
//  UserSession.h
//  qliq
//
//  Created by Paul Bar on 2/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ApplicationsSubscription.h"
#import "SipAccountSettings.h"
#import "QliqUser.h"
#import "UserSettings.h"
#import "SecuritySettings.h"

#import "SipContact.h"

@interface UserSession : NSObject <NSCoding>

- (void) cleanup;

@property (nonatomic, assign) BOOL isLoginSeqeuenceFinished;
@property (nonatomic, strong) QliqUser *user;
@property (nonatomic, readonly, strong) SipContact *sipContact;
@property (nonatomic, strong) ApplicationsSubscription *subscriprion;
@property (nonatomic, strong) SipAccountSettings *sipAccountSettings;
@property (nonatomic, strong) NSString *dbKey;
@property (nonatomic, strong) UserSettings *userSettings;
@property (nonatomic, strong) NSString *publicKeyMd5FromWebServer;

@property (nonatomic, strong) NSDictionary *loggedInDictionary;

@property (nonatomic, getter=isLocal) BOOL local;

@end

//
//  UserSession.m
//  qliq
//
//  Created by Paul Bar on 2/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UserSession.h"
#import "KeychainService.h"
#import "UserSettingsService.h"

#import "DBUtil.h"
#import "SipContact.h"
#import "SipContactDBService.h"

@implementation UserSession

@synthesize isLoginSeqeuenceFinished;
@synthesize user;
@synthesize sipContact;
@synthesize subscriprion;
@synthesize sipAccountSettings;
@synthesize dbKey;
//@synthesize userSettings;
@synthesize publicKeyMd5FromWebServer;

- (SipContact *)sipContact{
    if (!sipContact && self.user){
        sipContact = [[[SipContactDBService alloc] init] sipContactForQliqId:self.user.qliqId];
    }
    return sipContact;
}

-(id) init
{
    self = [super init];
    if(self)
    {
        self.sipAccountSettings = [[SipAccountSettings alloc] init];
        self.subscriprion = [[ApplicationsSubscription alloc] init];
        self.userSettings = [[UserSettings alloc] init];
    }
    return self;
}

- (void)setUserSettings:(UserSettings *)userSettings {
    _userSettings = userSettings;
}

-(void) cleanup
{
    self.sipAccountSettings = [[SipAccountSettings alloc] init];
    self.subscriprion = [[ApplicationsSubscription alloc] init];
    self.userSettings = [[UserSettings alloc] init];
    self.dbKey = nil;
    self.user = nil;
    self.publicKeyMd5FromWebServer = nil;
    sipContact = nil;
    
    self.loggedInDictionary = nil;
}


#pragma mark -
#pragma mark serialization

static NSString *key_user = @"key_user";
static NSString *key_subscription = @"key_subscription";
static NSString *key_sipAccountSettings = @"key_sipAccountSettings";
static NSString *key_dbKey = @"key_dbKey";
static NSString *key_usersCallbackNumber = @"usersCallbackNumber";
static NSString *key_publicKeyMd5FromWebServer = @"publicKeyMd5FromWebServer";

//static NSString *key_userSettings = @"key_userSettings";

-(void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.user forKey:key_user];
    [aCoder encodeObject:self.subscriprion forKey:key_subscription];
    [aCoder encodeObject:self.sipAccountSettings forKey:key_sipAccountSettings];
    [aCoder encodeObject:self.dbKey forKey:key_dbKey];
    [aCoder encodeObject:self.publicKeyMd5FromWebServer forKey:key_publicKeyMd5FromWebServer];
//    [aCoder encodeObject:self.userSettings forKey:key_userSettings];
//        [[[UserSettingsService alloc] init] saveUserSettings:self.userSettings forUser:self.user];
}

-(id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if(self)
    {
        self.user = [aDecoder decodeObjectForKey:key_user];
        self.subscriprion = [aDecoder decodeObjectForKey:key_subscription];
        self.sipAccountSettings = [aDecoder decodeObjectForKey:key_sipAccountSettings];
        self.dbKey = [aDecoder decodeObjectForKey:key_dbKey];
        self.publicKeyMd5FromWebServer = [aDecoder decodeObjectForKey:key_publicKeyMd5FromWebServer];
        self.userSettings = [[[UserSettingsService alloc] init] getSettingsForUser:self.user];
  
        self.loggedInDictionary = nil;
//        self.userSettings = [aDecoder decodeObjectForKey:key_userSettings];
    }
    return self;
}

@end

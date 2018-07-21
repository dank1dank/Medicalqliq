//
//  GetSecuritySettingsService.m
//  qliq
//
//  Created by Ravi Ada on 01/09/2013.
//
//

#import "GetSecuritySettingsService.h"
#import "JSONSchemaValidator.h"
#import "QliqJsonSchemaHeader.h"
#import "KeychainService.h"
#import "JSONKit.h"
#import "RestClient.h"

#import "DBUtil.h"

#import "SipContact.h"
#import "SipContactDBService.h"

#import "Recipients.h"
#import "QliqUserDBService.h"
#import "UserSettingsService.h"

@interface GetSecuritySettingsService()

@property (nonatomic, strong) NSString * deviceUuid;

@end

@implementation GetSecuritySettingsService

@synthesize deviceUuid;

- (NSString *)serviceName {
    return @"services/get_security_settings";
}

- (id) initWithDeviceUuid:(NSString *) _deviceUuid
{
    self = [super init];
    if (self) {
        self.deviceUuid = _deviceUuid;
    }
    return self;
}

- (Schema)requestSchema {
    return GetSecuritySettingsRequestSchema;
}

- (Schema)responseSchema {
    return GetSecuritySettingsResponseSchema;
}

- (NSDictionary *)requestJson {
    
    UserSession * currentSession = [UserSessionService currentUserSession];
    
	NSMutableDictionary * dataDict = [[NSMutableDictionary alloc] init];
    dataDict[USERNAME] = currentSession.sipAccountSettings.username;
    dataDict[PASSWORD] = currentSession.sipAccountSettings.password;
    dataDict[DEVICE_UUID] = self.deviceUuid;

    return @{ MESSAGE : @{ DATA : dataDict } };
}

- (void)handleResponseMessageData:(NSDictionary *)dataDict withCompletition:(CompletionBlock)completitionBlock {
    
    DDLogSupport(@"\n\n\n Security Settings: %@", dataDict);
    
    SecuritySettings *securitySettings = [SecuritySettings securitySettingsWithDictionary:dataDict];
    if (completitionBlock) {
        completitionBlock(CompletitionStatusSuccess, securitySettings, nil);
    }
}

@end

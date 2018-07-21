//
//  GetPresenceStatusService.m
//  qliq
//
//  Created by Ravi Ada on 11/23/12.
//
//

#import "GetPresenceStatusService.h"
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
#import "NotificationUtils.h"

#define kRescheduleChimeNotifications @"RescheduleChimeNotifications"

NSString *PresenceChangeStatusNotification = @"PresenceChangeStatusNotification";

@interface GetPresenceStatusService()

@property (nonatomic, strong) NSString * qliqId;

@end

@implementation GetPresenceStatusService

@synthesize qliqId;

- (NSString *) serviceName{
    return @"services/get_presence_status";
}

- (id) initWithQliqId:(NSString *) _qliqId
{
    self = [super init];
    if (self) {
        self.qliqId = _qliqId;
    }
    return self;
}

- (Schema)requestSchema{
    return GetPresenceStatusRequestSchema;
}

- (Schema)responseSchema{
    return GetPresenceStatusResponseSchema;
}

- (NSDictionary *)requestJson{
    
    UserSession * currentSession = [UserSessionService currentUserSession];
    
	NSMutableDictionary * dataDict = [[NSMutableDictionary alloc] init];
    dataDict[USERNAME] = currentSession.sipAccountSettings.username;
    dataDict[PASSWORD] = currentSession.sipAccountSettings.password;
    dataDict[QLIQ_ID] = self.qliqId;

    if (self.reason.length > 0) {
        dataDict[REASON] = self.reason;
    }
    return @{ MESSAGE : @{ DATA : dataDict } };
}

- (void)handleResponseMessageData:(NSDictionary *)dataDict withCompletition:(CompletionBlock)completitionBlock{
    
    /* save presence */
    NSString *responseQliqId = [dataDict objectForKey:QLIQ_ID];
    Presence * presence = [[Presence alloc] init];
    QliqUser *thisUser = [[QliqUserDBService sharedService] getUserWithId:responseQliqId];
    if (thisUser == nil) {
        DDLogSupport(@"Cannot find QliqUser for presence response qliq id: '%@'", responseQliqId);
        return;
    }
    
    thisUser.presenceMessage = [dataDict objectForKey:PRESENCE_MESSAGE];
    // Sometimes server does not send presence_message. That is causing the app to crach because we cannot insert nil
    // into dictionary
    //
    if (thisUser.presenceMessage == nil)
        thisUser.presenceMessage = @"";
        
    thisUser.presenceStatus = [QliqUser presenceStatusFromString: [dataDict objectForKey:PRESENCE_STATUS]];
    thisUser.forwardingQliqId = [dataDict objectForKey:FORWARDING_QLIQ_ID];
    [[QliqUserDBService sharedService] saveUser:thisUser];
    
    presence.presenceType = [dataDict objectForKey:PRESENCE_STATUS];
    presence.message = [dataDict objectForKey:PRESENCE_MESSAGE];
    presence.forwardingUser = [[QliqUserDBService sharedService] getUserWithId:[dataDict objectForKey:FORWARDING_QLIQ_ID]];
    
    [appDelegate.network.presences setPresence:presence forUser:thisUser];
    
    BOOL isForMyself = NO;
    /* if got presence for current user - change presence in UserSettings */
    if ([thisUser.qliqId isEqualToString:[UserSessionService currentUserSession].user.qliqId]){
        isForMyself = YES;
        QliqUser *myUser = [UserSessionService currentUserSession].user;
        myUser.presenceStatus = thisUser.presenceStatus;
        myUser.presenceMessage = thisUser.presenceMessage;
        myUser.forwardingQliqId = thisUser.forwardingQliqId;
        PresenceSettings * presenceSettings = [UserSessionService currentUserSession].userSettings.presenceSettings;
        
        presenceSettings.prevPresenceType = presenceSettings.currentPresenceType;
        presenceSettings.currentPresenceType = presence.presenceType;
        
        Presence * presenceInSettings = [presenceSettings presenceForType:presence.presenceType];
        presenceInSettings.message = presence.message;
        presenceInSettings.forwardingUser = presence.forwardingUser;
        
        [[UserSessionService currentUserSession].userSettings write];
        
        // Krishna 5/21/2018
        // Send this notification only when the presence status is for myself.
        //
        [NSNotificationCenter postNotificationToMainThread:kRescheduleChimeNotifications];
    }
    
    // Update Presence Status Indicator for Me as well as to My contacts in the UI
    //
    [NSNotificationCenter postNotificationToMainThread:PresenceChangeStatusNotification userInfo:@{
                                                                                                   @"qliqId": responseQliqId,
                                                                                                   @"presenceStatus": [NSNumber numberWithInt:thisUser.presenceStatus],
                                                                                                   @"presenceMessage": thisUser.presenceMessage,
                                                                                                   @"isForMyself": [NSNumber numberWithBool:isForMyself]
                                                                                                   }];
    
    if (completitionBlock) 
        completitionBlock(CompletitionStatusSuccess, nil, nil);
}

+ (void) handlePayload:(NSDictionary *)payloadDict
{
    GetPresenceStatusService *service = [[GetPresenceStatusService alloc] init];
    [service handleResponseMessageData:payloadDict withCompletition:nil];
}

@end

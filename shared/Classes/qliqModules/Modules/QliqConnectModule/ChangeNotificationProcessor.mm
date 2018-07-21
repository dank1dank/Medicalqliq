//
//  ChangeNotificationProcessor.m
//  qliq
//
//  Created by Adam Sowa on 11/15/17.
//

#import "ChangeNotificationProcessor.h"
#import "JSONKit.h"
#import "QliqSipMessage.h"
#import "ChangeNotificationSchema.h"
#import "GetPresenceStatusService.h"
#import "GetContactInfoService.h"
#import "QliqUserDBService.h"
#import "QxPlatfromIOSHelpers.h"
#import "Helper.h"
#import "UIDevice+UUID.h"
#import "KeychainService.h"
#import "Crypto.h"
#import "QliqSip.h"
#import "Login.h"
#import "GetMultiPartyService.h"
#import "SipContactDBService.h"
#import "ConversationDBService.h"
#import "QliqConnectModule.h"
#import "RecipientsDBService.h"
#import "NotificationUtils.h"
#import "GetSecuritySettingsService.h"
#import "GetQuickMessagesService.h"
#import "GetOnCallGroupService.h"
#import "GetAllOnCallGroupsService.h"
#import "UploadToQliqStorService.h"
#import "ReportIncidentService.h"
#include "qxlib/controller/QxChangeNotificationProcessor.hpp"
#import "AlertController.h"

class MyChangeNotificationListener : public qx::ChangeNotificationListener
{
public:
    MyChangeNotificationListener(ChangeNotificationProcessor *processor) :
        processor(processor)
    {
    }
    
    bool onChangeNotificationReceived(int databaseId,
                                      const std::string& subject,
                                      const std::string& qliqId,
                                      const std::string& data) override
    {
        return [processor onChangeNotificationReceived:databaseId
                                               subject:qx::toNSString(subject)
                                                qliqId:qx::toNSString(qliqId)
                                                  data:qx::toNSString(data)];
    }
    
private:
    ChangeNotificationProcessor *processor;
};

@interface ChangeNotificationProcessor()
{
    qx::ChangeNotificationProcessor cppProcessor;
    MyChangeNotificationListener *cppListener;
}

- (void) processUserChangeNotification:(int)databaseId qliqId:(NSString *)qliqId;
- (void) processPresenceChangeNotification:(int)databaseId qliqId:(NSString *)qliqId data:(NSDictionary *)dataDict;
- (void) processGroupChangeNotification:(int)databaseId qliqId:(NSString *)qliqId;
- (void) processDeviceChangeNotification:(int)databaseId uuid:(NSString *)uuid;
- (void) processLoginCredentialsNotification:(int)databaseId qliqId:(NSString *)qliqId email:(NSString *)email pubkeyMd5:(NSString *)pubkeyMd5 reason:(NSString *)reason;
- (void) processLogoutChangeNotification:(int)databaseId;
- (void) processMultiPartyChangeNotification:(int)databaseId qliqId:(NSString *)qliqId;
- (void) logoutUserWithAlert:(NSString *)msg;
- (void) processConversationChangeNotification:(int)databaseId data:(NSDictionary *)dataDict;
- (void) processSyncConversationsChangeNotification:(int)databaseId;
- (void) processSecuritySettingsNotification:(int)databaseId deviceUuid:(NSString *)deviceUuid;
- (void) processQuickMessagesChangeNotification:(int)databaseId qliqId:(NSString *)qliqId;
- (void) processSingleOnCallGroupChangeNotificationFor:(int)databaseId qliqId:(NSString *)qliqId;
- (void) processSyncOnCallGroupsChangeNotification:(int)databaseId qliqId:(NSString *)qliqId;
- (void) processQliqStorUploadStatusChangeNotification:(int)databaseId subject:(NSString *)subject data:(NSDictionary *)dataDict;
- (void) processSyncContactsChangeNotification:(int)databaseId;
- (void) processInvitationRequest:(int)databaseId data:(NSDictionary *)invitationRequest;
- (void) processInvitationResponse:(int)databaseId data:(NSDictionary *)invitationResponse;
- (void) onProcessingFinished:(int)databaseId error:(NSError *)error;
- (void) processPlRequest:(NSDictionary *)dataDict;

@end

@implementation ChangeNotificationProcessor

- (id) init
{
    self = [super init];
    if (self) {
        std::string deviceUuid = qx::toStdString([[UIDevice currentDevice] qliqUUID]);
        cppProcessor.setDeviceUuid(deviceUuid);
        
        cppListener = new MyChangeNotificationListener(self);
        cppProcessor.setListener(cppListener);
    }
    return self;
}

- (void) dealloc
{
    delete cppListener;
}

- (BOOL) handleSipMessage:(QliqSipMessage *)message
{
    if (([message.command isEqualToString:CHANGE_NOTIFICATION_MESSAGE_COMMAND_PATTERN] &&
         [message.type isEqualToString:CHANGE_NOTIFICATION_MESSAGE_TYPE_PATTERN]) ||
        [message.command isEqualToString:BULK_CHANGE_NOTIFICATION_MESSAGE_COMMAND_PATTERN]) {
        
        NSDictionary *dict = @{
           @"Type": message.type,
           @"Command": message.command,
           @"Subject": message.subject,
           @"Data": message.data
        };
        NSString *json = [dict JSONString];
        cppProcessor.onSipMessage(qx::toStdString(json));
        return YES;
    } else if ([message.command isEqualToString:@"pl-request"]) {
        [self processPlRequest:message.data];
        return YES;
    } else {
        return NO;
    }
}

- (BOOL) onChangeNotificationReceived:(int)databaseId subject:(NSString *)subject qliqId:(NSString *)qliqId data:(NSString *)dataString
{
    BOOL ret = YES;
    NSError *error = nil;
    NSData *jsonData = [dataString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dataDict = [[JSONDecoder decoder] objectWithData:jsonData error:&error];
    AppDelegate *appDelegate = (AppDelegate*) [UIApplication sharedApplication].delegate;
   
    if ([subject isEqualToString:@"user"]) {
        [self processUserChangeNotification:databaseId qliqId:qliqId];
    } else if ([subject isEqualToString:@"group"]) {
        [self processGroupChangeNotification:databaseId qliqId:qliqId];
    } else if ([subject isEqualToString:@"presence"]) {
        [self processPresenceChangeNotification:databaseId qliqId:qliqId data:dataDict];
    } else if ([subject isEqualToString:@"device"]) {
        NSString *uuid = [dataDict objectForKey:@"device_uuid"];
        [self processDeviceChangeNotification:databaseId uuid:uuid];
    } else if ([subject isEqualToString:@"login_credentials"]) {
        NSString *email = [dataDict objectForKey:@"email"];
        NSString *pubkeyMd5 = [dataDict objectForKey:@"pubkey_md5"];
        NSString *reason = [dataDict objectForKey:@"reason"];
        [self processLoginCredentialsNotification:databaseId qliqId:qliqId email:email pubkeyMd5:pubkeyMd5 reason:reason];
    } else if ([subject isEqualToString:@"logout"]) {
        [self processLogoutChangeNotification:databaseId];
    } else if ([subject isEqualToString:@"multiparty"]) {
        [self processMultiPartyChangeNotification:databaseId qliqId:qliqId];
    } else if ([subject isEqualToString:@"conversation"]) {
        [self processConversationChangeNotification:databaseId data:dataDict];
    } else if ([subject isEqualToString:@"sync_conversations"]) {
        [self processSyncConversationsChangeNotification:databaseId];
    } else if ([subject isEqualToString:@"security_settings"]) {
        NSString *deviceUuid = [[UIDevice currentDevice] qliqUUID];
        [self processSecuritySettingsNotification:databaseId deviceUuid:deviceUuid];
    } else if ([subject isEqualToString:@"quick_messages"]) {
        [self processQuickMessagesChangeNotification:databaseId qliqId:qliqId];
    } else if ([subject isEqualToString:@"oncall_group"] || [subject isEqualToString:@"oncall_note_update"]) {
        [self processSingleOnCallGroupChangeNotificationFor:databaseId qliqId:qliqId];
    } else if ([subject isEqualToString:@"sync_oncall_groups"]) {
        [self processSyncOnCallGroupsChangeNotification:databaseId qliqId:qliqId];
    } else if ([subject isEqualToString:@"qliqstor-upload-status"]) {
        [self processQliqStorUploadStatusChangeNotification:databaseId subject:subject data:dataDict];
    } else if ([subject isEqualToString:@"sync_contacts"]) {
        [self processSyncContactsChangeNotification:databaseId];
    } else if ([subject isEqualToString:@"invitation-request"]) {
        [self processInvitationRequest:databaseId data:dataDict];
    } else if ([subject isEqualToString:@"invitation-response"]) {
        [self processInvitationResponse:databaseId data:dataDict];
    } else {
        ret = NO;
    }
    
    return ret;
}

- (void) processUserChangeNotification:(int)databaseId qliqId:(NSString *)qliqId
{
    if ([[Helper getMyQliqId] isEqualToString:qliqId]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            [[GetUserConfigService sharedService] getUserConfig:YES withCompletitionBlock:^(CompletitionStatus status, id result, NSError *error) {
                 if (status == CompletitionStatusSuccess) {
                     NSDictionary  *dict = (NSDictionary *)result;
                     BOOL hasSipServerFqdnChanged = [[dict objectForKey:SipServerFqdnChangedKey] boolValue];
                     BOOL hasSipServerConfigChanged = [[dict objectForKey:SipServerConfigChangedKey] boolValue];
                     
                     if (hasSipServerFqdnChanged || hasSipServerConfigChanged) {
                         DDLogSupport(@"SIP server config change detected (change notification) trying to restart SIP");
                         [[QliqSip sharedQliqSip] handleNetworkUp];
                     }
                 }
                 [self onProcessingFinished:databaseId error:error];
             }];
        });
    }
    else {
        [[GetContactInfoService sharedService] getContactInfo: qliqId completitionBlock:^(QliqUser *contact, NSError *error) {
            [self onProcessingFinished:databaseId error:error];
        }];
    }
}

- (void) processPresenceChangeNotification:(int)databaseId qliqId:(NSString *)qliqId data:(NSDictionary *)dataDict
{
    QliqUser *user = [[QliqUserDBService sharedService] getUserWithId:qliqId];
    if (user) {
        NSDictionary *payloadDict = dataDict[@"payload"];
        if (payloadDict) {
            [GetPresenceStatusService handlePayload:payloadDict];
            cppProcessor.onProcessingFinished(databaseId, 0);
        } else {
            GetPresenceStatusService *getPresence = [[GetPresenceStatusService alloc] initWithQliqId: qliqId];
            [getPresence callServiceWithCompletition:^(CompletitionStatus status, id result, NSError *error) {
                [self onProcessingFinished:databaseId error:error];
            }];
        }
    } else {
        [[GetContactInfoService sharedService] getContactInfo: qliqId completitionBlock:^(QliqUser *contact, NSError *error) {
            [self onProcessingFinished:databaseId error:error];
        }];
    }
}

- (void) processGroupChangeNotification:(int)databaseId qliqId:(NSString *)qliqId
{
    // per Krishna's request now we call get_user_config instead of get_group_info
    // If there are any new groups found when doing get_user_config, get contacts from them
    //
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [[GetUserConfigService sharedService] getUserConfig:YES withCompletitionBlock:^(CompletitionStatus status, id result, NSError *error) {
            [self onProcessingFinished:databaseId error:error];
        }];
    });
    //    [[GetGroupInfoService sharedService] getGroupInfo:qliqId withCompletion:^(QliqGroup *group, NSError *error) {
    //
    //    }];
}

- (void) processDeviceChangeNotification:(int)databaseId uuid:(NSString *)uuid
{
    if ([[[UIDevice currentDevice] qliqUUID] isEqualToString:uuid]) {
        [appDelegate.currentDeviceStatusController refreshRemoteStatusWithCompletition:^(CompletitionStatus status, id result, NSError *error) {
            if ([appDelegate.currentDeviceStatusController isLocked] || [appDelegate.currentDeviceStatusController isWiped]) {
                // Pause further CN processing
                cppProcessor.setDontLoadNextFromDatabase(true, "Device is locked or wiped");
            }
            [self onProcessingFinished:databaseId error:error];
        }];
    } else {
        DDLogError(@"Received change-notification for a different device: %@", uuid);
        cppProcessor.onProcessingFinished(databaseId, 0);
    }
}

- (void) processLoginCredentialsNotification:(int)databaseId qliqId:(NSString *)qliqId email:(NSString *)email pubkeyMd5:(NSString *)pubkeyMd5 reason:(NSString *)reason
{
    if (![QliqStorage sharedInstance].failedToDecryptPushPayload && ![QliqStorage sharedInstance].wasLoginCredentintialsChanged && [QliqSip haveCredentialsChanged:qliqId email:email pubkeyMd5:pubkeyMd5])
    {
        DDLogSupport(@"Logging out");
        /*Clear login credentials and logout*/
        [[KeychainService sharedService] clearPin];
        [[KeychainService sharedService] clearPassword];
        // We don't erase API key, because we want to allow logout service or other to auth using the exising key
        // The key will be refreshed during subsequent login
        //[[KeychainService sharedService] clearApiKey];
        // Email may be different now
        [[KeychainService sharedService] saveUsername:email];
        // Old keys are invalid
        [[Crypto instance] deleteKeysForUser: [UserSessionService currentUserSession].sipAccountSettings.username];
        // Clear last login date, so we don't do local login next time
        [UserSessionService clearLastLoginDate];
        
        if (reason) {
            
            if ([reason isEqualToString:@"Change Email"]){
                reason = QliqLocalizedString(@"1170-TextAutoLoggedOutBecauseEmailChanged");
            }
            else if ([reason isEqualToString:@"Change Password"]){
                reason = QliqLocalizedString(@"3042-TextAutoLoggedOutBecausePasswordChanged");
            }
            else{
                reason = QliqFormatLocalizedString1(@"3043-TextAutoLoggedOutBecauseNotValidReason{reason}", reason);
            }
        }
        else {
            reason = QliqLocalizedString(@"1171-TextAutoLoggedOutBecausePasswordOrEmailChanged");
        }
        [self logoutUserWithAlert:reason];
        cppProcessor.setDontLoadNextFromDatabase(true, "Login credentials changed");
    }
    cppProcessor.onProcessingFinished(databaseId, 0);
}

- (void) processLogoutChangeNotification:(int)databaseId
{
    [self logoutUserWithAlert:NSLocalizedString(@"1172-TextForceLoggedOutByAdministrator", nil)];
    cppProcessor.setDontLoadNextFromDatabase(true, "User is logged out");
    cppProcessor.onProcessingFinished(databaseId, 0);
}

- (void) logoutUserWithAlert:(NSString *)msg
{
    [[Login sharedService] startLogoutWithCompletition:^{
        
        [AlertController showAlertWithTitle:nil
                                    message:msg
                                buttonTitle:nil
                          cancelButtonTitle:NSLocalizedString(@"1-ButtonOK", nil)
                                 completion:NULL];
    }];
}

- (void) processMultiPartyChangeNotification:(int)databaseId qliqId:(NSString *)qliqId
{
    if ([GetMultiPartyService hasOutstandingRequestForMultipartyQliqId:qliqId]) {
        cppProcessor.onProcessingFinished(databaseId, 0);
    } else {
        GetMultiPartyService *getMp = [[GetMultiPartyService alloc] initWithQliqId: qliqId];
        [getMp callServiceWithCompletition:^(CompletitionStatus status, id result, NSError *error) {
            
            if (status == CompletitionStatusSuccess)
            {
                SipContactDBService * sipContactService = [[SipContactDBService alloc] init];
                SipContact *contact = [sipContactService sipContactForQliqId:qliqId];
                
                if ([contact.qliqId length] > 0) {
                    // Now we have the contact
                    // 3. Notify UI about participants change (will work for CN)
                    [QliqConnectModule notifyMultipartyWithQliqId:qliqId];
                } else {
                    DDLogError(@"GetMultiPartyService finished with sucess but cannot retrieve contact for qliq id: %@", qliqId);
                }
            }
            else
            {
                if (error)
                {
                    [getMp handleError:error];
                    DDLogError(@"ERROR: GetMultiPartyService - %@", [error localizedDescription]);
                    if (error.code == 105)
                    {
                        NSArray *convs = [[ConversationDBService sharedService] getConversationsWithQliqId:qliqId];
                        if (convs.count > 0)
                        {
                            Conversation *conversation = convs.firstObject;
                            [[[RecipientsDBService alloc] init] removeSelfUserFromRecipients:conversation.recipients];
                            //                            conversation.deleted = YES;
                            [[ConversationDBService sharedService] saveConversation:conversation];
                            [NSNotificationCenter postNotificationToMainThread:RecipientsChangedNotification withObject:conversation userInfo:nil];
                        }
                        else
                        {
                            DDLogError(@"No conversations for qliq ID: %@", qliqId);
                        }
                    }
                }
            }
            
            [self onProcessingFinished:databaseId error:error];
        }];
    }
}

- (void) processConversationChangeNotification:(int)databaseId data:(NSDictionary *)dataDict
{
    NSDictionary *payloadDict = dataDict[@"payload"];
    if (payloadDict) {
        NSString *uuid = payloadDict[@"conversation_uuid"];
        if (uuid && uuid.length > 0) {
            BOOL muted = [payloadDict[@"muted"] boolValue];
            [QliqConnectModule setConversationMuted:0 withUuid:uuid withMuted:muted withCallWebService:NO];
        }
    }
    cppProcessor.onProcessingFinished(databaseId, 0);
}

- (void) processSyncConversationsChangeNotification:(int)databaseId
{
    [[QliqSip sharedQliqSip] setRegistered:NO];
    [[QliqSip sharedQliqSip] setRegistered:YES];
    cppProcessor.onProcessingFinished(databaseId, 0);
}

- (void) processSecuritySettingsNotification:(int)databaseId deviceUuid:(NSString *)deviceUuid
{
    GetSecuritySettingsService *geSecuritySettings = [[GetSecuritySettingsService alloc] initWithDeviceUuid:deviceUuid];
    [geSecuritySettings callServiceWithCompletition:^(CompletitionStatus status, id result, NSError *error) {
        
        if ([result isKindOfClass:[SecuritySettings class]]) {
            // Refresh user's settings
            UserSettings *userSettings = [UserSessionService currentUserSession].userSettings;
            userSettings.securitySettings = result;
            // Save to permanent storage (for local login)
            [userSettings write];
            
            [appDelegate configureInactivityLock];
        }
        //if we need to raise an alert, we do here
        //[NSNotificationCenter postNotificationToMainThread:@"<......>" withObject:nil userInfo:nil andWait:YES];
        [self onProcessingFinished:databaseId error:error];
    }];
}

- (void) processQuickMessagesChangeNotification:(int)databaseId qliqId:(NSString *)qliqId
{
    GetQuickMessagesService *getQuickMessages = [[GetQuickMessagesService alloc] initWithQliqId: qliqId];
    [getQuickMessages callServiceWithCompletition:^(CompletitionStatus status, id result, NSError *error) {
        [self onProcessingFinished:databaseId error:error];
    }];
}

- (void) processSingleOnCallGroupChangeNotificationFor:(int)databaseId qliqId:(NSString *)qliqId
{
    if (qliqId.length > 0) {
        [[[GetOnCallGroupService alloc] init] get:qliqId reason:ChangeNotificationRequestReason withCompletionBlock:^(CompletitionStatus status, id result, NSError *error) {
            [self onProcessingFinished:databaseId error:error];
        }];
    } else {
        DDLogError(@"Trying to update on_call group with nil qliqId");
        cppProcessor.onProcessingFinished(databaseId, 0);
    }
}

- (void) processSyncOnCallGroupsChangeNotification:(int)databaseId qliqId:(NSString *)qliqId
{
    [[[GetAllOnCallGroupsService alloc] init] getWithCompletionBlock:^(CompletitionStatus status, id result, NSError *error) {
        [self onProcessingFinished:databaseId error:error];
    }];
}

- (void) processQliqStorUploadStatusChangeNotification:(int)databaseId subject:(NSString *)subject data:(NSDictionary *)dataDict
{
    NSDictionary *payloadDict = dataDict[@"payload"];
    if (payloadDict) {
        [UploadToQliqStorService processChangeNotification:subject payload:[payloadDict JSONString]];
    }
    cppProcessor.onProcessingFinished(databaseId, 0);
}

- (void) processSyncContactsChangeNotification:(int)databaseId
{
    [QliqConnectModule syncContacts:NO];
    // TODO: this is simplification, we don't have completion block that is invoked
    // after the sync contacts process is actually completed.
    cppProcessor.onProcessingFinished(databaseId, 0);
}

- (void) processInvitationResponse:(int)databaseId data:(NSDictionary *)invitationResponse
{
    [QliqConnectModule processInvitationResponse:invitationResponse];
    cppProcessor.onProcessingFinished(databaseId, 0);
}

- (void) processInvitationRequest:(int)databaseId data:(NSDictionary *)invitationRequest
{
    [QliqConnectModule processInvitationRequest:invitationRequest completitionBlock:^(QliqUser *contact, NSError *error) {
        [self onProcessingFinished:databaseId error:error];
    }];
}

- (void) onProcessingFinished:(int)databaseId error:(NSError *)error
{
    int code = 0;
    if (error) {
        code = (int)error.code;
        if (![error.domain isEqualToString:@"NSURLErrorDomain"]) {
            DDLogError(@"Unexpected error domain: %@ code: %ld (assuming JSON Message.Error)", error.domain, (long)error.code);
            // This must be JSON or app level error, in any case it is not network error
            // so we consider this request finished
            code = 0;
        }
    }
    cppProcessor.onProcessingFinished(databaseId, code);
}

- (void) processPlRequest:(NSDictionary *)dataDict
{
    NSString *uuid = dataDict[@"device_uuid"];
    BOOL attachDatabase = [dataDict[@"attach_database"] boolValue];
    // TODO: not implemenented on webserver
    NSNumber *attachLogDatabase = dataDict[@"attach_log_database"];
    if (attachLogDatabase == nil) {
        attachLogDatabase = [NSNumber numberWithBool:YES];
    }
    NSString *myUuid = [[UIDevice currentDevice] qliqUUID];
    
    if ([uuid length] == 0 || [myUuid isEqualToString:uuid]) {
        DDLogSupport(@"Received pl-request, device uuid: %@, attach database: %d", uuid, (int)attachDatabase);
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
           QliqAPIService *service = [[ReportIncidentService alloc] initWithDefaultFilesAndDatabase:attachDatabase
                                                                                     andLogDatabase:[attachLogDatabase boolValue]
                                                                                         andMessage:@"Pulled iOS Logs"
                                                                                         andSubject:@"Pulled iOS Logs"
                                                                                       isNotifyUser:NO];
            [service callServiceWithCompletition:^(CompletitionStatus status, id result, NSError *error) {
                DDLogSupport(@"Report error sending finished with status: %d, error: %@", status, error);
            }];
        });
    } else {
        DDLogError(@"Received pl-request for a different device: %@ (my device: %@)", uuid, myUuid);
    }
}

@end

//
//  SendMessageToNonQliqUserService.m
//  qliq
//
//  Created by Adam Sowa on 31/12/15.
//
//

#import "SendMessageToNonQliqUserService.h"
#import "QliqJsonSchemaHeader.h"
#import "UIDevice+UUID.h"
#import "RestClient.h"
#import "JSONKit.h"
#import "Metadata.h"
#import "InvitationAPIService.h"

@interface SendMessageToNonQliqUserService()

@property (nonatomic, strong) NSString *conversationUuid;
@property (nonatomic, strong) NSString *messageUuid;
@property (nonatomic, strong) NSMutableDictionary *contentDict;

@end

@implementation SendMessageToNonQliqUserService

- (id)initWithEmail:(NSString *)email orMobile:(NSString *)mobile withSubject:(NSString *)subject message:(NSString *)message
{
    self = [super init];
    if (self) {
        NSString *username = [UserSessionService currentUserSession].sipAccountSettings.username;
        NSString *password = [UserSessionService currentUserSession].sipAccountSettings.password;
        NSString *deviceUUID = [[UIDevice currentDevice] qliqUUID];
        self.conversationUuid = [Metadata generateUuid];
        self.messageUuid = [Metadata generateUuid];
        
        NSMutableDictionary *recipientDetailsDicts = [[NSMutableDictionary alloc] init];
        if (email.length > 0) {
            [recipientDetailsDicts setObject:email forKey:EMAIL];
        }
        if (mobile.length > 0) {
            [recipientDetailsDicts setObject:mobile forKey:MOBILE];
        }
        
        self.contentDict = [[NSMutableDictionary alloc] init];
        [self.contentDict setObject:username forKey:USERNAME];
        [self.contentDict setObject:password forKey:PASSWORD];
        [self.contentDict setObject:deviceUUID forKey:DEVICE_UUID];
        [self.contentDict setObject:recipientDetailsDicts forKey:RECIPIENT_DETAILS];
        [self.contentDict setObject:message forKey:@"body"];
        [self.contentDict setObject:[NSNumber numberWithBool:YES] forKey:@"notify_recipient"];
        [self.contentDict setObject:self.conversationUuid forKey:CONVERSATION_ID];
        [self.contentDict setObject:self.messageUuid forKey:CALL_ID];
        
        if (subject.length > 0) {
            [self.contentDict setObject:subject forKey:SUBJECT];
        }
        
    }
    return self;
}

#pragma mark - Private

- (NSString *)serviceName {
    return @"services/qliq_message_to_nonqliq_user";
}

- (NSDictionary *)requestJson {
    return @{MESSAGE : @{DATA : self.contentDict}};
}

- (void)handleResponseMessageData:(NSDictionary *)dataDict withCompletition:(CompletionBlock)completitionBlock {
    
    NSDictionary *recipientDetailsDict = [self.contentDict objectForKey:RECIPIENT_DETAILS];
    Contact *contact = [[Contact alloc] init];
    contact.email = [recipientDetailsDict objectForKey:EMAIL];
    contact.mobile = [recipientDetailsDict objectForKey:MOBILE];
    
    QliqUser *user = [InvitationAPIService createAndSaveInvitatedUserFromDict:dataDict andContact:contact];
    
    NSDictionary *result = @{QLIQ_USER : user, CONVERSATION_ID : self.conversationUuid, CALL_ID : self.messageUuid};
    if (completitionBlock) {
        completitionBlock(CompletitionStatusSuccess, result, nil);
    }
}

@end

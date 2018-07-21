//
//  SendMessageToNonQliqUserService.m
//  qliq
//
//  Created by Adam Sowa on 31/12/15.
//
//

#import "ModifyConversationStatusService.h"
#import "QliqJsonSchemaHeader.h"
#import "UIDevice+UUID.h"
#import "RestClient.h"
#import "JSONKit.h"

@interface ModifyConversationStatusService()

@property (nonatomic, strong) NSString *conversationUuid;
@property (nonatomic, readwrite) BOOL muted;
@property (nonatomic, strong) NSDictionary *contentDict;

@end

@implementation ModifyConversationStatusService

- (id)initWithConversationUuid:(NSString *)conversationUuid withMuted:(BOOL)muted
{
    self = [super init];
    if (self) {
        NSString *username = [UserSessionService currentUserSession].sipAccountSettings.username;
        NSString *password = [UserSessionService currentUserSession].sipAccountSettings.password;
        NSString *deviceUUID = [[UIDevice currentDevice] qliqUUID];
        self.conversationUuid = conversationUuid;
        self.muted = muted;
        
        self.contentDict = @{
            USERNAME: username,
            PASSWORD: password,
            DEVICE_UUID: deviceUUID,
            @"conversations": @[ @{
                    @"conversation_uuid": self.conversationUuid,
                    @"muted": [NSNumber numberWithBool:self.muted]
            } ]
         };
    }
    return self;
}

#pragma mark - Private

- (NSString *)serviceName {
    return @"services/modify_conversations_status";
}

- (NSDictionary *)requestJson {
    return @{MESSAGE : @{DATA : self.contentDict}};
}

- (void)handleResponseMessageData:(NSDictionary *)dataDict withCompletition:(CompletionBlock)completitionBlock {
    
    if (completitionBlock) {
        completitionBlock(CompletitionStatusSuccess, nil, nil);
    }
}

@end

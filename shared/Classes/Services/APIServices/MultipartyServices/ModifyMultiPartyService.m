//
//  ModifyMultiPartyService.m
//  qliq
//
//  Created by Ravi Ada on 11/23/12.
//
//

#import "ModifyMultiPartyService.h"

#import "JSONKit.h"
#import "JSONSchemaValidator.h"
#import "QliqJsonSchemaHeader.h"

#import "DBUtil.h"
#import "KeychainService.h"
#import "RestClient.h"

@interface ModifyMultiPartyService()

@property (nonatomic, strong) Recipients *recipients;
@property (nonatomic, strong) Recipients *modifiedRecipients;

@end

@implementation ModifyMultiPartyService

- (id)initWithRecipients:(Recipients *)recipients modifiedRecipients:(Recipients *)newRecipients
{
    self = [super init];
    if (self) {
        self.recipients = recipients;
        self.modifiedRecipients = newRecipients;
    }
    return self;
}

- (NSString *)serviceName {
    return @"services/modify_multiparty";
}

- (Schema)requestSchema {
    return ModifyMultiPartyRequestSchema;
}

- (Schema)responseSchema {
    return ModifyMultiPartyResponseSchema;
}

- (NSDictionary *)requestJson
{
    NSMutableArray * participants = [[NSMutableArray alloc] init];
    
    /* add participants to 'remove' */
    for (id <Recipient> recipient in [self.recipients allRecipients]){
        if (![self.modifiedRecipients containsRecipient:recipient]){
            [participants addObject:@{ @"qliq_id" : [recipient recipientQliqId], @"operation" : @"remove" }];
        }
    }

    /* add participants to 'add' */
    for (id <Recipient> recipient in [self.modifiedRecipients allRecipients]){
        if (![self.recipients containsRecipient:recipient]) {
            [participants addObject:@{ @"qliq_id" : [recipient recipientQliqId], @"operation" : @"add" }];
        }
    }
    
    UserSession *currentSession = [UserSessionService currentUserSession];
    NSString * username = currentSession.sipAccountSettings.username;
    NSString * password = currentSession.sipAccountSettings.password;
    
    NSDictionary *contentDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                 password, PASSWORD,
                                 username, USERNAME,
                                 self.recipients.qliqId, MULTIPARTY_QLIQ_ID,
                                 self.modifiedRecipients.name, MULTIPARTY_NAME,
                                 participants, PARTICIPANTS,
                                 nil];
    
	NSDictionary *jsonDict = @{ MESSAGE : @{ DATA : contentDict }};
    
    DDLogSupport(@"modify json: %@",jsonDict);
    
    return jsonDict;
}

- (void)handleResponseMessageData:(NSDictionary *)dataDict withCompletition:(CompletionBlock)completitionBlock{
    
    self.modifiedRecipients.qliqId = self.recipients.qliqId;

    if (completitionBlock) {
        completitionBlock(CompletitionStatusSuccess, self.modifiedRecipients, nil);
    }
}

@end

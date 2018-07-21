 //
//  CreateMultiPartyService.m
//  qliq
//
//  Created by Ravi Ada on 11/23/12.
//
//

#import "CreateMultiPartyService.h"
#import "JSONSchemaValidator.h"
#import "QliqJsonSchemaHeader.h"
#import "KeychainService.h"
#import "JSONKit.h"
#import "RestClient.h"
#import "DBUtil.h"

#import "SipContact.h"
#import "SipContactDBService.h"

#import "Recipients.h"
#import "RecipientsDBService.h"

static NSMutableSet *s_outstandingRequestConversationIds = nil;

@interface CreateMultiPartyService()

@property (nonatomic, strong) Recipients * recipients;
@property (nonatomic, assign) NSInteger conversationId;

@end

@implementation CreateMultiPartyService

@synthesize recipients;

- (NSString *) serviceName{
    return @"services/create_multiparty";
}

- (id) initWithRecipients:(Recipients *) _recipients andConversationId:(NSInteger)conversationId
{
    self = [super init];
    if (self){
        self.recipients = _recipients;
        self.conversationId = conversationId;
        
        if (s_outstandingRequestConversationIds == nil) {
            s_outstandingRequestConversationIds = [[NSMutableSet alloc] init];
        }
        
        [self setCompletionBlock:^(void) {
            NSNumber *num = [NSNumber numberWithInteger:conversationId];
            [s_outstandingRequestConversationIds removeObject:num];
        }];
    }
    return self;
}

- (Schema)requestSchema{
    return CreateMultiPartyRequestSchema;
}

- (Schema)responseSchema{
    return CreateMultiPartyResponseSchema;
}

- (NSDictionary *)requestJson{
    
    NSMutableArray * particiapants = [[NSMutableArray alloc] init];
    
    for (id<Recipient> recipient in [self.recipients allRecipients]){
        NSString * qliq_id = [recipient recipientQliqId];
        if (qliq_id){
            [particiapants addObject:@{ @"qliq_id" : qliq_id }];
        }else{
            DDLogError(@"qliq_id nil for recipient: %@",recipient);
        }
    }
    
    UserSession *currentSession = [UserSessionService currentUserSession];
    
	NSMutableDictionary * dataDict = [[NSMutableDictionary alloc] init];
    dataDict[PASSWORD]     = currentSession.sipAccountSettings.password;
    dataDict[USERNAME]     = currentSession.sipAccountSettings.username;
    dataDict[PARTICIPANTS] = particiapants;
    
    if (self.recipients.name)
        dataDict[MULTIPARTY_NAME] = self.recipients.name;
    
    dataDict[MULTIPARTY_PERSONAL_GROUP] = [NSNumber numberWithBool:self.recipients.isPersonalGroup];
    
    NSNumber *number = [NSNumber numberWithInteger:self.conversationId];
    [s_outstandingRequestConversationIds addObject:number];
    
    return @{ MESSAGE : @{ DATA : dataDict } };
}

- (void)handleResponseMessageData:(NSDictionary *)dataDict withCompletition:(CompletionBlock)completitionBlock
{
    NSString * mpQliqId = [dataDict objectForKey:QLIQ_ID];
    
    SipContactDBService * sipDBService = [[SipContactDBService alloc] init];
    [sipDBService saveSipContactFromMPResponseDict:dataDict];
    
    RecipientsDBService * recipientsDBService = [[RecipientsDBService alloc] init];
    self.recipients.qliqId = mpQliqId;
    self.recipients.name = [dataDict objectForKey:NAME];
    
    id<Recipient> myRecipient = [UserSessionService currentUserSession].user;
    if (![recipients containsRecipient:myRecipient]) {
        [recipients addRecipient:myRecipient];
    }

    
    [recipientsDBService save:self.recipients completion:nil];

    NSNumber *number = [NSNumber numberWithInteger:self.conversationId];
    [s_outstandingRequestConversationIds removeObject:number];
    
    if (completitionBlock) {
        completitionBlock(CompletitionStatusSuccess, mpQliqId, nil);
    }
}

- (void) handleError:(NSError*) error
{
    NSNumber *number = [NSNumber numberWithInteger:self.conversationId];
    [s_outstandingRequestConversationIds removeObject:number];
}

+ (BOOL) hasOutstandingRequestForConversationId:(NSInteger)conversationId
{
    NSNumber *number = [NSNumber numberWithInteger:conversationId];
    return [s_outstandingRequestConversationIds containsObject:number];
}

@end

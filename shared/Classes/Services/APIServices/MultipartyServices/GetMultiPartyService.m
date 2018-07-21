//
//  GetMultiPartyService.m
//  qliq
//
//  Created by Ravi Ada on 11/23/12.
//
//

#import "GetMultiPartyService.h"
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
#import "QliqUserDBService.h"
#import "GetContactInfoService.h"
#import "Log.h"
#import "QliqConnectModule.h"

static NSMutableSet *s_outstandingRequestMultipartyQliqId = nil;

@interface GetMultiPartyService()

@property (nonatomic, strong) NSString * multiPartyQliqId;

@end

@implementation GetMultiPartyService

@synthesize multiPartyQliqId;

- (NSString *) serviceName{
    return @"services/get_multiparty";
}

- (id) initWithQliqId:(NSString *) _multiPartyQliqId
{
    self = [super init];
    if (self) {
        self.multiPartyQliqId = _multiPartyQliqId;
        
        if (s_outstandingRequestMultipartyQliqId == nil) {
            s_outstandingRequestMultipartyQliqId = [[NSMutableSet alloc] init];
        }
    }
    return self;
}

- (Schema)requestSchema{
    return GetMultiPartyRequestSchema;
}

- (Schema)responseSchema{
    return GetMultiPartyResponseSchema;
}

- (NSDictionary *)requestJson{
    
    UserSession * currentSession = [UserSessionService currentUserSession];
    
	NSMutableDictionary * dataDict = [[NSMutableDictionary alloc] init];
    dataDict[USERNAME] = currentSession.sipAccountSettings.username;
    dataDict[PASSWORD] = currentSession.sipAccountSettings.password;
    dataDict[MULTIPARTY_QLIQ_ID] = self.multiPartyQliqId;

    [s_outstandingRequestMultipartyQliqId addObject:self.multiPartyQliqId];
    
    return @{ MESSAGE : @{ DATA : dataDict } };
    
}

- (void)handleResponseMessageData:(NSDictionary *)dataDict withCompletition:(CompletionBlock)completitionBlock{

    SipContactDBService * sipDBService = [[SipContactDBService alloc] init];
    [sipDBService saveSipContactFromMPResponseDict:dataDict];
    
    RecipientsDBService * recipientsDBService = [[RecipientsDBService alloc] init];
    [recipientsDBService saveRecipientsFromMPResponseDict:dataDict];
    
    NSArray *participants = [dataDict objectForKey:PARTICIPANTS];
    [participants enumerateObjectsUsingBlock:^(NSDictionary * partipant, NSUInteger idx, BOOL *stop) {
        NSString *qliqId = [partipant objectForKey:@"qliq_id"];
        SipContact *user = [[SipContactDBService sharedService] sipContactForQliqId:qliqId];
        if ([user sipUri].length == 0) {
            DDLogError(@"MP has unknown participant, will call get_contact_info for: %@", qliqId);
            [[GetContactInfoService sharedService] getContactInfo:qliqId completitionBlock:^(QliqUser *contact, NSError *error) {
                if (!error) {
                    // Save the recipients again now with the just downloaded user
                    [recipientsDBService saveRecipientsFromMPResponseDict:dataDict];
                    // Refresh UI with new participant
                    NSString *multipartyQliqId = [dataDict objectForKey:QLIQ_ID];
                    [QliqConnectModule notifyMultipartyWithQliqId:multipartyQliqId];
                }
            }];
        }
    }];
    
    if (completitionBlock)
        completitionBlock(CompletitionStatusSuccess, nil, nil);
    
    [s_outstandingRequestMultipartyQliqId removeObject:self.multiPartyQliqId];
}

- (void) handleError:(NSError*) error
{
    [s_outstandingRequestMultipartyQliqId removeObject:self.multiPartyQliqId];
}

+ (BOOL) hasOutstandingRequestForMultipartyQliqId:(NSString *)qliqId
{
    return [s_outstandingRequestMultipartyQliqId containsObject:qliqId];
}

@end

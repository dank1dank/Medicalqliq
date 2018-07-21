//
//  SetPresenceStatusService.m
//  qliq
//
//  Created by Ravi Ada on 11/23/12.
//
//

#import "SetPresenceStatusService.h"
#import "JSONSchemaValidator.h"
#import "QliqJsonSchemaHeader.h"
#import "KeychainService.h"
#import "JSONKit.h"
#import "RestClient.h"
#import "Presence.h"

@interface SetPresenceStatusService()

@property (nonatomic, strong) NSString * presenceStatus;
@property (nonatomic, strong) NSString * presenceMessage;
@property (nonatomic, strong) NSString * forwardToQliqId;

@end

@implementation SetPresenceStatusService

@synthesize presenceStatus, presenceMessage, forwardToQliqId;

- (NSString *) serviceName{
    return @"services/set_presence_status";
}

- (id) initWithPresence:(Presence *) presence ofType:(NSString *)presenceType{
    
    self = [super init];
    if (self) {
        self.presenceMessage = presence.message;
        self.presenceStatus = presenceType;
        self.forwardToQliqId = [presence.forwardingUser recipientQliqId];
        
        if (!self.presenceMessage) self.presenceMessage = @"";
        
    }
    return self;
}

- (id) initWithPresence:(QliqUser *) user
{
    self = [super init];
    if (self) {
        self.presenceMessage = user.presenceMessage;
        self.presenceStatus = [QliqUser presenceStatusToString:user.presenceStatus];
        self.forwardToQliqId = user.forwardingQliqId;
        
        if (!self.presenceMessage) self.presenceMessage = @"";
    }
    return self;
}


- (Schema)requestSchema{
    return SetPresenceStatusRequestSchema;
}

- (Schema)responseSchema{
    return SetPresenceStatusResponseSchema;
}

- (NSDictionary *)requestJson{
    
    UserSession *currentSession = [UserSessionService currentUserSession];
    NSString * username = currentSession.sipAccountSettings.username;
    NSString * password = currentSession.sipAccountSettings.password;
    
    
	NSDictionary *contentDict = [NSDictionary dictionaryWithObjectsAndKeys:
								 password, PASSWORD,
								 username, USERNAME,
								 self.presenceStatus, STATUS,
								 self.presenceMessage, MESSAGE_LOWERCASE,
                                 self.forwardToQliqId, FORWARDING_QLIQ_ID,
                                 nil];
    
    NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:
							  contentDict, DATA,
							  nil];
    
	NSMutableDictionary *jsonDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									 dataDict, MESSAGE,
									 nil];
    return jsonDict;
    
}

- (void)handleResponseMessageData:(NSDictionary *)dataDict withCompletition:(CompletionBlock)completitionBlock{
    if (completitionBlock) completitionBlock(CompletitionStatusSuccess, nil, nil);
}

@end

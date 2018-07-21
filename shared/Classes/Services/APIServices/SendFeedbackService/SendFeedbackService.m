//
//  SendFeedbackService.m
//  qliq
//
//  Created by Aleksey Garbarev on 11/8/12.
//
//

#import "SendFeedbackService.h"
#import "JSONSchemaValidator.h"
#import "QliqJsonSchemaHeader.h"
#import "KeychainService.h"
#import "JSONKit.h"
#import "RestClient.h"
#import "UIDevice+UUID.h"
#import "UserSession.h"
#import "UserSessionService.h"

@interface SendFeedbackService()

@property (nonatomic, strong) NSString * message;
@property (nonatomic, strong) NSString * subject;
@property (nonatomic, assign) BOOL notifyUser;

@end

@implementation SendFeedbackService

@synthesize message, subject;

- (NSString *) serviceName{
    return @"services/send_feedback";
}

- (id) initWithMessage:(NSString *)_message andSubject:(NSString *)_subject notifyUser:(BOOL)notifyUser {
    self = [super init];
    if (self) {
        self.message = _message;
        self.subject = _subject;
        self.notifyUser = _notifyUser;
    }
    return self;
}

- (Schema)requestSchema{
    return SendFeedbackRequestSchema;
}

- (Schema)responseSchema{
    return SendFeedbackResponseSchema;
}

- (NSDictionary *)requestJson{
    
    UserSession *currentSession = [UserSessionService currentUserSession];
    NSString * username = currentSession.sipAccountSettings.username;
    NSString * password = currentSession.sipAccountSettings.password;
    NSString * uuid = [[UIDevice currentDevice] qliqUUID];
    
	NSDictionary *contentDict = [NSDictionary dictionaryWithObjectsAndKeys:
								 password, PASSWORD,
								 username, USERNAME,
								 self.subject, SUBJECT,
                                 self.message, MESSAGE_LOWERCASE,
                                 [NSNumber numberWithBool:self.notifyUser], NOTIFY_USER,
                                 uuid, DEVICE_UUID,
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

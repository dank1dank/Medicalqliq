//
//  GetQliqMessageForPushService.m
//  qliq
//
//  Created by Adam on 5/3/18.
//

#import "GetQliqMessageForPushService.h"
#import "JSONKit.h"
#import "QliqJsonSchemaHeader.h"
#import "UIDevice+UUID.h"
#import "RestClient.h"
#import "QliqConnectModule.h"

@interface GetQliqMessageForPushService()

@property (nonatomic, strong) NSString *callId;
@property (nonatomic, strong) NSString *serverContext;
@property (nonatomic, strong) NSString *fromUser;
@property (nonatomic, strong) NSDictionary *aps;

@end

@implementation GetQliqMessageForPushService

- (id) initWithPushNotification:(NSDictionary *)aps
{
    NSString *callId = aps[@"call_id"];
    NSString *fromUser = aps[@"fuser"];
    NSString *serverContext = nil;
    
    NSString *xHeadersString = aps[@"xheaders"];
    if ([xHeadersString length] > 0) {
        xHeadersString = [xHeadersString stringByReplacingOccurrencesOfString:@"\\\"" withString:@"\""];
        NSStringEncoding stringEncoding = NSUTF8StringEncoding;
        NSStringEncoding dataEncoding = stringEncoding;
        NSError *error = nil;
        NSData *jsonData = [xHeadersString dataUsingEncoding:dataEncoding];
        JSONDecoder *jsonKitDecoder = [JSONDecoder decoder];
        NSDictionary *xHeaders = [jsonKitDecoder objectWithData:jsonData error:&error];
        serverContext = xHeaders[@"X-server-context"];
    }
    if (serverContext == nil) {
        serverContext = @"";
    }
    return [self initWithCallId:callId serverContext:serverContext fromUser:fromUser pushNotification:aps];
}

- (id) initWithCallId:(NSString *)callId
        serverContext:(NSString *)serverContext
             fromUser:(NSString *)fromUser
     pushNotification:(NSDictionary *)aps
{
    self = [super init];
    if (self) {
        self.callId = callId;
        self.serverContext = serverContext;
        self.fromUser = fromUser;
        self.aps = aps;
    }
    return self;
}

+ (void) handlePushNotification:(NSDictionary *)aps
{
    GetQliqMessageForPushService *service = [[GetQliqMessageForPushService alloc] initWithPushNotification:aps];
    [service callServiceWithCompletition:^(CompletitionStatus status, id result, NSError *error) {
        
        if (status == CompletitionStatusSuccess) {
            DDLogSupport(@"get_qliq_message_for_push finished successfully");
            NSDictionary *aps = result;
            [QliqConnectModule processRemoteNotificationWithQliqMessage:aps isVoip:YES];
        } else if (status == CompletitionStatusError) {
            DDLogSupport(@"get_qliq_message_for_push finished with error, code: %d, message: %@", (int)error.code, [error localizedDescription]);
        }
    }];
}

#pragma mark - Private

- (NSString *) serviceName
{
    return @"services/get_qliq_message_for_push";
}

- (NSDictionary *) requestJson
{
    NSString *username = [UserSessionService currentUserSession].sipAccountSettings.username;
    NSString *password = [UserSessionService currentUserSession].sipAccountSettings.password;
    NSString *deviceUUID = [[UIDevice currentDevice] qliqUUID];
    
    NSDictionary *contentDict = @{
                                  PASSWORD: password,
                                  USERNAME: username,
                                  DEVICE_UUID: deviceUUID,
                                  @"callid": self.callId,
                                  @"X_server_context": self.serverContext,
                                  @"fromuser": self.fromUser
                                  };
    return @{MESSAGE: @{DATA: contentDict}};
}

- (void)handleResponseMessageData:(NSDictionary *)dataDict withCompletition:(CompletionBlock)completitionBlock {
    
    NSString *msg = dataDict[@"message"];
    NSMutableDictionary *apsCopy = [self.aps mutableCopy];
    [apsCopy setObject:msg forKey:@"msg"];
    
    if (completitionBlock) {
        completitionBlock(CompletitionStatusSuccess, apsCopy, nil);
    }
}

@end


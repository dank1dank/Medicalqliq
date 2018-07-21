//
//  GetQuickMessagesService.m
//  qliq
//
//  Created by Ravi Ada on 11/23/12.
//
//

#import "GetQuickMessagesService.h"
#import "JSONSchemaValidator.h"
#import "QliqJsonSchemaHeader.h"
#import "KeychainService.h"
#import "JSONKit.h"
#import "RestClient.h"

#import "DBUtil.h"

#import "QuickMessage.h"
#import "UserSettingsService.h"
#import "DBHelperConversation.h"

@interface GetQuickMessagesService()

@property (nonatomic, strong) NSString * qliqId;

@end

@implementation GetQuickMessagesService

@synthesize qliqId;

- (NSString *) serviceName{
    return @"services/get_quick_messages";
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
    return GetQuickMessagesRequestSchema;
}

- (Schema)responseSchema{
    return GetQuickMessagesResponseSchema;
}

- (NSDictionary *)requestJson{
    
    UserSession * currentSession = [UserSessionService currentUserSession];
    
	NSMutableDictionary * dataDict = [[NSMutableDictionary alloc] init];
    dataDict[USERNAME] = currentSession.sipAccountSettings.username;
    dataDict[PASSWORD] = currentSession.sipAccountSettings.password;

    return @{ MESSAGE : @{ DATA : dataDict } };
    
}

- (void)handleResponseMessageData:(NSDictionary *)dataDict withCompletition:(CompletionBlock)completitionBlock{
    /* delete previous quick messages */
    [QuickMessage deletePriorQuickMessages];
    
    /* save quick messages */
	DDLogSupport(@"Data %@",dataDict);
	NSMutableArray *quickMessagesArray = [dataDict objectForKey:@"quick_messages"];
    for(NSMutableDictionary *quickMessageDict in quickMessagesArray)
    {
        DDLogSupport(@"quickMessageDict %@",quickMessageDict);
        QuickMessage *quickMessage = [[QuickMessage alloc] init];
        quickMessage.message = [quickMessageDict objectForKey:@"message"];
        quickMessage.uuid = [quickMessageDict objectForKey:@"uuid"];
        quickMessage.displayOrder = [[quickMessageDict objectForKey:@"order"] intValue];
        quickMessage.category = [quickMessageDict objectForKey:@"category"];
        [QuickMessage addQuickMessage:quickMessage];
    }
    
    if (completitionBlock) completitionBlock(CompletitionStatusSuccess, nil, nil);
}

@end

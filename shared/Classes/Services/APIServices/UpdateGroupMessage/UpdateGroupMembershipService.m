//
//  UpdateGroupMembershipService.m
//  qliq
//
//  Created by Ravi Ada on 02/18/13.
//
//

#import "UpdateGroupMembershipService.h"
#import "JSONSchemaValidator.h"
#import "QliqJsonSchemaHeader.h"
#import "KeychainService.h"
#import "JSONKit.h"
#import "RestClient.h"
#import "Presence.h"

@interface UpdateGroupMembershipService()

@property (nonatomic, strong) NSMutableArray * groups;

@end


@implementation UpdateGroupMembershipService

- (NSString *) serviceName{
    return @"services/update_group_membership";
}

- (id) initWithGroups:(NSMutableArray *) groups;
{
    self = [super init];
    if (self) {
        self.groups = groups;
    }
    return self;
}

- (Schema)requestSchema{
    return UpdateGroupMembershipRequestSchema;
}

- (Schema)responseSchema{
    return UpdateGroupMembershipResponseSchema;
}

- (NSDictionary *)requestJson{
    
    UserSession *currentSession = [UserSessionService currentUserSession];
    NSString * username = currentSession.sipAccountSettings.username;
    NSString * password = currentSession.sipAccountSettings.password;
    
	NSDictionary *contentDict = [NSDictionary dictionaryWithObjectsAndKeys:
								 password, PASSWORD,
								 username, USERNAME,
                                 self.groups, @"groups",
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

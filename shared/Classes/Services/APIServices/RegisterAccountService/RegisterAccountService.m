//
//  ReportIncidentService.m
//  qliq
//
//  Created by Aleksey Garbarev on 11/8/12.
//
//

#import "RegisterAccountService.h"
#import "JSONSchemaValidator.h"
#import "QliqJsonSchemaHeader.h"
#import "KeychainService.h"
#import "JSONKit.h"
#import "RestClient.h"
#import "QliqUser.h"

@interface RegisterAccountService()

@property (nonatomic, strong) QliqUser *user;
@property (nonatomic, strong) NSString *organization;
@property (nonatomic, strong) NSString *website;

@end

@implementation RegisterAccountService

@synthesize user, organization, website;

- (NSString *) serviceName{
    NSString *server = @"https://";
    server = [server stringByAppendingString: [RestClient serverUrlForUsername:user.email]];
    NSString *serviceUrl = [server stringByAppendingString:@"/services/register_account"];
    return serviceUrl;
}

- (id) initWithUser:(QliqUser *)_user andOrganization:(NSString *)_organization andWebsite:(NSString *)_website {
    self = [super init];
    if (self) {
        self.user = _user;
        self.organization = _organization;        
        self.website = _website;
    }
    return self;
}

- (Schema)requestSchema{
    return RegisterAccountRequestSchema;
}

- (Schema)responseSchema{
    return RegisterAccountResponseSchema;
}

- (NSDictionary *)requestJson{
    
	NSMutableDictionary *contentDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
								 @"group", ACCOUNT_TYPE,
                                 user.email, EMAIL,
                                 user.firstName, FIRST_NAME,
                                 user.lastName, LAST_NAME,
                                 user.phone, PHONE,
                                 user.profession, TITLE,
                                 organization, ORGANIZATION,
                                 website, WEBSITE,
                                 nil];

    if (user.middleName.length > 0) {
        [contentDict setObject:user.middleName forKey:MIDDLE];
    }
    
    NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:
							  contentDict, DATA,
							  nil];
    
	NSMutableDictionary *jsonDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									 dataDict, MESSAGE,
									 nil];
    NSLog(@"json: %@", [jsonDict JSONString]);
    return jsonDict;
}

- (void)handleResponseMessageData:(NSDictionary *)dataDict withCompletition:(CompletionBlock)completitionBlock{
    if (completitionBlock) completitionBlock(CompletitionStatusSuccess, nil, nil);
}




@end

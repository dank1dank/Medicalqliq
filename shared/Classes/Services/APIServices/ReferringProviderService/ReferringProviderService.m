//
//  UserAccountService.m
//  qliq
//
//  Created by Paul Bar on 2/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ReferringProviderService.h"
#import "QliqApiManager.h"
#import "JSONKit.h"
#import "GetReferringProviderResponseSchema.h"
#import "GetReferringProviderRequestSchema.h"
#import "WebClient.h"
#import "UserSessionService.h"
#import "UserSession.h"
#import "ASIHTTPRequest.h"
#import "JSONSchemaValidator.h"
#import "DBUtil.h"
#import "ReferringProvider.h"
#import "ReferringProviderDbService.h"
#import "QliqUser.h"
#import "QliqUserService.h"
#import "TaxonomyDbService.h"
#import "Buddy.h"
#import "RestClient.h"

@interface ReferringProviderService(Private)
-(BOOL) referringProviderInfoValid:(NSString *)referringProviderJson;
-(BOOL) processReferringProviderInfo:(NSString *)referringProviderJson;
-(BOOL) storeReferringProviderInfoData:(NSDictionary *)dataDict;
@end

@implementation ReferringProviderService
@synthesize delegate;


#pragma mark -
#pragma mark Private
-(void) getReferringProviderInfoForUser
{
	NSURL *referringProviderDownloadURL;
	
	SipAccountSettings *sas= [UserSessionService currentUserSession].sipAccountSettings;
	NSString *urlString = [[WebClient serverUrlForUsername:sas.username] stringByAppendingString:@"/services/get_referring_providers_info"];
	referringProviderDownloadURL = [NSURL URLWithString:urlString];
	NSMutableDictionary *contentDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
								 @"*********", GET_REFERRING_PROVIDER_REQUEST_MESSAGE_DATA_PASSWORD,
								 sas.username, GET_REFERRING_PROVIDER_REQUEST_MESSAGE_DATA_USER_ID,
								 nil];
	NSMutableDictionary *dataDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
							  contentDict, GET_REFERRING_PROVIDER_REQUEST_MESSAGE_DATA,
							  GET_REFERRING_PROVIDER_REQUEST_MESSAGE_TYPE_PATTERN, GET_REFERRING_PROVIDER_REQUEST_MESSAGE_TYPE,
							  GET_REFERRING_PROVIDER_REQUEST_MESSAGE_COMMAND_PATTERN, GET_REFERRING_PROVIDER_REQUEST_MESSAGE_COMMAND,
							  GET_REFERRING_PROVIDER_REQUEST_MESSAGE_SUBJECT_PATTERN, GET_REFERRING_PROVIDER_REQUEST_MESSAGE_SUBJECT,
							  nil];
	NSMutableDictionary *jsonDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
							  dataDict, GET_REFERRING_PROVIDER_REQUEST_MESSAGE,
							  nil];
	
	DDLogInfo(@"Sending get_referring_provider_info request: %@", [jsonDict JSONString]);
	[contentDict setValue:sas.password forKey:GET_REFERRING_PROVIDER_REQUEST_MESSAGE_DATA_PASSWORD];
	
	RestClient *restClient = [RestClient clientForCurrentUser];
	
	[restClient postDataToServer:@"services/get_referring_providers_info" 
					  jsonToPost:jsonDict 
					onCompletion:^(NSString *reponseString) {
						[self processReferringProviderInfo:reponseString];
					} 
						 onError:^(NSError* error) {
							 [UIAlertView showWithError:error];
						 }
	 ];
	
	/*
	// create the request and start downloading by making the connection
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:referringProviderDownloadURL];
	
	[request appendPostData:[[jsonDict JSONString] dataUsingEncoding:NSUTF8StringEncoding]];
	NSString *postLength = [NSString stringWithFormat:@"%d", [[jsonDict JSONString] length]];
	[request addRequestHeader:@"Content-Type" value:@"application/json"];
	[request addRequestHeader:@"Content-Length" value:postLength];
	[request addRequestHeader:@"Accept" value:@"application/json"];
	[request setRequestMethod:@"POST"];
    request.delegate = self;
    request.didFinishSelector = @selector(referringProviderRequestFinished:);
    request.didFailSelector = @selector(referringProviderRequestFailed:);
	//[request startSynchronous];
    [request performSelectorOnMainThread:@selector(startSynchronous) withObject:nil waitUntilDone:YES];
	 */
}

/*
- (void) referringProviderRequestFinished:(ASIHTTPRequest *)request
{
	// Use when fetching text data
	NSString *responseString = [request responseString];
	//NSLog(@"Get referring providers request finished: %@", responseString);
	int httpStatusCode = [request responseStatusCode];
	NSString *httpStatusMessage = [request responseStatusMessage];
	if(httpStatusCode==200){
		[self processReferringProviderInfo:responseString];
	}else{
		DDLogError(@"Cannot get referring providers, http status: %@", httpStatusMessage);
	}
}

- (void) referringProviderRequestFailed:(ASIHTTPRequest *)request
{
	NSLog(@"Get referring provider request failed");
}*/

-(BOOL) processReferringProviderInfo:(NSString *)referringProviderJson
{   
    NSStringEncoding dataEncoding = NSUTF8StringEncoding;
    NSError *error=nil;
    NSData *jsonData = [referringProviderJson dataUsingEncoding:dataEncoding];
    JSONDecoder *jsonKitDecoder = [JSONDecoder decoder];
    NSDictionary *referringProviderInfoData = [jsonKitDecoder objectWithData:jsonData error:&error];
    NSString *errorMessage = [referringProviderInfoData valueForKey:@"Error"];
	if([errorMessage length]>0){
		NSLog(@"Error returned from webservice: %@", errorMessage);
		return FALSE;
	}
    NSDictionary *data = [[referringProviderInfoData valueForKey:GET_REFERRING_PROVIDER_RESPONSE_MESSAGE] valueForKey:GET_REFERRING_PROVIDER_RESPONSE_MESSAGE_DATA];
	//NSLog(@"After parsing with JSONKit: %@", data);
	[self storeReferringProviderInfoData:data];
    return TRUE;
}

-(BOOL) referringProviderInfoValid:(NSString *)referringProviderJson
{
    BOOL rez = YES;
    rez &= [referringProviderJson length] > 0;
    BOOL validJson = [JSONSchemaValidator validate:referringProviderJson embeddedSchema:ReferringProviderInfoResponseSchema];
    rez &= validJson;
	
    return rez;
}

-(BOOL) storeReferringProviderInfoData:(NSDictionary *)dataDict
{
    BOOL success = YES;
	
    NSArray *referringProviderArray = [dataDict objectForKey:GET_REFERRING_PROVIDER_RESPONSE_MESSAGE_DATA_REFERRING_PROVIDERS];
	ReferringProviderDbService *rphDBService = [[ReferringProviderDbService alloc] init];
	
	for(NSMutableDictionary *referringProviderDict in referringProviderArray){
		
		NSString *email = [referringProviderDict objectForKey:GET_REFERRING_PROVIDER_RESPONSE_MESSAGE_DATA_REFERRING_PROVIDERS_USER_ID];
		NSString *prefix = [referringProviderDict objectForKey:GET_REFERRING_PROVIDER_RESPONSE_MESSAGE_DATA_REFERRING_PROVIDERS_NAME_PREFIX];
		NSString *firstName = [referringProviderDict objectForKey:GET_REFERRING_PROVIDER_RESPONSE_MESSAGE_DATA_REFERRING_PROVIDERS_FIRST_NAME];
		NSString *middleName = [referringProviderDict objectForKey:GET_REFERRING_PROVIDER_RESPONSE_MESSAGE_DATA_REFERRING_PROVIDERS_MIDDLE_NAME];
		NSString *lastName = [referringProviderDict objectForKey:GET_REFERRING_PROVIDER_RESPONSE_MESSAGE_DATA_REFERRING_PROVIDERS_LAST_NAME];
		NSString *suffix = [referringProviderDict objectForKey:GET_REFERRING_PROVIDER_RESPONSE_MESSAGE_DATA_REFERRING_PROVIDERS_NAME_SUFFIX];
		NSString *credentials = [referringProviderDict objectForKey:GET_REFERRING_PROVIDER_RESPONSE_MESSAGE_DATA_REFERRING_PROVIDERS_CREDENTIALS];
		NSString *initials = [referringProviderDict objectForKey:GET_REFERRING_PROVIDER_RESPONSE_MESSAGE_DATA_REFERRING_PROVIDERS_INITIALS];
		NSString *state = [referringProviderDict objectForKey:GET_REFERRING_PROVIDER_RESPONSE_MESSAGE_DATA_REFERRING_PROVIDERS_STATE];
		NSString *zip = [referringProviderDict objectForKey:GET_REFERRING_PROVIDER_RESPONSE_MESSAGE_DATA_REFERRING_PROVIDERS_ZIP];
		NSString *mobile = [referringProviderDict objectForKey:GET_REFERRING_PROVIDER_RESPONSE_MESSAGE_DATA_REFERRING_PROVIDERS_MOBILE];
		NSString *phone = [referringProviderDict objectForKey:GET_REFERRING_PROVIDER_RESPONSE_MESSAGE_DATA_REFERRING_PROVIDERS_PHONE];
		NSString *fax = [referringProviderDict objectForKey:GET_REFERRING_PROVIDER_RESPONSE_MESSAGE_DATA_REFERRING_PROVIDERS_FAX];
		NSNumber *npi = [referringProviderDict objectForKey:GET_REFERRING_PROVIDER_RESPONSE_MESSAGE_DATA_REFERRING_PROVIDERS_NPI];
		NSString *taxonomyCode = [referringProviderDict objectForKey:GET_REFERRING_PROVIDER_RESPONSE_MESSAGE_DATA_REFERRING_PROVIDERS_TAXONOMY_CODE];
		NSString *sipUri= [referringProviderDict objectForKey:GET_REFERRING_PROVIDER_RESPONSE_MESSAGE_DATA_REFERRING_PROVIDERS_SIP_URI];
		NSString *qliqId = [referringProviderDict objectForKey:GET_REFERRING_PROVIDER_RESPONSE_MESSAGE_DATA_REFERRING_PROVIDERS_USER_ID];
		NSString *displayName = [referringProviderDict objectForKey:GET_REFERRING_PROVIDER_RESPONSE_MESSAGE_DATA_REFERRING_PROVIDERS_NAME];
		
		ReferringProvider *rp = [[ReferringProvider alloc] init];
		rp.npi = [npi doubleValue];
		rp.prefix = prefix;
		rp.firstName = firstName;
		rp.middleName = middleName;
		rp.lastName = lastName;
		rp.suffix = suffix;
		rp.credentials = credentials;
		rp.state = state;
		rp.zip = zip;
		rp.mobile = mobile;
		rp.phone = phone;
		rp.fax = fax;
		rp.taxonomyCode = taxonomyCode;
		rp.email = email;
		rp.sipUri = sipUri;
		
		[rphDBService saveReferringProvider:rp];
		
		if([sipUri length]>0 && [qliqId length]>0){
			//saving user
			QliqUserService *userService = [[QliqUserService alloc] init];
			QliqUser* rphUser = [[QliqUser alloc] init];
			/*
			rphUser.email = email;
			rphUser.prefix = prefix;
			rphUser.firstName = firstName;
			rphUser.middleName = middleName;
			rphUser.lastName = lastName;
			rphUser.suffix = suffix;
			rphUser.credentials = credentials;
			rphUser.initials = initials;
			rphUser.state = state;
			rphUser.zip = zip;
			rphUser.mobile = mobile;
			rphUser.phone = phone;
			rphUser.fax = fax;
			rphUser.npi = npi;
			rphUser.kind = @"provider";
			rphUser.taxonomyCode = taxonomyCode;
			rphUser.sipUri = sipUri;
			if(![userService saveUser:rphUser])
			{
				NSLog(@"Cant save logging user: %@", rphUser);
			}else{
				//we are keeping the Buddy model for now. will get rid of it latter
				SipAccountSettings *sas= [UserSessionService currentUserSession].sipAccountSettings;
				Buddy *buddyModelObj = [[Buddy alloc] init];
				buddyModelObj.qliqId = sas.username;
				buddyModelObj.buddyQliqId = rphUser.email;
				buddyModelObj.displayName = displayName;
				buddyModelObj.sipUri = sipUri;
				success = [BuddyList addBuddy:buddyModelObj];
				[buddyModelObj release];
				
			}
			[rphUser release];
			 */
			[userService release];
		}
		[rp release];
	}
	[rphDBService release];
    return success;
}
@end

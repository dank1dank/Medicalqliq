//
//  UserAccountService.m
//  qliq
//
//  Created by Paul Bar on 2/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SuperbillService.h"
#import "QliqApiManager.h"
#import "JSONKit.h"
#import "GetSuperbillInfoResponse.h"
#import "GetSuperbillInfoRequest.h"
#import "WebClient.h"
#import "UserSessionService.h"
#import "UserSession.h"
#import "ASIHTTPRequest.h"
#import "JSONSchemaValidator.h"
#import "DBUtil.h"
#import "Superbill.h"
#import "SuperbillDbService.h"

@interface SuperbillService(Private)

-(BOOL) superbillInfoValid:(NSString *)superbillJson;
-(BOOL) processSuperbillInfo:(NSString *)superbillJson;
-(BOOL) storeSuperbillInfoData:(NSDictionary *)dataDict;
@end
	
@implementation SuperbillService
@synthesize delegate;


#pragma mark -
#pragma mark Private
-(void) getSuperbillInfoForUser
{
	NSURL *superbillDownloadURL;

	SipAccountSettings *sas= [UserSessionService currentUserSession].sipAccountSettings;
	QliqUser *loggedInUser = [UserSessionService currentUserSession].user;
	
	NSString *urlString = [[WebClient serverUrlForUsername:sas.username] stringByAppendingString:@"/services/get_superbill_info"];
	superbillDownloadURL = [NSURL URLWithString:urlString];
	NSDictionary *contentDict = [NSDictionary dictionaryWithObjectsAndKeys:
								 loggedInUser.taxonomyCode, GET_SUPERBILL_INFO_REQUEST_MESSAGE_DATA_TAXONOMY_CODE,
								 sas.password, GET_SUPERBILL_INFO_REQUEST_MESSAGE_DATA_PASSWORD,
								 sas.username, GET_SUPERBILL_INFO_REQUEST_MESSAGE_DATA_USER_ID,
								 nil];
	NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:
							  contentDict, GET_SUPERBILL_INFO_REQUEST_MESSAGE_DATA,
							  GET_SUPERBILL_INFO_REQUEST_MESSAGE_TYPE_PATTERN, GET_SUPERBILL_INFO_REQUEST_MESSAGE_TYPE,
							  GET_SUPERBILL_INFO_REQUEST_MESSAGE_COMMAND_PATTERN, GET_SUPERBILL_INFO_REQUEST_MESSAGE_COMMAND,
							  GET_SUPERBILL_INFO_REQUEST_MESSAGE_SUBJECT_PATTERN, GET_SUPERBILL_INFO_REQUEST_MESSAGE_SUBJECT,
							  nil];
	NSDictionary *jsonDict = [NSDictionary dictionaryWithObjectsAndKeys:
							  dataDict, GET_SUPERBILL_INFO_REQUEST_MESSAGE,
							  nil];
	
	// create the request and start downloading by making the connection
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:superbillDownloadURL];
	
	[request appendPostData:[[jsonDict JSONString] dataUsingEncoding:NSUTF8StringEncoding]];
	NSString *postLength = [NSString stringWithFormat:@"%d", [[jsonDict JSONString] length]];
	[request addRequestHeader:@"Content-Type" value:@"application/json"];
	[request addRequestHeader:@"Content-Length" value:postLength];
	[request addRequestHeader:@"Accept" value:@"application/json"];
	[request setRequestMethod:@"POST"];
    request.delegate = self;
    request.didFinishSelector = @selector(superbillRequestFinished:);
    request.didFailSelector = @selector(superbillRequestFailed:);
	[request startSynchronous];
}

- (void) superbillRequestFinished:(ASIHTTPRequest *)request
{
	// Use when fetching text data
	NSString *responseString = [request responseString];
	//NSLog(@"Get superbill request finished: %@", responseString);
	int httpStatusCode = [request responseStatusCode];
	NSString *httpStatusMessage = [request responseStatusMessage];
	if(httpStatusCode==200){
		[self processSuperbillInfo:responseString];
	}else{
		DDLogError(@"Cannot get superbill, http status: %@", httpStatusMessage);
	}
	
}

- (void) superbillRequestFailed:(ASIHTTPRequest *)request
{
	NSLog(@"Get superbill request failed");
}

-(BOOL) processSuperbillInfo:(NSString *)superbillJson
{   
    NSStringEncoding dataEncoding = NSUTF8StringEncoding;
    NSError *error=nil;
    NSData *jsonData = [superbillJson dataUsingEncoding:dataEncoding];
    JSONDecoder *jsonKitDecoder = [JSONDecoder decoder];
    NSDictionary *superbillInfoData = [jsonKitDecoder objectWithData:jsonData error:&error];
    NSString *errorMessage = [superbillInfoData valueForKey:@"Error"];
	if([errorMessage length]>0){
		NSLog(@"Error returned from superbill webservice: %@", errorMessage);
		return FALSE;
	}
    NSDictionary *data = [[superbillInfoData valueForKey:GET_SUPERBILL_INFO_RESPONSE_MESSAGE] valueForKey:GET_SUPERBILL_INFO_RESPONSE_MESSAGE_DATA];
	NSLog(@"After parsing with JSONKit: %@", data);
	[self storeSuperbillInfoData:data];
    return TRUE;
}

-(BOOL) superbillInfoValid:(NSString *)superbillJson
{
    BOOL rez = YES;
    rez &= [superbillJson length] > 0;
    BOOL validJson = [JSONSchemaValidator validate:superbillJson embeddedSchema:SuperbillInfoResponseSchema];
    rez &= validJson;

    return rez;
}

-(BOOL) storeSuperbillInfoData:(NSDictionary *)dataDict
{
    BOOL success = YES;
	SuperbillDbService *sbDbService = [[SuperbillDbService alloc] init];
	Superbill *sb = [[Superbill alloc] init];
    NSMutableDictionary *superbillDict = [dataDict objectForKey:GET_SUPERBILL_INFO_RESPONSE_MESSAGE_DATA_SUPERBILL];
	NSString *superBillName = [superbillDict objectForKey:GET_SUPERBILL_INFO_RESPONSE_MESSAGE_DATA_SUPERBILL_NAME];
	sb.taxonomyCode = [UserSessionService currentUserSession].user.taxonomyCode;
	sb.name = superBillName;
	sb.data = [dataDict description];
	[sbDbService saveSuperbill:sb];
	[sb release];
	[sbDbService release];
    return success;
}
@end

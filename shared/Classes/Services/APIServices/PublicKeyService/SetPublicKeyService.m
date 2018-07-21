//
//  SetPublicKeyService.m
//  qliq
//
//  Created by Ravi Ada on 05/29/12.
//  Copyright (c) 2012 qliqSoft Inc. All rights reserved.
//

#import "SetPublicKeyService.h"
#import "JSONSchemaValidator.h"
#import "RestClient.h"
#import "QliqJsonSchemaHeader.h"
#import "JSONKit.h"
#import "WebClient.h"
#import "KeychainService.h"
#import "UserSessionService.h"
#import "UserSession.h"

@interface SetPublicKeyService()

-(void) processResponseString:(NSString *)responseString;

@end

@implementation SetPublicKeyService

@synthesize delegate;

+ (SetPublicKeyService *) sharedService{
    static dispatch_once_t pred;
    static id shared = nil;
    dispatch_once(&pred, ^{
        shared = [[SetPublicKeyService alloc] init];
        
    });
    return shared;
}


-(void) setPublicKey:(NSString*)publicKey
{
	
	UserSession *userSession = [UserSessionService currentUserSession];
	
    //TODO: get the qliq_id, device UUID and, current timestamp on the device
	NSDictionary *contentDict = [NSDictionary dictionaryWithObjectsAndKeys:
								 userSession.sipAccountSettings.password, PASSWORD,
								 userSession.sipAccountSettings.username, USERNAME,
								 userSession.deviceUuid, UUID,
								 @"iOS", PLATFORM,
								 publicKey,PUBLIC_KEY,
                                 nil];
    
    NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:
							  contentDict, DATA,
							  nil];
	NSMutableDictionary *jsonDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
							  dataDict, MESSAGE,
							  nil];
	
	if ([JSONSchemaValidator validate:[jsonDict JSONString] embeddedSchema:SetPublicKeyRequestSchema]){
		RestClient *restClient = [RestClient clientForCurrentUser];
		[restClient postDataToServer:@"services/set_public_key" 
						  jsonToPost:jsonDict 
						onCompletion:^(NSString *responseString)
		 {
			 [self processResponseString:responseString];
		 } 
							 onError:^(NSError* error)
		 {
             DDLogError(@"error during sending request: %@",error);
		 }];
	}else{
		DDLogError(@"Invalid request sent to server");
	}
}

#pragma mark -
#pragma mark Private

-(void) processResponseString:(NSString *)responseString
{
    NSError *error = nil;
    NSData *jsonData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
    JSONDecoder *jsonKitDecoder = [JSONDecoder decoder];
    NSMutableDictionary *message = [[jsonKitDecoder objectWithData:jsonData error:&error] objectForKey:MESSAGE];
    
	//TODO: process Data if data json object is present, otherwise process error json
	NSDictionary *dataDict = [message objectForKey:DATA];
    if (dataDict)
    {
        DDLogInfo(@"dataDict: %@", dataDict);
    }else{
		
		NSDictionary *errorDict = [message objectForKey:ERROR];
        DDLogError(@"errorDict: %@", errorDict);
	}
}
@end

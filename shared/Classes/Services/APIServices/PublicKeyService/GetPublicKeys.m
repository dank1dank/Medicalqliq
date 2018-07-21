//
//  GetPublicKeys.m
//  qliq
//
//  Created by Ravi Ada on 05/29/12.
//  Copyright (c) 2012 qliqSoft Inc. All rights reserved.
//

#import "GetPublicKeys.h"
#import "JSONSchemaValidator.h"
#import "RestClient.h"
#import "QliqJsonSchemaHeader.h"
#import "JSONKit.h"
#import "UserSession.h"
#import "UserSessionService.h"
#import "Crypto.h"
#import "SipContactDBService.h"
#import "DBUtil.h"

@interface GetPublicKeys()

-(void) getPublicKeysRequestFinished:(NSString *)responseString;
-(BOOL) publicKeysValid:(NSString *)publiKeysJson;
-(BOOL) storePublicKeys:(NSDictionary *)dataDict;

@end

@implementation GetPublicKeys{
    void(^finish)(NSString * qliqId, NSError * error);
}

@synthesize delegate, requestQliqId;

-(void) dealloc
{
    // ARC mode is enabled and forbids call to release?
    //[requestQliqId release];
}

-(void) getPublicKeys:(NSString*) qliqId completitionBlock:(void(^)(NSString * qliqId, NSError * error))block{
    finish = block;
    self.requestQliqId = qliqId;
    
    UserSession *currentSession = [UserSessionService currentUserSession];
    NSString *username = currentSession.sipAccountSettings.username;
    NSString *password = currentSession.sipAccountSettings.password;
	
    //TODO: get the qliq_id, device UUID and, current timestamp on the device
	NSDictionary *contentDict = [NSDictionary dictionaryWithObjectsAndKeys:
								 password, PASSWORD,
								 username, USERNAME,
								 qliqId,QLIQ_ID,
                                 nil];
    
    NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:
							  contentDict, DATA,
							  nil];
	NSMutableDictionary *jsonDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     dataDict, MESSAGE,
                                     nil];
	if ([JSONSchemaValidator validate:[jsonDict JSONString] embeddedSchema:GetContactPubkeyRequestSchema]){
		
		RestClient *restClient = [RestClient clientForCurrentUser];
        [restClient postDataToServer:RegularWebServerType
                                path:@"services/get_contact_pubkey"
						  jsonToPost:jsonDict
						onCompletion:^(NSString *responseString)
		 {
			 [self getPublicKeysRequestFinished:responseString];
		 }
							 onError:^(NSError* error)
		 {
             [self.delegate didFailToGetPublicKeysWithReason:requestQliqId withReason:[error localizedDescription] withServiceErrorCode:0];
             DDLogError(@"errur during getting public keys: %@",error);
             if (finish) finish(nil, error);
		 }];
	}else{
		[self.delegate didFailToGetPublicKeysWithReason:requestQliqId withReason:@"GetAllPublicKeysService: Invalid request sent to server"
                                   withServiceErrorCode:0];
        if (finish) finish(nil, [NSError errorWithDomain:errorDomainForModule(@"getPublicKey") code:1 userInfo:userInfoWithDescription(@"GetAllPublicKeysService: Invalid request sent to server")]);
	}
    
}

-(void) getPublicKeys:(NSString*) qliqId
{
    [self getPublicKeys:qliqId completitionBlock:nil];
}

#pragma mark -
#pragma mark Private

-(void) getPublicKeysRequestFinished:(NSString *)responseString
{
    NSLog(@"responseString : %@",responseString);
	NSStringEncoding dataEncoding = NSUTF8StringEncoding;
	NSError *error=nil;
	NSData *jsonData = [responseString dataUsingEncoding:dataEncoding];
	JSONDecoder *jsonKitDecoder = [JSONDecoder decoder];
	NSDictionary *getUserConfigData = [jsonKitDecoder objectWithData:jsonData error:&error];
	NSDictionary *errorDict = [[getUserConfigData valueForKey:MESSAGE] valueForKey:ERROR];
	
	if(errorDict != nil)
	{
		NSLog(@"Error returned from webservice: %@", [errorDict objectForKey:ERROR_MSG]);
		NSString *reason = [NSString stringWithFormat:@"Server error:%@", [errorDict objectForKey:ERROR_MSG]];
        NSNumber *errorNum = [errorDict objectForKey:ERROR_CODE];
		[self.delegate didFailToGetPublicKeysWithReason:requestQliqId withReason:reason withServiceErrorCode:[errorNum intValue]];
        if (finish) finish(nil, [NSError errorWithDomain:errorDomainForModule(@"getPublicKey") code:1 userInfo:userInfoWithDescription(reason)]);
		return;
	}
	
	
	if(![self publicKeysValid:responseString])
	{
		NSString *reason = [NSString stringWithFormat:@"Invalid public key info"];
        if (finish) finish(nil, [NSError errorWithDomain:errorDomainForModule(@"getPublicKey") code:1 userInfo:userInfoWithDescription(reason)]);
		return;
	}
	
	NSDictionary *getPublicKeysInfo = [[getUserConfigData valueForKey:MESSAGE] valueForKey:DATA];
	
    if ([self storePublicKeys:getPublicKeysInfo])
        [self.delegate getPublicKeysSuccess:requestQliqId];
    else
        [self.delegate didFailToGetPublicKeysWithReason:requestQliqId withReason:@"No valid keys in response" withServiceErrorCode:0];
    
    if (finish) finish(requestQliqId, nil);
}

-(BOOL) publicKeysValid:(NSString *)publiKeysJson
{
    BOOL rez = YES;
    rez &= [publiKeysJson length] > 0;
    BOOL validJson = [JSONSchemaValidator validate:publiKeysJson embeddedSchema:GetContactPubkeyResponseSchema];
    rez &= validJson;
	
    return rez;
}

-(BOOL) storePublicKeys:(NSDictionary *)dataDict
{
	DDLogSupport(@"STORE PUBLIC KEYS: processing started");
	
    __block BOOL success = NO;
	DDLogInfo(@"Data %@",dataDict);
    
    SipContact * sipContact = [[SipContact alloc] init];
    sipContact.qliqId = [dataDict objectForKey:QLIQ_ID];
    sipContact.publicKey = [dataDict objectForKey:PUBLIC_KEY];

    [[[SipContactDBService alloc] init] save:sipContact completion:^(BOOL wasInserted, id objectId, NSError *error) {
        success = (error == nil);
    }];
    
	DDLogSupport(@"STORE PUBLIC KEYS: processing finished");
	return success;
}

@end

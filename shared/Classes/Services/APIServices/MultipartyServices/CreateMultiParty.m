//
//  CreateMultiParty.m
//  qliq
//
//  Created by Ravi Ada on 11/22/12.
//  Copyright (c) 2012 qliqSoft All rights reserved.
//

#import "CreateMultiParty.h"
#import "NSNotificationAdditions.h"
#import "JSONSchemaValidator.h"
#import "RestClient.h"
#import "QliqJsonSchemaHeader.h"
#import "JSONKit.h"
#import "UserSession.h"
#import "UserSessionService.h"
#import "KeychainService.h"
#import "QliqKeychainUtils.h"
#import "Crypto.h"
#import "NSString+Base64.h"

@interface CreateMultiParty ()

-(void) processResponseString:(NSString *)responseString onCompletion:(void(^)(NSDictionary* responseData))completionBlock onError:(void (^)(NSError *error)) errorBlock;
- (void)createMultiPartyServiceCall:(NSString*) name andParticipantList:(NSArray*)participants onCompletion:(void(^)(NSDictionary* responseData))completionBlock onError:(void (^)(NSError *error)) errorBlock;
-(BOOL) isJsonResponseValid:(NSString *)responseString;

@end

@implementation CreateMultiParty

+ (CreateMultiParty *) sharedService{
    static dispatch_once_t pred;
    static id shared = nil;
    dispatch_once(&pred, ^{
        shared = [[CreateMultiParty alloc] init];
        
    });
    return shared;
}

-(void) createMultiParty:(NSString*) name andParticipantList:(NSArray*)participants
{
    DDLogSupport(@"Starting createMultiParty");
    [self createMultiPartyCompletitionBlock:name andParticipantList:participants completionBlock:nil];
    DDLogSupport(@"Finished createMultiParty");
}

-(void) createMultiPartyCompletitionBlock:(NSString*) name andParticipantList:(NSArray*)participants completionBlock:(CompletitionBlock) completition
{
    [self createMultiPartyServiceCall:(NSString*) name andParticipantList:(NSArray*)participants onCompletion:^(NSDictionary* responseData) {
        if (completition) completition(CompletitionStatusSuccess, self, nil);
    } onError:^(NSError *error) {
        if (completition) completition(CompletitionStatusError, NO, error);
    }];
}

- (void)createMultiPartyServiceCall:(NSString*) name andParticipantList:(NSArray*)participants onCompletion:(void(^)(NSDictionary* responseData))completionBlock onError:(void (^)(NSError *error)) errorBlock
{
    
    __block NSString *username, *password, *clearTextPassword;
    UserSession *currentSession = [UserSessionService currentUserSession];
    username = currentSession.sipAccountSettings.username;
    password = currentSession.sipAccountSettings.password;
    clearTextPassword = [[UserSessionService currentUserSession].sipAccountSettings.password base64DecodedString];

    void (^errorHandler)(NSError * error) = ^(NSError * error){
        if (errorBlock) errorBlock(error);
    };
    void (^successHandler)(NSDictionary* responseData) = ^(NSDictionary* responseData){
        NSString *errorMsg = nil;
        NSString * encryptedPrivateKeyStr = [responseData objectForKey:PRIVATE_KEY];
        NSString * publicKeyStr = [responseData objectForKey:PUBLIC_KEY];
        if ([encryptedPrivateKeyStr length] == 0) {
            errorMsg = @"There is no private key on the web server";
        }
        else if ([publicKeyStr length] == 0) {
            errorMsg = @"There is no public key on the web server";
        }
        else if (![Crypto isValidPublicKey:publicKeyStr]) {
            errorMsg = @"Cannot open public key from web server";
        }
        else if (![Crypto isValidPrivateKey:encryptedPrivateKeyStr withPassword:clearTextPassword]) {
            errorMsg = @"Cannot open private key from web server";
        }
        else if (![[Crypto instance] saveKeysForUser:username :clearTextPassword privateKey:encryptedPrivateKeyStr publicKey:publicKeyStr]) {
            errorMsg = @"Cannot store key pair";
        }
        
        if (errorMsg) {
            DDLogError(errorMsg);
            
            if (errorBlock) {
                NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
                [errorDetail setValue:errorMsg forKey:NSLocalizedDescriptionKey];
                NSError *error = [NSError errorWithDomain:@"GetMultiParty" code:100 userInfo:errorDetail];
                errorBlock(error);
            }
        } else {
            if (completionBlock) {
                completionBlock(responseData);
            }
        }
    };
    
	NSDictionary *contentDict = [NSDictionary dictionaryWithObjectsAndKeys:
								 password, PASSWORD,
								 username, USERNAME,
                                 name,MULTIPARTY_NAME,
                                 participants,PARTICIPANTS,
                                 nil];
    
    NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:
							  contentDict, DATA,
							  nil];
	NSMutableDictionary *jsonDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     dataDict, MESSAGE,
                                     nil];
    NSLog(@"get_key_pair request: %@ ",[jsonDict JSONString]);
	if ([JSONSchemaValidator validate:[jsonDict JSONString] embeddedSchema:CreateMultiPartyRequestSchema]){
		
		RestClient *restClient = [RestClient clientForCurrentUser];
        
		[restClient postDataToServer:@"services/get_group_key_pair"
                          jsonToPost:jsonDict onCompletion:^(NSString * responseDict)
		 {
             [self processResponseString:responseDict onCompletion:successHandler onError:errorHandler];
		 }
                             onError:^(NSError* error)
		 {
             errorHandler(error);
		 }];
	}else{
		NSLog(@"CreateMultiParty: Invalid request sent to server");
        errorHandler([NSError errorWithDomain:@"CreateMultiPartyError" code:200 userInfo:[NSDictionary dictionaryWithObject:@"Invalid request sent to server" forKey:@"error"]]);
	}
}

-(void) processResponseString:(NSString *)responseString onCompletion:(void(^)(NSDictionary* responseData))completionBlock onError:(void (^)(NSError *error)) errorBlock
{
    NSLog(@"get_key_pair responseString : %@ ",responseString);
    
    if([self isJsonResponseValid:responseString]){
        
        NSError *error = nil;
        NSData *jsonData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
        JSONDecoder *jsonKitDecoder = [JSONDecoder decoder];
        NSMutableDictionary *message = [[jsonKitDecoder objectWithData:jsonData error:&error] objectForKey:MESSAGE];
        
        NSDictionary *dataDict = [message objectForKey:DATA];
        if (dataDict)
        {
            NSLog(@"dataDict: %@", dataDict);
            //callback
            completionBlock(dataDict);
        }else{
            NSDictionary *errorDict = [message objectForKey:ERROR];
            DDLogError(@"Cannot create multiparty: errorDict: %@", errorDict);
            if (errorBlock) errorBlock ([NSError errorWithDomain:@"CreateMultiPartyError" code:200 userInfo:errorDict]);
        }
    }else{
        DDLogError(@"Invalid JSON received from server");
        if (errorBlock) errorBlock ([NSError errorWithDomain:@"CreateMultiPartyError" code:200 userInfo:userInfoWithDescription(@"Invalid JSON received from server")]);
    }
}

-(BOOL) isJsonResponseValid:(NSString *)responseString
{
    BOOL rez = YES;
    rez &= [responseString length] > 0;
    BOOL validJson = [JSONSchemaValidator validate:responseString embeddedSchema:CreateMultiPartyResponseSchema];
    rez &= validJson;
	
    return rez;
}


@end

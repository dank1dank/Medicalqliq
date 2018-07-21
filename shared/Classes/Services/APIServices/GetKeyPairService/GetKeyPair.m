//
//  GetKeyPair.m
//  qliq
//
//  Created by Vita on 7/19/12.
//  Copyright (c) 2012 Al Digit. All rights reserved.
//

#import "GetKeyPair.h"
#import "NotificationUtils.h"
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

@interface GetKeyPair ()

-(void) processResponseString:(NSString *)responseString onCompletion:(void(^)(NSString * privateKey, NSString * publicKey))completionBlock onError:(void (^)(NSError *error)) errorBlock;
-(void)getKeyPairOnCompletion:(void(^)(NSString * privateKey, NSString * publicKey))completionBlock onError:(void (^)(NSError *error)) errorBlock;
-(BOOL) isJsonResponseValid:(NSString *)responseString;

@end

@implementation GetKeyPair

+ (GetKeyPair *) sharedService{
    static dispatch_once_t pred;
    static id shared = nil;
    dispatch_once(&pred, ^{
        shared = [[GetKeyPair alloc] init];
        
    });
    return shared;
}

- (BOOL) isKeyPairInKeychain{
    return NO;
}

-(void) getKeyPair
{
    DDLogSupport(@"Starting getKeyPair");
    [self getKeyPairCompletitionBlock:nil];
    DDLogSupport(@"Finished getKeyPair");
}

-(void) getKeyPairCompletitionBlock:(CompletionBlock) completition
{
    [self getKeyPairOnCompletion:^(NSString * privateKey, NSString * publicKey) {
        if (completition) completition(CompletitionStatusSuccess, self, nil);
    } onError:^(NSError *error) {
        if (completition) completition(CompletitionStatusError, NO, error);
    }];
}

- (void)getKeyPairOnCompletion:(void(^)(NSString * privateKey, NSString * publicKey))completionBlock onError:(void (^)(NSError *error)) errorBlock
{
    
    __block NSString *username, *password, *clearTextPassword;
    UserSession *currentSession = [UserSessionService currentUserSession];
    username = currentSession.sipAccountSettings.username;
    password = currentSession.sipAccountSettings.password;
    clearTextPassword = [[UserSessionService currentUserSession].sipAccountSettings.password base64DecodedString];

    void (^errorHandler)(NSError * error) = ^(NSError * error){
        if (errorBlock) errorBlock(error);
    };
    void (^successHandler)(NSString * encryptedPrivateKeyStr, NSString * publicKey) = ^(NSString * encryptedPrivateKeyStr, NSString * publicKeyStr){
        
        NSLog(@"getKeyPair ended with privateKey: %@, publicKey: %@",encryptedPrivateKeyStr,publicKeyStr);

        NSString *errorMsg = nil;

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
            DDLogError(@"%@", errorMsg);
            
            if (errorBlock) {
                NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
                [errorDetail setValue:errorMsg forKey:NSLocalizedDescriptionKey];
                NSError *error = [NSError errorWithDomain:@"GetKeyPair" code:100 userInfo:errorDetail];
                errorBlock(error);
            }
        } else {
            if (completionBlock) {
                completionBlock(encryptedPrivateKeyStr, publicKeyStr);
            }
        }
    };
    
	NSDictionary *contentDict = [NSDictionary dictionaryWithObjectsAndKeys:
								 password, PASSWORD,
								 username, USERNAME,
                                 nil];
    
    NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:
							  contentDict, DATA,
							  nil];
	NSMutableDictionary *jsonDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     dataDict, MESSAGE,
                                     nil];
    NSLog(@"get_key_pair request: %@ ",[jsonDict JSONString]);
	if ([JSONSchemaValidator validate:[jsonDict JSONString] embeddedSchema:GetKeyPairRequestSchema]){
		
		RestClient *restClient = [RestClient clientForCurrentUser];
        
        [restClient postDataToServer:RegularWebServerType
                                path:@"services/get_key_pair"
                          jsonToPost:jsonDict onCompletion:^(NSString * responseDict)
		 {
             [self processResponseString:responseDict onCompletion:successHandler onError:errorHandler];
		 }
                             onError:^(NSError* error)
		 {
             errorHandler(error);
		 }];
	}else{
		NSLog(@"GetKeyPair: Invalid request sent to server");
        errorHandler([NSError errorWithDomain:@"GetKeyPairError" code:200 userInfo:[NSDictionary dictionaryWithObject:@"GetKeyPair: Invalid request sent to server" forKey:@"error"]]);
	}
}

-(void) processResponseString:(NSString *)responseString onCompletion:(void(^)(NSString * privateKey, NSString * publicKey))completionBlock onError:(void (^)(NSError *error)) errorBlock
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
            DDLogSupport(@"dataDict: %@", dataDict);
            
            NSString* privKey = [dataDict objectForKey:PRIVATE_KEY];
            NSString* pubKey =[dataDict objectForKey:PUBLIC_KEY];
            //callback
            completionBlock(privKey, pubKey);
        }else{
            NSDictionary *errorDict = [message objectForKey:ERROR];
            DDLogError(@"Cannot get key pair: errorDict: %@", errorDict);
            if (errorBlock) errorBlock ([NSError errorWithDomain:@"GetKeyPairError" code:200 userInfo:errorDict]);
        }
    }else{
        DDLogError(@"Invalid JSON received from server");
        if (errorBlock) errorBlock ([NSError errorWithDomain:@"GetKeyPairError" code:200 userInfo:userInfoWithDescription(@"Invalid JSON received from server")]);
    }
}

-(BOOL) isJsonResponseValid:(NSString *)responseString
{
    BOOL rez = YES;
    rez &= [responseString length] > 0;
    BOOL validJson = [JSONSchemaValidator validate:responseString embeddedSchema:GetKeyPairResponseSchema];
    rez &= validJson;
	
    return rez;
}


@end

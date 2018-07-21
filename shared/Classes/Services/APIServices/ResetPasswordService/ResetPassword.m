//
//  ResetPassword.m
//  qliq
//
//  Created by Vita on 7/19/12.
//  Copyright (c) 2012 Al Digit. All rights reserved.
//

#import "ResetPassword.h"
#import "JSONSchemaValidator.h"
#import "RestClient.h"
#import "QliqJsonSchemaHeader.h"
#import "JSONKit.h"
#import "UserSession.h"
#import "UserSessionService.h"
#import "KeychainService.h"
#import "QliqUserDBService.h"
#import "Helper.h"

@interface ResetPassword ()

-(void) processResponseString:(NSString *)responseString onCompletion:(void(^)(BOOL success, NSError * error)) block;
-(BOOL) isJsonResponseValid:(NSString *)responseString;

@end

@implementation ResetPassword

+ (ResetPassword *) sharedService{
    static dispatch_once_t pred;
    static id shared = nil;
    dispatch_once(&pred, ^{
        shared = [[ResetPassword alloc] init];
        
    });
    return shared;
}

- (void)resetPassword:(NSString*) email onCompletion:(void(^)(BOOL success, NSError * error)) block
{
    NSDictionary *contentDict = [NSDictionary dictionaryWithObjectsAndKeys:
								 email, EMAIL,
                                 nil];
    
    NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:
							  contentDict, DATA,
							  nil];
	NSMutableDictionary *jsonDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     dataDict, MESSAGE,
                                     nil];
    NSLog(@"reset_password request %@: ",[jsonDict JSONString]);
	if ([JSONSchemaValidator validate:[jsonDict JSONString] embeddedSchema:ResetPasswordRequestSchema]){
		
		RestClient *restClient = [RestClient clientForCurrentUser];
        
		[restClient postDataToServer:RegularWebServerType
                                path:@"services/reset_password"
                          jsonToPost:jsonDict onCompletion:^(NSString * responseDict)
		 {
             [self processResponseString:responseDict onCompletion:block];
         }
                             onError:^(NSError* error)
		 {
             if (block) block(NO, error);
             
		 }];
	}else{
		NSLog(@"resetPassword: Invalid request sent to server");
        if (block) block(NO, [NSError errorWithDomain:@"ResetPasswordError" code:200 userInfo:[NSDictionary dictionaryWithObject:@"ResetPasswordError: Invalid request sent to server" forKey:@"error"]]);
	}
}

-(void) processResponseString:(NSString *)responseString onCompletion:(void(^)(BOOL success, NSError * error)) block
{
    NSLog(@"reset_password responseString : %@ ",responseString);
    
    if([self isJsonResponseValid:responseString]){
        NSError *error = nil;
        NSData *jsonData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
        JSONDecoder *jsonKitDecoder = [JSONDecoder decoder];
        NSMutableDictionary *message = [[jsonKitDecoder objectWithData:jsonData error:&error] objectForKey:MESSAGE];
        
        NSDictionary *dataDict = [message objectForKey:DATA];
        if (dataDict)
        {
            DDLogSupport(@"dataDict: %@", dataDict);
            
            if (block) block(YES, nil);
        }else{
            NSDictionary *errorDict = [message objectForKey:ERROR];
            DDLogError(@"errorDict: %@", errorDict);
            if (block) block(NO, [NSError errorWithDomain:@"ResetPasswordError" code:200 userInfo:errorDict]);
        }
    }else{
        DDLogError(@"Invalid JSON received from server");
        if (block) block(NO, [NSError errorWithDomain:@"ResetPasswordError" code:200 userInfo:[NSDictionary dictionaryWithObject:@"Invalid JSON received from server" forKey:@"error"]]);
    }
    
}

-(BOOL) isJsonResponseValid:(NSString *)responseString
{
    BOOL rez = YES;
    rez &= [responseString length] > 0;
    BOOL validJson = [JSONSchemaValidator validate:responseString embeddedSchema:ResetPasswordResponseSchema];
    rez &= validJson;
	
    return rez;
}


@end

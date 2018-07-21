//
//  GetAvatar.m
//  qliq
//
//  Created by Ravi Ada on 05/29/12.
//  Copyright (c) 2012 qliqSoft Inc. All rights reserved.
//

#import "GetAvatar.h"
#import "JSONSchemaValidator.h"
#import "RestClient.h"
#import "QliqJsonSchemaHeader.h"
#import "JSONKit.h"
#import "WebClient.h"
#import "UserSession.h"
#import "UserSessionService.h"
#import "ContactService.h"
#import "QliqUserService.h"

@interface GetAvatar()

-(void) processResponseString:(NSString *)responseString andQliqId:(NSString *) qliqId andAvatarFilePath:(NSString *) filePath;

@end

@implementation GetAvatar

@synthesize delegate;

+ (GetAvatar *) sharedService{
    static dispatch_once_t pred;
    static id shared = nil;
    dispatch_once(&pred, ^{
        shared = [[GetAvatar alloc] init];
        
    });
    return shared;
}

- (NSString*)avatarsFolder {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask,YES);
    NSString *cachesDirectory = [paths objectAtIndex:0];
    NSString *userAvatarsDir = [cachesDirectory stringByAppendingPathComponent:@"Avatars"];
    if(![fileManager fileExistsAtPath:userAvatarsDir])
    {
        [fileManager createDirectoryAtPath:userAvatarsDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return userAvatarsDir;
}

-(void) getAvatar:(NSString*) qliqId
{
    UserSession *currentSession = [UserSessionService currentUserSession]; 
    NSString *username = currentSession.sipAccountSettings.username;
    NSString *password = currentSession.sipAccountSettings.password;            
	
    //TODO: get the qliq_id, device UUID and, current timestamp on the device
	NSDictionary *contentDict = [NSDictionary dictionaryWithObjectsAndKeys:
								 password, PASSWORD,
								 username, USERNAME,
								 qliqId, QLIQ_ID,
                                 nil];
    
    NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:
							  contentDict, DATA,
							  nil];
	NSMutableDictionary *jsonDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									 dataDict, MESSAGE,
									 nil];
   
    
    NSString *downloadPath = [NSString stringWithFormat:@"%@/%@.jpg",[self avatarsFolder],qliqId];
	
	if ([JSONSchemaValidator validate:[jsonDict JSONString] embeddedSchema:GetAvatarRequestSchema]){
		
		RestClient *restClient = [RestClient clientForCurrentUser];
		[restClient downloader:@"services/get_avatar" 
					jsonToPost:jsonDict 
						toFile:downloadPath 
				  onCompletion:^(NSString *responseString){
					  
					  [self processResponseString:responseString andQliqId:qliqId andAvatarFilePath:downloadPath];
					  
				  } onError:^(NSError* error){
					  
					  [UIAlertView showWithError:error];
				  }];
	}else{
		NSLog(@"GetAvatar: Invalid request sent to server");
	}
	
}

#pragma mark -
#pragma mark Private

-(void) processResponseString:(NSString *)responseString andQliqId:(NSString *) qliqId andAvatarFilePath:(NSString *) filePath
{
    NSError *error = nil;
    NSData *jsonData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
    JSONDecoder *jsonKitDecoder = [JSONDecoder decoder];
    NSMutableDictionary *message = [[jsonKitDecoder objectWithData:jsonData error:&error] objectForKey:MESSAGE];
	NSDictionary *errorDict = [message objectForKey:ERROR];
	NSDictionary *dataDict = [message objectForKey:DATA];
    if (!errorDict)
    {
        NSLog(@"dataDict: %@", dataDict);
		QliqUser *qliquser = [[QliqUserService sharedService] getUserWithId:qliqId];
		Contact *contact = [[ContactService sharedService] getContactById:qliquser.contactId];
		contact.avatarFilePath = filePath;
		[[ContactService sharedService] saveContact:contact];
		
        if ([UserSessionService currentUserSession].user.qliqId == qliqId) {
            [UserSessionService currentUserSession].user.avatarFilePath = filePath;
        }
    }
    else 
    {
        NSLog(@"errorDict: %@", errorDict);
	}
}
@end

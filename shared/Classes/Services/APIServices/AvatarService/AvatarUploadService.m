//
//  SetAvatar.m
//  qliq
//
//  Created by Ravi Ada on 05/29/12.
//  Copyright (c) 2012 qliqSoft Inc. All rights reserved.
//

#import "AvatarUploadService.h"
#import "JSONSchemaValidator.h"
#import "RestClient.h"
#import "QliqJsonSchemaHeader.h"
#import "JSONKit.h"
#import "UserSession.h"
#import "UserSessionService.h"

#import "QliqUser.h"
#import "ContactAvatarService.h"
#import "QliqUserDBService.h"

@interface AvatarUploadService ()

@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, strong) UIImage *avatar;
@property (nonatomic, strong) QliqUser *user;

@end

@implementation AvatarUploadService

- (id) initWithAvatar:(UIImage *)image forUser:(QliqUser *)user
{
    self = [super init];
    if (self) {
        self.user = user;
        self.avatar = image;
        self.filePath = [ContactAvatarService newAvatarPathForQliqUser:self.user];
        [self saveImage:image toPath:self.filePath];
    }
    return self;
}

- (void) saveImage:(UIImage *)image toPath:(NSString *)filePath
{
    if (filePath && filePath.length != 0) {
       
        NSError *error = nil;
        BOOL isExists = NO;
        BOOL isDirectory = NO;
        BOOL successRemoved = NO;
        
        isExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory];
        
        if (isExists && isDirectory) {
            DDLogSupport(@"filePath is a directory");
            successRemoved = [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
            if (error) {
                DDLogError(@"%@", [error localizedDescription]);
                error = nil;
            }
        } else {
            successRemoved = YES;
        }
        
        if (image && successRemoved) {
            NSData *imageData = UIImagePNGRepresentation(image);
            if ([imageData writeToFile:filePath options:(NSDataWritingAtomic) error:&error]) {
                DDLogSupport(@"Image was written successfuly");
            } else if(error) {
                DDLogError(@"%@", [error localizedDescription]);
            }
        } else {
            if (!image) {
                DDLogError(@"Try to save Nil image");
            } else {
                 DDLogError(@"Previous file wasn't removed");
            }
        }
    } else {
        DDLogError(@"filePath for save is nil");
    }
}

- (QliqAPIServiceType)type{
    return QliqAPIServiceTypeUpload;
}

- (Schema)requestSchema{
    return SetAvatarRequestSchema;
}

- (Schema)responseSchema{
    return SetAvatarResponseSchema;
}

- (NSString *) serviceName{
    return @"services/set_avatar";
}

- (NSString *)filePath{
    return _filePath;
}

- (NSDictionary *)requestJson{
    UserSession *currentSession = [UserSessionService currentUserSession];
    NSString *username = currentSession.sipAccountSettings.username;
    NSString *password = currentSession.sipAccountSettings.password;
    
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
    return jsonDict;
}

- (void) handleResponseMessageData:(NSDictionary *) dataDict withCompletition:(CompletionBlock) completitionBlock
{
    self.user.avatarFilePath = self.filePath;
    self.user.avatar = self.avatar;
    [[QliqUserDBService sharedService] saveUser:self.user];
 
    [[ContactAvatarService sharedService] changeAvatarForContact:self.user];
    
    if (completitionBlock) {
        completitionBlock(CompletitionStatusSuccess, nil, nil);
    }
}

@end

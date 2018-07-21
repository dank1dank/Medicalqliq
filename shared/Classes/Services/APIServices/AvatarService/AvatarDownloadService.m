//
//  AvatarAPIService.m
//  qliq
//
//  Created by Aleksey Garbarev on 15.08.12.
//
//
#import "Contact.h"
#import "RestClient.h"
#import "QliqUserDBService.h"
#import "AvatarDownloadService.h"
#import "ContactAvatarService.h"
#import "QliqJsonSchemaHeader.h"
#import "Helper.h"

@interface AvatarDownloadService ()

@property (strong, nonatomic) QliqUser *user;
@property (strong, nonatomic) NSString *outputPath;
@property (strong, nonatomic) NSString *urlString;

@end

@implementation AvatarDownloadService

- (id)initWithUser:(QliqUser *)user andUrlString:(NSString *)urlString
{
    
    self = [super init];
    if (self) {
        self.user = user;
        self.urlString = urlString;
        self.outputPath = [ContactAvatarService newAvatarPathForQliqUser:user];
        if ([self.user.qliqId isEqualToString:[Helper getMyQliqId]]) {
            DDLogSupport(@"Inited for user:%@, e-mail:%@, qliqId:%@", self.user.nameDescription, self.user.email, self.user.qliqId);
        }
    }
    return self;
}

- (void)callServiceWithCompletition:(CompletionBlock)completitionBlock
{
    if (!self.urlString) {
        return;
    }
    
    if ([self.user.qliqId isEqualToString:[Helper getMyQliqId]]) {
        DDLogSupport(@"Called for user:%@, e-mail:%@, qliqId:%@", self.user.nameDescription, self.user.email, self.user.qliqId);
    }
    
    if (self.outputPath.length != 0) {
        
        NSError *error = nil;
        BOOL isDirectory = NO;
        BOOL isExists = [[NSFileManager defaultManager] fileExistsAtPath:self.outputPath isDirectory:&isDirectory];
        if (isExists && isDirectory) {
            [[NSFileManager defaultManager] removeItemAtPath:self.outputPath error:&error];
            if(error){
                DDLogError(@"Directory at path: \n<%@>\n can't be removed with error: %@", self.outputPath, [error localizedDescription]);
            }
        }
        
        [[RestClient clientForCurrentUser] downloader:self.urlString toFile:self.outputPath downloadMode:RCDownloadModeRewrite onCompletion:^(NSString *responseDict) {
            [self handleSuccessWithCompletion:completitionBlock];
        } onError:^(NSError *error) {
            [self handleError:error withCompletion:completitionBlock];
        }];
    } else {
        DDLogError(@"Nil output path");
    }
}

- (void)handleSuccessWithCompletion:(CompletionBlock)block
{
    self.user.avatarFilePath = self.outputPath;
    BOOL isAvatarFilePathLength = self.user.avatarFilePath.length != 0;
    BOOL isDirectory = NO;
    BOOL isFileExists = [[NSFileManager defaultManager] fileExistsAtPath:self.user.avatarFilePath isDirectory:&isDirectory];
    
    if (isAvatarFilePathLength && isFileExists && !isDirectory) {
        if ([[NSFileManager defaultManager] isReadableFileAtPath:self.user.avatarFilePath] ) {

            // As it is leaking about 65 bytes per call.
//            UIImage *avatar = [[UIImage alloc] initWithContentsOfFile:self.user.avatarFilePath];
            UIImage *avatar = [UIImage imageWithContentsOfFile:self.user.avatarFilePath];
            
            if (!avatar) {
                NSError *error = nil;
                [[NSFileManager defaultManager] removeItemAtPath:self.user.avatarFilePath error:&error];
                if(error){
                    DDLogError(@"%@", [error localizedDescription]);
                }
                self.user.avatarFilePath = nil;
                self.user.avatar = nil;
                //                    DDLogError(@"empty avatar file");
            } else {
                self.user.avatar = avatar;
            }
            
            if (self.user.qliqId) {
                [[QliqUserDBService sharedService] saveUser:self.user];
                [[ContactAvatarService sharedService] changeAvatarForContact:self.user];
            }
        } else {
            DDLogError(@"Avatar File at:\n <%@>\n is not readable\n", self.user.avatarFilePath);
        }
    } else {
        DDLogError(@"File at path: \n<%@>\nexists: %@\nisDirectory:%@", self.user.avatarFilePath, isFileExists ? @"YES" : @"NO", isDirectory ? @"YES" : @"NO");
    }
    
    if (block) {
        block(CompletitionStatusSuccess, nil, nil);
    }
}

- (void)handleError:(NSError *)error withCompletion:(CompletionBlock)block;
{
    self.user.avatarFilePath = nil;
    self.user.avatar = nil;
    [[QliqUserDBService sharedService] saveUser:self.user];
    [[ContactAvatarService sharedService] changeAvatarForContact:self.user];
    
    if (block) {
        block(CompletitionStatusError, nil, error);
    }
}

@end

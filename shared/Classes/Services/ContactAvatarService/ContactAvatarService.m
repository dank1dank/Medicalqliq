//
//  ContactAvatarService.m
//  qliq
//
//  Created by Paul Bar on 4/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ContactAvatarService.h"

#import "QliqUserDBService.h"
#import "Contact.h"
#import "QliqUser.h"

@interface ContactAvatarService()

@property (nonatomic, strong) NSCache *avatarCache;

@end

@implementation ContactAvatarService

+ (ContactAvatarService *)sharedService {
    static dispatch_once_t pred;
    static id shared = nil;
    dispatch_once(&pred, ^{
        shared = [[ContactAvatarService alloc] init];
        
    });
    return shared;
}

- (id)init
{
    self = [super init];
    if(self)
    {
        self.avatarCache = [[NSCache alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didReceiveMemoryWarning:)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {

    [self.avatarCache removeAllObjects];
    self.avatarCache = nil;

}
- (void)didReceiveMemoryWarning:(NSNotification *)notificaiton {
    [self.avatarCache removeAllObjects];
}

- (NSString *)getCashKeyForContact:(id)contact {
    NSString *key = nil;
    
    if ([contact isKindOfClass:[Contact class]]) {
        key = [NSString stringWithFormat:@"avatar_%ld", (long)((Contact*)contact).contactId ];
    }
    else if ([contact isKindOfClass:[QliqUser class]]) {
        key = [NSString stringWithFormat:@"avatar_%llx", [((Contact*)contact).qliqId longLongValue] ];
    }
    
    return key;
}

- (UIImage *)getAvatarForContact:(id)contact {
    UIImage *avatarImage = nil;
    
    NSString *key = [self getCashKeyForContact:contact];
    
    UIImage *cachedAvatar = nil;
    
    @synchronized(self) {
        cachedAvatar = [self.avatarCache objectForKey:key];
    }
    
    if(cachedAvatar) {
        avatarImage = cachedAvatar;
    }
    else
    {
        if ([contact respondsToSelector:@selector(avatar)]) {
            avatarImage = [contact avatar];
        }
        
        if(avatarImage) {
            @synchronized(self) {
                [self.avatarCache setObject:avatarImage forKey:key];
            }
        }
    }
    
    return avatarImage;
}

- (void)changeAvatarForContact:(id)contact {
    
    if (contact){
        UIImage *avatarImage = nil;
        if ([contact respondsToSelector:@selector(avatar)]) {
            avatarImage = [contact avatar];
        }
        
        [self removeAvatarForContact:contact];
        
        if(avatarImage) {
            @synchronized(self) {
                NSString *key = [self getCashKeyForContact:contact];
                [self.avatarCache setObject:avatarImage forKey:key];
            
                NSDictionary *userInfo = [NSMutableDictionary dictionary];
                [userInfo setValue:contact forKey:@"contact"];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"UserHasChangeAvatar" object:nil userInfo:userInfo];
                
                if ([contact isKindOfClass:[QliqUser class]] && [((QliqUser *)contact).qliqId isEqualToString:[UserSessionService currentUserSession].user.qliqId]) {
                    [appDelegate updateLastUsers];
                }
            }
        }
    }
}

- (void)removeAvatarForContact:(id)contact {
    NSString *key = [self getCashKeyForContact:contact];
    
    @synchronized(self) {
        
        if ([self.avatarCache objectForKey:key]) {
            [self.avatarCache removeObjectForKey:key];
        }
    }
}

// M: Remove Avatar from avatarCache in order to reload a new avatar //
- (void)removeAvatarForUserId:(NSInteger)contactId
{
    NSString *key = [NSString stringWithFormat:@"avatar_%ld",(long)contactId];
    [self.avatarCache removeObjectForKey:key];
}

+ (NSString *)newAvatarPathForQliqUser:(QliqUser *)user
{
    NSString *newAvatarPath = @"";
    NSString *avatarBasePath = [kDecryptedDirectory stringByAppendingPathComponent:@"avatars"];
    
    if (user && user.qliqId.length !=0) {
        newAvatarPath = [avatarBasePath stringByAppendingPathComponent:user.qliqId];
    }
    
    return newAvatarPath;
}

@end

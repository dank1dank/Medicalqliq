//
//  ContactAvatarService.h
//  qliq
//
//  Created by Paul Bar on 4/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Contact, QliqUser;

@interface ContactAvatarService : NSObject

+ (ContactAvatarService *) sharedService;
+ (NSString *)newAvatarPathForQliqUser:(QliqUser *)user;

- (UIImage*)getAvatarForContact:(id)contact;
- (void)changeAvatarForContact:(id)contact;

- (void)removeAvatarForContact:(id)contact;
- (void)removeAvatarForUserId:(NSInteger)contactId;

@end

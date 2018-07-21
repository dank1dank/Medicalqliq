//
//  FindQliqUser.h
//  qliq
//
//  Created by Ravi Ada on 05/29/12.
//  Copyright (c) 2012 qliqSoft Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Contact, QliqUser;

@interface FindQliqUser : NSObject

+ (FindQliqUser *) sharedService;

- (void) checkForQliqUsers:(NSArray *) contactsArray completitionBlock:(void(^)(NSError *))block;
- (void) checkForQliqUserContact:(Contact *) contact completition:(void(^)(BOOL isMember, NSError * error)) block;
- (void) getQliqUserForContact:(Contact *) contact completition:(void(^)(QliqUser * user, NSError * error)) block;



@end

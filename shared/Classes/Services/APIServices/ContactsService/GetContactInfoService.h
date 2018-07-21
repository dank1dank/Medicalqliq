//
//  GetContactInfo.h
//  qliq
//
//  Created by Ravi Ada on 08/01/12.
//  Copyright (c) 2012 qliqSoft Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Contact;

@protocol GetContactInfoDelegate <NSObject>

-(void) GetContactInfoSuccess;
-(void) didFailToGetContactInfoWithReason:(NSString*)reason;

@end

@interface GetContactInfoService : NSOperation
{
}

typedef enum {GetContactInfoErrorCodeWebserverError, GetContactInfoErrorCodeInvalidRequest, GetContactInfoErrorCodeInvalidInfo} GetContactInfoErrorCode;

+ (GetContactInfoService *)sharedService;
- (void)getContactInfo:(NSString *)qliqId;
- (void)getContactInfo:(NSString *)qliqId completitionBlock:(void(^)(QliqUser *contact, NSError *error))completeBlock;

- (void)getContactByEmail:(NSString*)email completitionBlock:(void(^)(QliqUser *contact, NSError *error))completeBlock;
- (void)getContactByPhone:(NSString*)phone completitionBlock:(void(^)(QliqUser *contact, NSError *error))completeBlock;

- (void)getInfoForContact:(Contact *)contact withReason:(NSString*)reason conpletionBlock:(void(^)(QliqUser *contact, NSError *error))completionBlock;

@property (nonatomic, assign) id<GetContactInfoDelegate> delegate UNAVAILABLE_ATTRIBUTE;//Use blocks interface instead

@end

//
//  GetPublicKeys.h
//  qliq
//
//  Created by Ravi Ada on 05/29/12.
//  Copyright (c) 2012 qliqSoft Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ApiServiceBase.h"

@protocol GetPublicKeysDelegate <NSObject>
-(void) getPublicKeysSuccess:(NSString *)qliqId;
-(void) didFailToGetPublicKeysWithReason:(NSString *)qliqId withReason:(NSString*)reason withServiceErrorCode:(NSInteger)serviceErrorCode;

@end

@interface GetPublicKeys : ApiServiceBase

-(void) getPublicKeys:(NSString*) qliqId;
-(void) getPublicKeys:(NSString*) qliqId completitionBlock:(void(^)(NSString * qliqId, NSError * error))block;

@property (nonatomic, assign) id<GetPublicKeysDelegate> delegate;
@property (nonatomic, retain) NSString *requestQliqId;

@end

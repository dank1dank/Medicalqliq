//
//  UserAccountService.h
//  qliq
//
//  Created by Paul Bar on 2/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QliqApiManagerDelegate.h"
#import "ApiServiceBase.h"
#import "DBServiceBase.h"

@class UserSession;
@class QliqUser;

@protocol ReferringProviderServiceDelegate <NSObject>

@end

@interface ReferringProviderService : ApiServiceBase

-(void) getReferringProviderInfoForUser;

@property (nonatomic, assign) id<ReferringProviderServiceDelegate> delegate;

@end

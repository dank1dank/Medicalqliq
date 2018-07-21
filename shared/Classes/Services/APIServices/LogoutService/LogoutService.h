//
//  LogoutService.h
//  qliq
//
//  Created by Ravi Ada on 05/29/12.
//  Copyright (c) 2012 qliqSoft Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol LogoutServiceDelegate <NSObject>

@end

@interface LogoutService : NSOperation

@property (nonatomic, assign) id<LogoutServiceDelegate> delegate;

+ (LogoutService *)sharedService;

- (void)sentLogoutRequest;

@end

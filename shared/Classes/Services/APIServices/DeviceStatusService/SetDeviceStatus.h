//
//  SetDeviceStatus.h
//  qliq
//
//  Created by Vita on 7/19/12.
//  Copyright (c) 2012 Al Digit. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SetDeviceStatus : NSOperation
+ (SetDeviceStatus *) sharedService;

- (void)setDeviceStatusLock:(NSString*)lockState wipeState:(NSString*)wipeState onCompletion:(void(^)(BOOL success, NSError * error)) block;

// Calls the service with previous (saved) lock and wipe state and current app_in_background state
+ (void)setDeviceStatusCurrentAppStateWithCompletion:(void(^)(BOOL success, NSError * error)) block;

@end

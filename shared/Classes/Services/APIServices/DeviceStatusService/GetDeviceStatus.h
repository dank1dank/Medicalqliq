//
//  GetDeviceStatus.h
//  qliq
//
//  Created by Vita on 7/19/12.
//  Copyright (c) 2012 Al Digit. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  Notifies that there is device status change (lock, wipe)
 */
extern NSString *DeviceStatusNotification;

#define GetDeviceStatusLockFailed   @"lock failed"
#define GetDeviceStatusWipeFailed   @"wipe failed"
#define GetDeviceStatusLocked       @"locked"
#define GetDeviceStatusWiped        @"wiped"
#define GetDeviceStatusLocking      @"locking"
#define GetDeviceStatusWiping       @"wiping"
#define GetDeviceStatusUnlocking    @"unlocking"
#define GetDeviceStatusUnlocked     @"unlocked"
#define GetDeviceStatusNone         @"none"

@interface GetDeviceStatus : NSOperation

+ (GetDeviceStatus *)sharedService;

- (BOOL)isLockedInKeychain;

- (void)isDeviceLockedCompletition:(void(^)(BOOL locked, BOOL wiped, NSError *error))thisBlock;

- (void)getDeviceStatusOnCompletion:(void (^)(BOOL lock, BOOL wipeData))completionBlock
                            onError:(void (^)(NSError *error)) errorBlock;

@end

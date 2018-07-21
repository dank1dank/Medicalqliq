//
//  FailedAttempsController.h
//  qliq
//
//  Created by Aleksey Garbarev on 10/1/12.
//
//

#import <Foundation/Foundation.h>

@interface FailedAttemptsController : NSObject

- (NSInteger)countFailedAttempts;
- (void) lock;
- (NSTimeInterval)lockInterval;
- (void) increment;
- (void) clear;
- (BOOL) isLocked;
- (BOOL) shouldLock;
- (NSTimeInterval) timeIntervalToUnlock;
- (NSUInteger) maxAttempts;

- (void) unlockWithCompletion:(void(^)(void))block;
- (void) setDidLockBlock:(void(^)(BOOL isLocked)) lockBlock;
- (void) setCountdownBlock:(void(^)(NSTimeInterval invervalToUnlock)) countdownBlock;

@end

//
//  DispatchExtras.h
//  Eyeris
//
//  Created by Ivan Zezyulya on 15.02.12.
//  Copyright (c) 2012 1618Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif

void Dispatch_AfterDelay(dispatch_queue_t queue, NSTimeInterval afterInterval, dispatch_block_t block);
void Dispatch_AfterDelay_ToMainThread(NSTimeInterval afterInterval, dispatch_block_t block);

void Dispatch_ToMainThread(dispatch_block_t block);
void Dispatch_ToBackgroundDefaultPriority(dispatch_block_t block);
void Dispatch_ToBackgroundHighPriority(dispatch_block_t block);
void Dispatch_ToBackgroundLowPriority(dispatch_block_t block);
void Dispatch_ToBackgroundBackgroundPriority(dispatch_block_t block);


@interface WaitCondition : NSObject
- (void) fire;
- (void) reset;
@end

void Dispatch_NotifyForConditions(NSArray *conditions, dispatch_block_t completion); // conditions should contain WaitCondition's

#ifdef __cplusplus
} // extern "C"
#endif

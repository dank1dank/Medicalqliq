//
//  DispatchExtras.m
//  Eyeris
//
//  Created by Ivan Zezyulya on 15.02.12.
//  Copyright (c) 2012 1618Labs. All rights reserved.
//

#import "DispatchExtras.h"

void Dispatch_AfterDelay(dispatch_queue_t queue, NSTimeInterval afterInterval, dispatch_block_t block)
{
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, afterInterval * NSEC_PER_SEC);
    dispatch_after(delay, queue, block);
}

void Dispatch_AfterDelay_ToMainThread(NSTimeInterval afterInterval, dispatch_block_t block)
{
    Dispatch_AfterDelay(dispatch_get_main_queue(), afterInterval, block);
}

void Dispatch_ToMainThread(dispatch_block_t block)
{
    dispatch_async(dispatch_get_main_queue(), block);
}

void Dispatch_ToBackgroundDefaultPriority(dispatch_block_t block)
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block);
}

void Dispatch_ToBackgroundHighPriority(dispatch_block_t block)
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), block);
}

void Dispatch_ToBackgroundLowPriority(dispatch_block_t block)
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), block);
}

void Dispatch_ToBackgroundBackgroundPriority(dispatch_block_t block)
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), block);
}


@implementation WaitCondition {
    int clients;
    NSCondition *condition;
}

- (id) init
{
    if ((self = [super init])) {
        condition = [NSCondition new];
    }
    return self;
}

- (void) reset
{
    @synchronized(self) {
        clients = 0;
    }
}

- (void) fire
{
    [condition lock];
    if (clients == 0) {
        clients--;
    }
    while (clients > 0) {
        [condition signal];
        clients--;
    }
    [condition unlock];
}

- (void) wait
{
    [condition lock];
    clients++;
    while (clients > 0) {
        [condition wait];
    }
    [condition unlock];
}

@end

void Dispatch_NotifyForConditions(NSArray *conditions, dispatch_block_t completion)
{
    dispatch_queue_t queue = dispatch_queue_create("notify_queue", NULL);
    dispatch_group_t group = dispatch_group_create();

    for (WaitCondition *condition in conditions)
    {
        NSCAssert([condition isKindOfClass:[WaitCondition class]], ([NSString stringWithFormat:@"%s: conditions must contain %@ objects only", __func__, NSStringFromClass([WaitCondition class])]));
        dispatch_group_async(group, queue, ^{
            [condition wait];
        });
    }

    dispatch_group_notify(group, queue, ^{
        Dispatch_ToMainThread(completion);
    });

    dispatch_release(queue);
    dispatch_release(group);
}

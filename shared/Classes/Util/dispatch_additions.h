//
//  dispatch_additions.h
//  qliq
//
//  Created by Aleksey Garbarev on 11/26/12.
//
//

#import <Foundation/Foundation.h>
#import "CocoaLumberjack.h"

static __inline__ void dispatch_sync_main(void(^block)(void)){
    dispatch_queue_t queue = dispatch_get_main_queue();

    if (![NSThread isMainThread] && [NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]) {
        DDLogWarn(@"Deadlock must be here.. =)");
    }
    
    if ([NSThread isMainThread]){
        block();
    }else{
        dispatch_sync(queue, block);
    }
}

static __inline__ void dispatch_async_main(void(^block)(void))
{
    dispatch_async(dispatch_get_main_queue(), block);
}

static __inline__ void dispatch_async_background(void(^block)(void))
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), block);
}

static __inline__ void dispatch_async_main_after(NSTimeInterval delayInSeconds, void(^block)(void))
{
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), block);
}

static __inline__ void dispatch_async_after(NSTimeInterval delayInSeconds, dispatch_queue_t queue, void(^block)(void))
{
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, queue, block);
}


//
//  NSOperationQueues_Additions.h
//  qliq
//
//  Created by Valerii Lider on 11/1/16.
//
//

#import <Foundation/Foundation.h>
#import "CocoaLumberjack.h"

static __inline__ BOOL isCurrentThreadMain() {
    return [[NSOperationQueue currentQueue] isEqual:[NSOperationQueue mainQueue]] && [[NSOperationQueue currentQueue].underlyingQueue isEqual:dispatch_get_main_queue()];
}

static __inline__ void performBlockOnQueue(BOOL sync, NSOperationQueue *queue, void(^block)(void))
{
    if (block) {
        if ([[NSOperationQueue currentQueue] isEqual:queue])
        {
            block();
        }
        else
        {
            if (sync)
            {
                NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:block];
                [queue addOperations:@[operation] waitUntilFinished:YES];
            }
            else
            {
                [queue addOperationWithBlock:block];
            }
        }
    }
}

static __inline__ void performBlockInMainThread(void(^block)(void))
{
    performBlockOnQueue(NO, [NSOperationQueue mainQueue], block);
}

static __inline__ void performBlockInMainThreadSync(void(^block)(void))
{
    performBlockOnQueue(YES, [NSOperationQueue mainQueue], block);
}

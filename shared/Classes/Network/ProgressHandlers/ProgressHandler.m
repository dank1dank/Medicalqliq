//
//  ProgressHandler.m
//  qliq
//
//  Created by Aleksey Garbarev on 27.11.12.
//
//

#import "ProgressHandler.h"

@interface ProgressHandler()

@property (nonatomic, readwrite) CGFloat currentProgress;
@property (nonatomic, readwrite) ProgressState currentState;


@end

@implementation ProgressHandler{
    BOOL cancel;
}

@synthesize observer;
@synthesize onCancel;

- (id)init{
    self = [super init];
    if (self) {
        cancel = NO;
    }
    return self;
}

- (void) setObserver:(id<ProgressObserver>)_observer{
    observer = _observer;
}

- (void) setState:(ProgressState) state{
    if (self.currentState != state){
        self.currentState = state;
        __weak __block typeof(self) welf = self;
        dispatch_async_main(^{
            if ([welf.observer respondsToSelector:@selector(progressHandler:didChangeState:)]){
                [welf.observer progressHandler:self didChangeState:self.currentState];
            }
        });
    }
}

- (void) setProgress:(CGFloat) value{
    if (self.currentProgress != value){
        self.currentProgress = value;
            if (self && self.observer) {
                if ([self.observer respondsToSelector:@selector(progressHandler:didChangeProgress:)]){
                    [self.observer progressHandler:self didChangeProgress:self.currentProgress];
                } else {
                    DDLogError(@"Progress handler. Set progress error. NIL observer");
                }
            }
    }
}

- (BOOL) shouldCancelProgress{
    
    if (cancel)
        DDLogWarn(@"Will cancel progress");
    
    return cancel;
}

- (void) cancel{
    cancel = YES;

    if (self.onCancel) self.onCancel();
}

- (void)dealloc{
    DDLogSupport(@"ProgressHandler dealloced");
}

@end


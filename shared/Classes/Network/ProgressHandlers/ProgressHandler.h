//
//  ProgressHandler.h
//  qliq
//
//  Created by Aleksey Garbarev on 27.11.12.
//
//

#import <Foundation/Foundation.h>

typedef enum {ProgressStateDownloading, ProgressStateUploading, ProgressStateCancelled, ProgressStateError, ProgressStateComplete} ProgressState;

@protocol ProgressObserver;

@interface ProgressHandler : NSObject

@property (nonatomic, readonly) CGFloat currentProgress;
@property (nonatomic, readonly) ProgressState currentState;

/* Don't forget to set progressHandler.observer = nil in observer's dealloc since weak unavailable */
@property (nonatomic, unsafe_unretained) id<ProgressObserver> observer;

@property (nonatomic, strong) void(^onCancel)(void);

- (void) setState:(ProgressState) state;
- (void) setProgress:(CGFloat) value;

- (BOOL) shouldCancelProgress;

- (void) cancel;

@end

@protocol ProgressObserver <NSObject>

- (void) progressHandler:(ProgressHandler *) progressHandler didChangeProgress:(CGFloat) progress;
- (void) progressHandler:(ProgressHandler *) progressHandler didChangeState:(ProgressState) state;

@end
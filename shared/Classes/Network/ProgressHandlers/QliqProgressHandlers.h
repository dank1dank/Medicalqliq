//
//  QliqProgressHandlers.h
//  qliq
//
//  Created by Aleksey Garbarev on 27.11.12.
//
//

#import <Foundation/Foundation.h>

#import "ProgressHandler.h"

@interface QliqProgressHandlers : NSObject


- (void) setProgressHandler:(ProgressHandler *) handler forKey:(id <NSCopying>) key;
- (ProgressHandler *) progressHandlerForKey:(id<NSCopying>) key;
- (void) removeProgressHandlerForKey:(id<NSCopying>) key;

- (void)cancelAllProgressHandlers;

@end

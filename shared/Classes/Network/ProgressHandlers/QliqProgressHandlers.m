//
//  QliqProgressHandlers.m
//  qliq
//
//  Created by Aleksey Garbarev on 27.11.12.
//
//

#import "QliqProgressHandlers.h"

@interface QliqProgressHandlers()

@end

@implementation QliqProgressHandlers{
    NSMutableDictionary * progressHandlers;
}

- (id)init{
    self = [super init];
    if (self) {
        progressHandlers = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void) setProgressHandler:(ProgressHandler *) handler forKey:(id <NSCopying>) key{
    [progressHandlers setObject:handler forKey:key];
}

- (ProgressHandler *) progressHandlerForKey:(id<NSCopying>) key{
    return [progressHandlers objectForKey:key];
}

- (void) removeProgressHandlerForKey:(id<NSCopying>) key{
    [progressHandlers removeObjectForKey:key];
}

- (void)cancelAllProgressHandlers {
    for (ProgressHandler *ph in [progressHandlers allValues]) {
        [ph cancel];
    }
}

@end

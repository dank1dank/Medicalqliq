//
//  ABTimeCounter.m
//  qliq
//
//  Created by Adam Sowa on 31/03/15.
//
//

#import "ABTimeCounter.h"

@interface ABTimeCounter ()

@property (nonatomic, assign) BOOL isCounting;

@property (nonatomic, readwrite) NSTimeInterval accumulatedTime;

@property (nonatomic, strong) NSDate *lastStartDate;

@end

@implementation ABTimeCounter

#pragma mark Properties overload

- (NSTimeInterval)measuredTime {
    return self.accumulatedTime + [self p_timeSinceLastStart];
}

#pragma mark - Public

/**
 *  Reset timer
 */
- (void)reset
{
    self.accumulatedTime = 0;
    self.lastStartDate = nil;
    self.isCounting = NO;
}

/**
 *  Restart timer
 */
- (void)restart
{
    self.accumulatedTime = 0;
    self.lastStartDate = [NSDate date];
    self.isCounting = YES;
}

/**
 *  Pause timer
 */
- (void)pause
{
    if (self.isCounting) {
        self.accumulatedTime += [self p_timeSinceLastStart];
        self.lastStartDate = nil;
        self.isCounting = NO;
    }
}

/**
 *  Resume timer
 */
- (void)resume
{
    if (!self.isCounting) {
        self.lastStartDate = [NSDate date];
        self.isCounting = YES;
    }
}

#pragma mark - Private

/**
 *  Get time interval
 *
 *  @return time interval since last Start date
 */
- (NSTimeInterval)p_timeSinceLastStart
{
    if (self.isCounting) {
        return [[NSDate date] timeIntervalSinceDate:self.lastStartDate];
    }
    else {
        return 0;
    }
}

@end
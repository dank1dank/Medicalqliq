//
//  ABTimeCounter.h
//  qliq
//
//  Created by Adam Sowa on 31/03/15.
//
//
#import <Foundation/Foundation.h>

@interface ABTimeCounter : NSObject

@property (nonatomic, readonly) NSTimeInterval measuredTime;

/**
 *  Restart timer
 */
- (void)restart;
- (void)pause;
- (void)resume;
- (void)reset;

@end
//
//  TimerNotifier.h
//  qliq
//
//  Created by Paul Bar on 3/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TimerNotifier : NSObject

-(id) initWithTimeInterval:(NSTimeInterval)seconds;

- (void) startNotifications;
- (void) cancelNotifications;

@end

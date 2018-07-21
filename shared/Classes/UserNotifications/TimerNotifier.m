//
//  TimerNotifier.m
//  qliq
//
//  Created by Paul Bar on 3/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TimerNotifier.h"
#import "UserNotifications.h"
#import "ChatMessage.h"

@interface TimerNotifier()

@property (nonatomic, strong) NSTimer *timer;

-(void) timerTick;

@end

@implementation TimerNotifier{
    NSTimeInterval interval;
}
@synthesize timer;

-(id) initWithTimeInterval:(NSTimeInterval)seconds
{
    self = [super init];
    if(self)
    {
        interval = seconds;
    }
    return self;
}

-(void) dealloc
{
    [self cancelNotifications];
}


- (void) startNotifications{
    DDLogSupport(@"start notifications");
    [self cancelNotifications];
    
    self.timer = [NSTimer timerWithTimeInterval:interval target:self selector:@selector(timerTick) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    [self.timer fire];
    
}
- (void) cancelNotifications{
    DDLogSupport(@"cancel notifications");
    [self.timer invalidate];
    self.timer = nil;
}


#pragma mark -
#pragma mark Private

-(void) timerTick
{
    DDLogSupport(@"tick!");
    //if we need to notify user about unhandled events we can do it here
    int count = [ChatMessage unreadMessagesCount];
    if(count > 0){
        [[UserNotifications getInstance] notifyUnreadMessages:count];
    }else{
        [self cancelNotifications];
    }
}

@end

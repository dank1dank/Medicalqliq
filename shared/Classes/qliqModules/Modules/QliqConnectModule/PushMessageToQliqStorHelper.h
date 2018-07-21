//
//  PushMessageToQliqStorHelper.h
//  qliq
//
//  Created by Adam Sowa on 10/18/12.
//
//

#import <Foundation/Foundation.h>

@class QliqStorClient;
@class ChatMessage;

@interface PushMessageToQliqStorHelper : NSObject

- (void) setQliqStorClient:(QliqStorClient *)client;
- (BOOL) isPushInProgress;
- (void) startPushing;
- (void) stopPushing;

+ (void) setMessageUnpushedToAllQliqStors: (ChatMessage *)msg;
+ (NSSet *) qliqStorsForMessage: (ChatMessage *)msg;

@end
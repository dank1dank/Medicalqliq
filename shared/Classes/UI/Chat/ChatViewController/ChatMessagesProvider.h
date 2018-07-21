//
//  ChatMessagesGetter.h
//  qliq
//
//  Created by Paul Bar on 2/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ChatMessage;
@interface ChatMessagesProvider : NSObject

- (id) initWithConversationId:(NSInteger) conversationId;

- (void) fetchMessagesInRange:(NSRange) range async:(BOOL) async complete:(void(^)(NSArray * messages))completeBlock;
/* Async API */
- (void) fetchMessagesInRange:(NSRange) range complete:(void(^)(NSArray * messages))completeBlock;
/* Sync API */
- (NSArray *) fetchMessagesInRange:(NSRange) range;

- (ChatMessage *) fetchMessageWithUUID:(NSString *) uuid;

@end


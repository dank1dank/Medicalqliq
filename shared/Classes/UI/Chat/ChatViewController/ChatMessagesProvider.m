//
//  ChatMessagesGetter.m
//  qliq
//
//  Created by Paul Bar on 2/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ChatMessagesProvider.h"
#import "ChatMessage.h"
#import "MessageAttachmentDBService.h"
#import "DBHelperConversation.h"
#import "ChatMessageService.h"

@interface ChatMessagesProvider()

@property (nonatomic, readwrite) NSInteger conversationId;

@end

@implementation ChatMessagesProvider{
    dispatch_queue_t fetchQueue;
}

@synthesize conversationId;

- (id) initWithConversationId:(NSInteger) _conversationId{
    self = [super init];
    if(self){
        self.conversationId = _conversationId;
        
        fetchQueue = dispatch_queue_create("message_fetch_queue", NULL);
        dispatch_set_target_queue(fetchQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0));
    }
    return self;
}

- (void)dealloc{
    if (fetchQueue) {
        
//        dispatch_release(fetchQueue);
        fetchQueue = NULL;
    }
}

- (void)fetchMessagesInRange:(NSRange)range async:(BOOL)async complete:(void(^)(NSArray *messages))completeBlock {
    
    __weak __block typeof(self) welf = self;
    void(^runBlock)(void) = ^{
        NSArray * result = nil;
        
        if (range.length > 0) {
            result = [[ChatMessageService sharedService] getMessagesForConversation:welf.conversationId pageSize:range.length pageOffset:range.location];
        }
        
        if (completeBlock) {
            completeBlock(result);
        }
    };

    if (async) {
        dispatch_async(fetchQueue, runBlock);
    }
    else {
        runBlock();
    }
}

/* Async API */
- (void) fetchMessagesInRange:(NSRange) range complete:(void(^)(NSArray * messages))completeBlock{
    
    [self fetchMessagesInRange:range async:YES complete:completeBlock];
    
}
/* Sync API */
- (NSArray *) fetchMessagesInRange:(NSRange) range{
    DDLogInfo(@"pagesToLoad: [%lu, %lu]", (unsigned long)range.location, (unsigned long)range.length);
    __block NSArray * messageArray = nil;
    
    [self fetchMessagesInRange:range async:NO complete:^(NSArray *messages) {
        messageArray = messages;
    }];
    
    return messageArray;
}

- (ChatMessage *) fetchMessageWithUUID:(NSString *) uuid{
        
    return [DBHelperConversation getMessageWithGuid:uuid];;
}


@end

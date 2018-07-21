//
//  ChatMessagesGetter.m
//  qliq
//
//  Created by Paul Bar on 2/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ChatMessagesGetter.h"
#import "ChatMessage.h"
#import "MessageAttachmentDBService.h"

@interface ChatMessagesGetter()

-(void) getMessagesBackgroundSelector:(NSNumber*)conversationId;
-(void) notifyGotMessages:(NSArray*)messages;
-(void) getMessagesPageBackground:(PageParams*)pageParams;

@property (nonatomic,retain) MessageAttachmentDBService *attachmentDbService;

@end

@implementation ChatMessagesGetter
@synthesize delegate;
@synthesize attachmentDbService;


-(id) init
{
    self = [super init];
    if(self)
    {
        attachmentDbService = [[MessageAttachmentDBService alloc] init];

    }
    return self;
}

-(void) dealloc
{
    [attachmentDbService release];
    [super dealloc];
}

-(void) getMessages:(NSNumber *)conversationId
{
    [self performSelectorInBackground:@selector(getMessagesBackgroundSelector:) withObject:conversationId];
}

-(NSArray*) getMessagesPageForConversarion:(NSNumber*)conversationId pageSize:(NSNumber*)pageSize pageOffset:(NSNumber*)pageOffset
{
    return [ChatMessage getMessagesForConversation:[conversationId intValue] pageSize:10 pageOffset:[pageOffset intValue]];
}

-(void) getMessages:(NSNumber *)conversationId pageSize:(NSNumber *)pageSize offset:(NSNumber *)offset inBackground:(BOOL) _background{
    //NSLog(@"ConversationId = %d", [conversationId intValue]);
    PageParams *p = [[PageParams alloc] init];
    p.conversationId = conversationId;
    p.pageSize = pageSize;
    p.pageOffset = offset;

    if (_background){
        [self performSelectorInBackground:@selector(getMessagesPageBackground:) withObject:p];    
    }else{
        [self getMessagesPageBackground:p];
    }
    
    [p release];
}

-(void) getMessages:(NSNumber *)conversationId pageSize:(NSNumber *)pageSize offset:(NSNumber *)offset
{
    //NSLog(@"ConversationId = %d", [conversationId intValue]);
    PageParams *p = [[PageParams alloc] init];
    p.conversationId = conversationId;
    p.pageSize = pageSize;
    p.pageOffset = offset;
    [self performSelectorInBackground:@selector(getMessagesPageBackground:) withObject:p];
    [p release];
}


-(void) notifyGotMessages:(NSArray *)messages
{
    [self.delegate didGetMessages:messages];
}


-(void) getMessagesBackgroundSelector:(NSNumber *)conversationId
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSArray *messageArray = [ChatMessage getMessagesForConversation:[conversationId intValue] pageSize:10 pageOffset:0];
    [self performSelectorOnMainThread:@selector(notifyGotMessages:) withObject:messageArray waitUntilDone:NO];
    [pool release];
}

-(void) getMessagesPageBackground:(PageParams *)pageParams
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSArray *messageArray = [ChatMessage getMessagesForConversation:[pageParams.conversationId intValue]
                                                           pageSize:[pageParams.pageSize intValue]
                                                         pageOffset:[pageParams.pageOffset intValue]];
    for(ChatMessage *message in messageArray)
    {
        message.attachments = [attachmentDbService getAttachmentsForMessage:message];
    }
    [self performSelectorOnMainThread:@selector(notifyGotMessages:) withObject:messageArray waitUntilDone:NO];
    [pool release];
}


@end


@implementation PageParams

@synthesize conversationId;
@synthesize pageSize;
@synthesize pageOffset;

-(void) dealloc
{
    [conversationId release];
    [pageSize release];
    [pageOffset release];
    [super dealloc];
}

@end
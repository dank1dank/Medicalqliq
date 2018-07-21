//
//  ChatMessagesGetter.h
//  qliq
//
//  Created by Paul Bar on 2/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ChatMessageGetterDelegate <NSObject>

-(void) didGetMessages:(NSArray *)messages;

@end
@interface ChatMessagesGetter : NSObject

-(void) getMessages:(NSNumber*) conversationId;
-(NSArray*) getMessagesPageForConversarion:(NSNumber*)conversationId pageSize:(NSNumber*)pageSize pageOffset:(NSNumber*)pageOffset;
-(void) getMessages:(NSNumber *)conversationId pageSize:(NSNumber *)pageSize offset:(NSNumber *)offset;
-(void) getMessages:(NSNumber *)conversationId pageSize:(NSNumber *)pageSize offset:(NSNumber *)offset inBackground:(BOOL) _background;

@property (nonatomic, assign) id<ChatMessageGetterDelegate> delegate;

@end


@interface PageParams : NSObject 
@property(nonatomic,retain) NSNumber *conversationId;
@property(nonatomic,retain) NSNumber *pageSize;
@property(nonatomic,retain) NSNumber *pageOffset;
@end


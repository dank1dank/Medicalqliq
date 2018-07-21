//
//  MessageAttachmentDBService.h
//  qliq
//
//  Created by Paul Bar on 4/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//


#import "FMDatabase.h"
#import "QliqDBService.h"

@class MessageAttachment;
@class ChatMessage;

@interface MessageAttachmentDBService : QliqDBService

+ (id) sharedService;

-(NSArray*) getAttachmentsForMessageUuid:(NSString *)uuid;
-(NSArray*) getAttachmentsForMessage:(ChatMessage*)message;
-(NSArray*) getAttachmentsForMediaFileId:(NSInteger)mediaFileId;
-(NSArray*) getAttachmentsForDownloadURL:(NSString *)urlString;
-(void) deleteAttachment:(MessageAttachment *)attachment;
-(BOOL) deleteAllAttachments;

@end

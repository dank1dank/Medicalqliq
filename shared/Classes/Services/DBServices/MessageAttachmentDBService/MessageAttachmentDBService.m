//
//  MessageAttachmentDBService.m
//  qliq
//
//  Created by Paul Bar on 4/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MessageAttachmentDBService.h"
#import "MessageAttachment.h"
#import "ChatMessage.h"
#import "MediaFile.h"
#import "NSData+Base64.h"
#import "MediaFileDBService.h"

@implementation MessageAttachmentDBService

+ (MessageAttachmentDBService *) sharedService{
    static dispatch_once_t pred;
    static MessageAttachmentDBService * shared = nil;
    dispatch_once(&pred, ^{
        shared = [[MessageAttachmentDBService alloc] init];
        
    });
    return shared;
}

- (NSArray *) getAttachmentsForMessage:(ChatMessage *)message
{
    return [self getAttachmentsForMessageUuid:message.metadata.uuid];
}

- (NSArray *) attachmentsFromDecoders:(NSArray *)decoders
{
    NSMutableArray *attachments = [[NSMutableArray alloc] initWithCapacity:[decoders count]];
    for (DBCoder * decoder in decoders) {
        MessageAttachment * attachment = [self objectOfClass:[MessageAttachment class] fromDecoder:decoder];
        [attachments addObject:attachment];
    }
    return attachments;
}

- (NSArray*) getAttachmentsForMessageUuid:(NSString *)uuid
{
    if (!uuid || ![uuid isKindOfClass:[NSString class]]) {
    
        return @[];
    }
    
    NSString * selectQuery = @"SELECT * FROM message_attachment WHERE uuid = ?";
  
    NSArray * decoders = [self decodersFromSQLQuery:selectQuery withArgs:@[uuid]];
    
    return [self attachmentsFromDecoders:decoders];
}

- (NSArray*) getAttachmentsForMediaFileId:(NSInteger)mediaFileId;
{
    NSString * selectQuery = @"SELECT * FROM message_attachment WHERE mediafile_id = ?";
    
    NSArray * decoders = [self decodersFromSQLQuery:selectQuery withArgs:@[[NSNumber numberWithInteger:mediaFileId]]];
    
    return [self attachmentsFromDecoders:decoders];
}

-(NSArray*) getAttachmentsForDownloadURL:(NSString *)urlString
{
    NSString * selectQuery = @"SELECT * FROM message_attachment WHERE url = ?";
    
    NSArray * decoders = [self decodersFromSQLQuery:selectQuery withArgs:@[urlString]];
    
    return  [self attachmentsFromDecoders:decoders];
}

-(void) deleteAttachment:(MessageAttachment *)attachment
{
    NSArray *attachmentsWithSameMediaFile = [self getAttachmentsForMediaFileId:attachment.mediaFile.mediafileId];
    if ([attachmentsWithSameMediaFile count] == 1) {
        [[MediaFileDBService sharedService] deleteMediaFile:attachment.mediaFile];
    }
    [self deleteObject:attachment mode:DBModeSingle completion:nil];
}

- (BOOL) deleteAllAttachments
{
    __block BOOL ret = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        ret = [db executeUpdate:@"DELETE FROM message_attachment"];
    }];
    return ret;
}


@end
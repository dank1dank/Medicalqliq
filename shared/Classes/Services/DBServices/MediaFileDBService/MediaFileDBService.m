//
//  MediaFileDBService.m
//  qliq
//
//  Created by Aleksey Garbarev on 12/25/12.
//
//

#import "MediaFileDBService.h"
#import "MediaFileService.h"
#import "DBUtil.h"
#import "MessageAttachment.h"
#import "MessageAttachmentDBService.h"
#import "ChatMessageService.h"
#import "QliqConnectModule.h"
#import "NotificationUtils.h"
#import "ThumbnailService.h"

@implementation MediaFileDBService

+ (MediaFileDBService *) sharedService{
    
    static dispatch_once_t pred;
    static MediaFileDBService * shared = nil;
    dispatch_once(&pred, ^{
        shared = [[MediaFileDBService alloc] init];
    });
    return shared;
}

/* Override to delete content with mediafile */
- (void) deleteObject:(id<DBCoding>)object as:(Class) objectClass mode:(DBMode)mode completion:(DBDeleteCompletion)completion
{
    if ([object isKindOfClass:[MediaFile class]]) {
        [self deleteContentsOfMediaFile:object];
    }
    
    [super deleteObject:object as:objectClass mode:objectClass completion:completion];
    [NSNotificationCenter postNotificationToMainThread:kRemoveMediaFileAndAttachmentNotification withObject:nil userInfo:nil];
}

- (NSArray *) mediafilesFromDecoders:(NSArray *) decoders{
    
    NSMutableArray * mediafiles = [[NSMutableArray alloc] init];
    
    for (DBCoder * decoder in decoders){
        MediaFile * mediafile = [self objectOfClass:[MediaFile class] fromDecoder:decoder];
        [mediafiles addObject:mediafile];
    }
    
    return mediafiles;
}

- (NSArray*) mediafiles
{
    NSString *selectQuery = @"SELECT * FROM mediafiles";
    
    NSArray * decoders = [self decodersFromSQLQuery:selectQuery withArgs:nil];
    
    return [self mediafilesFromDecoders:decoders];
}

- (NSArray*) mediafilesWithMimeTypes:(NSArray *)mimeTypes archived:(BOOL)archived{
    
    NSString *typesString = [NSString stringWithFormat:@"('%@')",[mimeTypes componentsJoinedByString:@"','"]];
    
    NSString *selectQuery = [NSString stringWithFormat:@"SELECT * FROM mediafiles WHERE deleted = 0 AND archived = %d AND file_mime_type IN %@",
                             archived,
                             typesString];
    
    NSArray *decoders = [self decodersFromSQLQuery:selectQuery withArgs:nil];
    
    return [self mediafilesFromDecoders:decoders];
}

- (NSInteger)countOfMediaFilesWithMimeTypes:(NSArray *)mimeTypes containsFormatInName:(NSString *)nameFormat
{
    NSString *typesString = [NSString stringWithFormat:@"('%@')",[mimeTypes componentsJoinedByString:@"','"]];
    NSString *selectQuery = [NSString stringWithFormat:@"SELECT COUNT(id) AS MEDIAFILES_COUNT "
                             "FROM (SELECT id FROM mediafiles WHERE deleted = 0 "
                             "AND file_mime_type IN %@ AND file_name LIKE '%@%%')", typesString, nameFormat];
    
    NSArray *decoders = [self decodersFromSQLQuery:selectQuery withArgs:nil];
    NSInteger res = 0;
    if (decoders.count != 0) {
        
        id result = [((DBCoder *)decoders.firstObject) decodeObjectForColumn:@"MEDIAFILES_COUNT"];
        res = [result unsignedIntegerValue];
    }
    return res;
}

- (MediaFile *) mediafileWithId:(NSInteger)mediafileId
{
    return [self objectWithId:[NSNumber numberWithInteger:mediafileId] andClass:[MediaFile class]];
}

- (MediaFile *)mediafileWithName:(NSString *)fileName
{
    NSString *query = @"SELECT * FROM mediafiles WHERE file_name = ?";
    NSArray *decoders = [self decodersFromSQLQuery:query withArgs:@[fileName]];
    
    id <DBCoding> object = nil;
    if ([decoders count] > 0) {
        object = [self objectOfClass:[MediaFile class] fromDecoder:decoders[0]];
    }
    
    return object;
}

- (void)removeMediaFileAndAttachment:(MediaFile *)mediaFile
{
    NSString *decryptedPath = mediaFile.decryptedPath;
    NSString *savedPath = [NSString stringWithFormat:@"%@%@",kDecryptedDirectory, mediaFile.fileName];

    NSArray *attachments = [[MessageAttachmentDBService sharedService] getAttachmentsForMediaFileId:mediaFile.mediafileId];
    if (attachments.count > 0)
    {
        for (MessageAttachment *attachment in attachments) {
            
            ChatMessage *message = [ChatMessageService getMessageWithUuid:attachment.messageUuid];
            [[QliqConnectModule sharedQliqConnectModule] sendDeletedStatus:message];
            [[MessageAttachmentDBService sharedService] deleteAttachment:attachment];
        }
    }

    [[ThumbnailService sharedService] removeAllThumbnailsForMediaFile:mediaFile];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    
    BOOL succes = YES;
    
    if (decryptedPath.length > 0)
    {
        succes = [fileManager removeItemAtPath:decryptedPath error:&error];
    }
    else
    {
        succes = [fileManager removeItemAtPath:savedPath error:&error];
    }    
    
    if (error)
        DDLogError(@"///---- Error on removing file from: \n%@\n Error:\n %@", decryptedPath, [error localizedDescription]);
    
    [[MediaFileDBService sharedService] deleteMediaFile:mediaFile];
}

- (BOOL) deleteContentsOfMediaFile:(MediaFile *)mediafile
{
    NSFileManager *filemanager = [NSFileManager defaultManager];
    NSError *errorDecrypted = nil;
    BOOL successDecryptedDeletion = [filemanager removeItemAtPath:mediafile.decryptedPath error:&errorDecrypted];
    if (errorDecrypted)
        DDLogError(@"%@", [errorDecrypted localizedDescription]);
    
    NSError *errorEncrypted = nil;
    BOOL successEncryptedDeletion = [filemanager removeItemAtPath:mediafile.encryptedPath error:&errorEncrypted];
    if (errorEncrypted)
        DDLogError(@"%@", [errorEncrypted localizedDescription]);
    
    return successDecryptedDeletion && successEncryptedDeletion;
}

- (BOOL) markAsDeletedMediafiles:(NSArray *)mediafiles
{
    if([mediafiles count] == 0) {
        return YES;
    }
    
    NSMutableArray *ids = [[NSMutableArray alloc] initWithCapacity:[mediafiles count]];
    
    for(MediaFile * mediafile in mediafiles)
    {
        if ([self deleteContentsOfMediaFile:mediafile])
        {
            [ids addObject:[NSNumber numberWithInteger:mediafile.mediafileId]];
        }
    }
    
    NSString *idsStr = [ids componentsJoinedByString:@","];
    
    NSString *sql = [NSString stringWithFormat:@"UPDATE mediafiles SET deleted = 1 WHERE id IN (%@)", idsStr];
    __block BOOL ret = NO;
    if (self.database) {
        ret = [self.database executeUpdate:sql];
    } else {
        [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
            ret = [db executeUpdate:sql];
        }];
    }
    return ret;
}

- (BOOL) markAsArchivedMediafiles:(NSArray *)mediafiles
{
    if([mediafiles count] == 0)
    {
        return YES;
    }
    
    NSMutableArray *ids = [[NSMutableArray alloc] initWithCapacity:[mediafiles count]];
    for(MediaFile * mediafile in mediafiles)
    {
        [ids addObject:[NSNumber numberWithInteger:mediafile.mediafileId]];
    }
    
    NSString *idsStr = [ids componentsJoinedByString:@","];
    
    NSString *sql = [NSString stringWithFormat:@"UPDATE mediafiles SET archived = 1 WHERE id IN (%@)", idsStr];
    
    __block BOOL ret = NO;
    if (self.database) {
        ret = [self.database executeUpdate:sql];
    } else {
        [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
            ret = [db executeUpdate:sql];
        }];
    }
    return ret;
}

- (BOOL) deleteMediaFile:(MediaFile *)mediaFile
{
    __block BOOL success = NO;
    [self deleteObject:mediaFile mode:DBModeSingle completion:^(NSError *error) {
        success = error == nil;
    }];
    return success;
}

- (BOOL)deleteMediaFileWithId:(NSInteger)mediaFileId
{
    MediaFile *mediaFile = [self mediafileWithId:mediaFileId];
    return [self deleteMediaFile:mediaFile];
}

- (BOOL)deleteMediaFilesWithoutAttachments
{
    NSString *sql = @"DELETE FROM mediafiles WHERE id NOT IN (SELECT mediafile_id FROM message_attachment)";
    __block BOOL ret = NO;
    if (self.database) {
        ret = [self.database executeUpdate:sql];
    } else {
        [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
            ret = [db executeUpdate:sql];
        }];
    }
    return ret;
}

- (BOOL)deleteMediaFilesOlderThan:(NSTimeInterval)timeInterval
{
    NSString *sql = @"DELETE FROM mediafiles WHERE timestamp < ? AND timestamp != 0";
    __block BOOL ret = NO;
    if (self.database) {
         ret = [self.database executeUpdate:sql, @(timeInterval)];
    }
    else {
        [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
            ret = [self.database executeUpdate:sql, @(timeInterval)];
        }];
    }
    return ret;
}

@end

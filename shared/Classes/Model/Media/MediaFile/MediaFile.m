//
//  MediaFile.m
//  qliqConnect
//
//  Created by Paul Bar on 12/19/11.
//  Copyright (c) 2011 Al Digit. All rights reserved.
//

#import "MediaFile.h"
#import "FMResultSet.h"
#import "CryptoWrapper.h"
#import "MediaFileService.h"
#import "MediaFileDBService.h"
#import <QuartzCore/QuartzCore.h>
#import "ThumbnailService.h"
#import "DBUtil.h"
#import "MessageAttachmentDBService.h"
#import "MessageAttachment.h"
#import "UserSessionService.h"

#define kLeftImageModifier @"Received"
#define kRightImageModifier @"Sent"

@interface MediaFile ()

@property(nonatomic, strong) NSString * relativeEncryptedPath;

@end


@interface MediaFile (Private)

- (NSString *) absolutePathFromRelative:(NSString *) relative;
- (NSString *) relativePathFromAbsolute:(NSString *) absolute;

+ (NSDateFormatter *) dateFormatter;

@end


@implementation MediaFile{
//    NSString * fileName;
}

@synthesize timestamp;
@synthesize mediafileId;
@synthesize encryptionKey;
@synthesize mimeType;
@synthesize fileSizeString;
@synthesize checksum;
@synthesize decryptedPath;
@synthesize relativeEncryptedPath;
@synthesize fileName;

//Search
- (NSString *) searchDescription
{
    NSString *name = @"";
    NSRange r = [fileName rangeOfString:@"_"];
    if (r.length == 1){
        r.length = r.location + 1;
        r.location = 0;
        name = [fileName stringByReplacingCharactersInRange:r withString:@""];
    }
    return [NSString stringWithFormat:@"%@", name];
}

//Generate filepath for this MediaFile
- (NSString *) generateFilePathForName:(NSString *)proposedUniqueName
{
    NSCharacterSet* illegalFileNameCharacters = [NSCharacterSet characterSetWithCharactersInString:@"/\\?%*|\"<>"];
    proposedUniqueName = [[proposedUniqueName componentsSeparatedByCharactersInSet:illegalFileNameCharacters] componentsJoinedByString:@""];
    
    NSString *extension = [proposedUniqueName pathExtension];
    NSString *proposedNameOnly = [proposedUniqueName stringByDeletingPathExtension];
    
    NSString *absoluteDirectoryPath = [MediaFileService generateAbsoluteDirectoryPathFor:self.mimeType fileName:self.fileName];
    NSString *filePath = [NSString stringWithFormat:@"%@%@",absoluteDirectoryPath, proposedUniqueName];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    int i = 2;
    while ([fileManager fileExistsAtPath:filePath]) {
        filePath = [NSString stringWithFormat:@"%@%@",absoluteDirectoryPath, proposedNameOnly];
        filePath = [filePath stringByAppendingFormat:@"-%d", i++];
        if (extension.length > 0) {
            filePath = [filePath stringByAppendingFormat:@".%@", extension];
        }
    }
    return filePath;
}

+ (NSString *)generateImageFilenameWithImageType:(NSString *)type {
   
    static unsigned int seq = 0;
    NSDateFormatter * formatter = [MediaFile dateFormatter];
    
    NSString *fileName = [NSString stringWithFormat:@"photo-%@%d.%@", [formatter stringFromDate:[NSDate date]], ++seq, type];
    
    return fileName;    
}

+ (NSString *)generateVideoFilename {

    static unsigned int seq = 0;
    NSDateFormatter * formatter = [MediaFile dateFormatter];
    
    NSString *fileName = [NSString stringWithFormat:@"video-%@%d.mp4", [formatter stringFromDate:[NSDate date]], ++seq];
    
    return fileName;
}

+ (NSString *) generateAudioFilename {
    
    static unsigned int seq = 0;
    NSDateFormatter * formatter = [MediaFile dateFormatter];
    
    NSString *fileName = [NSString stringWithFormat:@"audio-%@%d.m4a", [formatter stringFromDate:[NSDate date]], ++seq];
    
    return fileName;
}

+ (NSString *) generateDocumentFilename {
    
    static unsigned int seq = 0;
    NSDateFormatter * formatter = [MediaFile dateFormatter];
    
    NSString *fileName = [NSString stringWithFormat:@"document-%@%d.txt", [formatter stringFromDate:[NSDate date]], ++seq];
    
    return fileName;
}

+ (NSString *) generatePdfFilename {
    
    static unsigned int seq = 0;
    NSDateFormatter * formatter = [MediaFile dateFormatter];
    
    NSString *fileName = [NSString stringWithFormat:@"document-%@%d", [formatter stringFromDate:[NSDate date]], ++seq];
    
    return fileName;
}

+ (NSString *) audioRecordingMime {
    return @"audio/aac";
}

- (void) setEncryptedPath:(NSString *)_encryptedPath{
    self.relativeEncryptedPath = [self relativePathFromAbsolute:_encryptedPath];
}

- (NSString *)encryptedPath{
    return [self absolutePathFromRelative:self.relativeEncryptedPath];
}

- (BOOL) saveDecryptedData:(NSData *) decryptedData{
    return [decryptedData writeToFile:self.decryptedPath atomically:YES];
}

- (UIImage *) thumbnail{
    return [[ThumbnailService sharedService] thumbnailForMediaFile:self];
}

- (NSString *) base64EncodedThumbnail
{
    NSString *ret = nil;
    if ([MessageAttachment shouldSendThumbnailForFileName:self.fileName]) {
        ret = [MessageAttachment base64EncodeImage:self.thumbnail];
    }
    return ret;
}

- (BOOL)isEqual:(MediaFile *)object {
    return self.mediafileId == object.mediafileId;
}

- (BOOL) fileExists {
    return ([[NSFileManager defaultManager] fileExistsAtPath:self.encryptedPath] || [[NSFileManager defaultManager] fileExistsAtPath:self.decryptedPath]);
}

- (NSNumber *) encryptedFileSizeNumber
{
    NSError *error = nil;
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:self.encryptedPath error:&error];
    if (nil == error) {
        NSNumber *fileSizeNumber = [fileAttributes objectForKey:NSFileSize];
        return fileSizeNumber;
    } else {
        DDLogError(@"Cannot get file size for MediaFile at path: %@: %@", self.encryptedPath, error);
        return [NSNumber numberWithInteger:0];
    }
}

- (NSString *) description{
    
    NSString *descr = @"";
    if (mediafileId)
        descr = [descr stringByAppendingString:[NSString stringWithFormat:@"\n mediafileId: %ld,", (long)mediafileId]];
    
    if (timestamp)
        descr = [descr stringByAppendingString:[NSString stringWithFormat:@"\n timestamp: %f,", timestamp]];
    
    if (self.encryptedPath)
        descr = [descr stringByAppendingString:[NSString stringWithFormat:@"\n encryptedPath: %@,", self.encryptedPath]];
    
    if (encryptionKey)
        descr = [descr stringByAppendingString:[NSString stringWithFormat:@"\n encryptionKey: %@,", encryptionKey]];
    
    if (mimeType)
        descr = [descr stringByAppendingString:[NSString stringWithFormat:@"\n mimeType: %@,", mimeType]];
    
    if (decryptedPath)
        descr = [descr stringByAppendingString:[NSString stringWithFormat:@"\n decryptedPath: %@,", decryptedPath]];
    
    if (fileSizeString.length > 0)
        descr = [descr stringByAppendingString:[NSString stringWithFormat:@"\n fileSize: %@,", fileSizeString]];
    
    if ([self fileName])
        descr = [descr stringByAppendingString:[NSString stringWithFormat:@"\n fileName: %@", [self fileName]]];
    
    return descr;
}

#pragma mark - Helpers

+ (NSString *)contentTypeForImage:(UIImage *)image {
    
    NSData *data = UIImagePNGRepresentation(image);
    
    return [MediaFile contentTypeForImageData:data];
}

+ (NSString *)contentTypeForImageData:(NSData *)data {

    uint8_t c;
    [data getBytes:&c length:1];
    
    switch (c) {
        case 0xFF:
            return @"jpeg";
        case 0x89:
            return @"png";
        case 0x47:
            return @"gif";
        case 0x49:
        case 0x4D:
            return @"tiff";
    }
    return @"jpeg";
}

#pragma mark - DBCoding

- (id)initWithDBCoder:(DBCoder *)decoder{
    self = [super init];
    if (self) {
        self.timestamp = [[decoder decodeObjectForColumn:@"timestamp"] doubleValue];
        self.mimeType = [decoder decodeObjectForColumn:@"file_mime_type"];
        self.relativeEncryptedPath = [decoder decodeObjectForColumn:@"file_path"];
        self.encryptionKey = [decoder decodeObjectForColumn:@"encryption_key"];
        self.fileSizeString = [decoder decodeObjectForColumn:@"file_size"];
        self.checksum = [decoder decodeObjectForColumn:@"checksum"];
        self.fileName = [decoder decodeObjectForColumn:@"file_name"];
    }
    return self;
}

- (void)encodeWithDBCoder:(DBCoder *)coder{
    [coder encodeObject:[[NSNumber numberWithDouble:self.timestamp] stringValue] forColumn:@"timestamp"];
    [coder encodeObject:self.mimeType forColumn:@"file_mime_type"];
    [coder encodeObject:self.relativeEncryptedPath forColumn:@"file_path"];
    [coder encodeObject:self.encryptionKey forColumn:@"encryption_key"];
    [coder encodeObject:self.fileSizeString forColumn:@"file_size"];
    [coder encodeObject:self.checksum forColumn:@"checksum"];
    [coder encodeObject:self.fileName forColumn:@"file_name"];
    
}

- (NSString *)dbPKProperty{
    return @"mediafileId";
}

+ (NSString *)dbPKColumn{
    return @"id";
}

+ (NSString *)dbTable{
    return @"mediafiles";
}

@end


@implementation MediaFile (ActiveObject)

- (BOOL) decrypt{
    
    return [[MediaFileService getInstance] decryptMediaFile:self];
}

- (void) decryptAsyncCompletitionBlock:(void(^)(void)) block{
    dispatch_queue_t decrypt_queue = dispatch_queue_create("decrypt_queue", NULL);
    dispatch_async(decrypt_queue, ^{
        [self decrypt];
        dispatch_async(dispatch_get_main_queue(), block);
    });
    
//    dispatch_release(decrypt_queue);
}

- (BOOL) encrypt{
    return [[MediaFileService getInstance] encryptMediaFile:self];
}

- (void) encryptAsyncCompletitionBlock:(void(^)(void)) block{
    dispatch_queue_t encrypt_queue = dispatch_queue_create("encrypt_queue", NULL);
    
    dispatch_async(encrypt_queue, ^{
        [self encrypt];
        dispatch_async(dispatch_get_main_queue(), block);
    });
    
//    dispatch_release(encrypt_queue);
}

- (BOOL)save{
    
    __block BOOL success = YES;
    
    [[MediaFileDBService sharedService] save:self completion:^(BOOL wasInserted, id objectId, NSError *error) {
        success = (error == nil);
        if (!success) {
            DDLogError(@"MediaFile didn't saved with error: %@", [error localizedDescription]);
        } else if (!wasInserted) {
            DDLogError(@"MediaFile didn't inserted. ID: %@", objectId);
        }
    }];
    
	return success;
}


@end

@implementation MediaFile (Private)

- (NSString *)absolutePathFromRelative:(NSString *)relative {
    
    NSString * result = nil;
    
    if (relative) {
        NSString * documentsRootPath =  [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByDeletingLastPathComponent];
        result = [NSString stringWithFormat:@"%@/%@",documentsRootPath,relative];
    }
    
    return result;
}

- (NSString *)relativePathFromAbsolute:(NSString *)absolute {
    
    NSString * result = nil;
    NSRange range = [absolute rangeOfString:@"Documents"];
    
    if (range.location != NSNotFound) {
        NSRange rangeToDelete = { .location = 0, .length = range.location };
        result = [absolute stringByReplacingCharactersInRange:rangeToDelete withString:@""];
    }
    
    return result;
}

+ (NSDateFormatter *)dateFormatter {
    
    static NSDateFormatter * formatter;
    
    if (!formatter) {
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"MM-dd-yy_HHmm"];
    }
    
    return formatter;
}

@end

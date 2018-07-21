//
//  ChatMessageAttachment.m
//  qliq
//
//  Created by Adam Sowa on 4/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MessageAttachment.h"
#import "ExtendedChatMessageSchema.h"
#import "MediaFile.h"
#import "FMResultSet.h"
#import "NSData+MKBase64.h"
#import "MediaFileService.h"

#import "MessageAttachmentDBService.h"
#import "MediaFileDBService.h"

#import "CryptoWrapper.h"

#import "ChatMessage.h"
#import "DBHelperConversation.h"

#import <QuartzCore/QuartzCore.h>

#import "ThumbnailService.h"
#import "DBUtil.h"
#import <AVFoundation/AVFoundation.h>



@implementation MessageAttachment

@synthesize attachmentId;
@synthesize messageUuid;
@synthesize url;
@synthesize status;
@synthesize mediaFile;

@synthesize progressGroup;

@synthesize isReceived;

#pragma mark - Initialization 

- (id) init {
    self = [super init];
    if (self){
        self.mediaFile = [[MediaFile alloc] init];
    }
    return self;
}

//Used when sending attachment with MediaFile from library
- (id) initWithMediaFile:(MediaFile *)_mediaFile{
    self = [self init];
    if(self) {
        self.mediaFile = _mediaFile;
		
    }
    return self;
}

- (MediaFile *) mediaFileWithUrl:(NSString *)urlString
{
    MediaFile *_mediaFile = nil;
    NSArray *attachments = [[MessageAttachmentDBService sharedService] getAttachmentsForDownloadURL:urlString];
    MessageAttachment *attachment = [attachments lastObject];

    if ([attachment.mediaFile fileExists]) {
        _mediaFile = attachment.mediaFile;
    }
    
    return _mediaFile;
}

//Used when new message received with attachment
- (id) initWithDictionary:(NSDictionary *)dictionary{
    self = [self init];
    if(self){
        DDLogVerbose(@"attachment dictionary: %@",dictionary);
        self.url = [dictionary objectForKey:EXTENDED_CHAT_MESSAGE_ATTACHMENT_URL];
        
        MediaFile *sameMediaFile = [self mediaFileWithUrl:self.url];
        if (!sameMediaFile) {
            self.mediaFile.fileName = dictionary[EXTENDED_CHAT_MESSAGE_ATTACHMENT_FILE_NAME];
            self.mediaFile.mimeType = dictionary[EXTENDED_CHAT_MESSAGE_ATTACHMENT_MIME];
            self.mediaFile.encryptionKey = dictionary[EXTENDED_CHAT_MESSAGE_ATTACHMENT_KEY];
            id attachmentSize = dictionary[EXTENDED_CHAT_MESSAGE_ATTACHMENT_SIZE];
            if ([attachmentSize isKindOfClass:[NSNumber class]]) {
                // Desktop, Android and fixed iPhone send as number
                self.mediaFile.fileSizeString = [attachmentSize stringValue];
            } else {
                // Old iphone code sends size as string
                self.mediaFile.fileSizeString = attachmentSize;
            }
            self.mediaFile.checksum = dictionary[EXTENDED_CHAT_MESSAGE_ATTACHMENT_CHECKSUM];
            self.mediaFile.timestamp = [NSDate date].timeIntervalSince1970;
            
            id thumbnail = [dictionary objectForKey:EXTENDED_CHAT_MESSAGE_ATTACHMENT_THUMBNAIL];
            if (thumbnail != nil) {  //I assume that only message with Image attachemnts have thumbnails
                if ([thumbnail isKindOfClass:[NSString class]]) {
                    NSString *base64Thumb = (NSString *)thumbnail;
                    NSData *thumbData = [NSData dataFromBase64String:base64Thumb];
                    UIImage * thumbnailImage = [UIImage imageWithData:thumbData];
                    if (thumbnailImage){
                        [[ThumbnailService sharedService] thumbnailForAttachment:self withImage:thumbnailImage];
                    }else{
                        DDLogError(@"Thumbnail image is nil for received message with dictionary: %@",dictionary);
                    }
                } else {
                    DDLogError(@"The message attachment thumbnail key is present but null");
                }
            }
            self.status = AttachmentStatusToBeDownloaded;
        } else {
            self.mediaFile = sameMediaFile;
            self.status = AttachmentStatusDownloaded;
        }
        
        DDLogVerbose(@"created attachment: %@",self);
    }
    return self;
}

#pragma mark -

- (NSString *)description{
    
    return [NSString stringWithFormat:@"{\n\
            attachmentId: %ld,\n\
            messageUuid: %@,\n\
            url: %@,\n\
            status: %d,\n\
            mediaFile: \t%@\n}", (long)attachmentId, messageUuid, url,status,mediaFile];
}



- (id) initWithVideoAtURL:(NSURL *)videoURL
{
    self = [self init];
    if (self) {
        self.mediaFile.fileName = [MediaFile generateVideoFilename];
        self.mediaFile.mimeType = @"video/mp4";
        self.mediaFile.decryptedPath = [videoURL path];
        self.status = AttachmentStatusNotInDB;
        [[ThumbnailService sharedService] thumbnailForAttachment:self withVideoURL:videoURL];
        
        [self.mediaFile encrypt];
    }
    return self;
}

//This method saves image asyn - so it have completition block
- (id) initWithImage:(UIImage *) image scale:(CGFloat) scale saved:(void(^)(void))savedBlock encrypted:(void(^)(void))encryptedBlock{
    self = [self init];
    if (self){
		
        self.mediaFile.fileName = [MediaFile generateImageFilenameWithImageType:@"png"];
        self.mediaFile.decryptedPath = [NSString stringWithFormat:@"%@%@",kDecryptedDirectory,self.mediaFile.fileName];
        self.mediaFile.mimeType =  @"image/png";
        self.status = AttachmentStatusNotInDB;
        //Request for thumbnail to cache it
        [[ThumbnailService sharedService] thumbnailForAttachment:self withImage:image];
        
        progressGroup = dispatch_group_create();
        
        __unsafe_unretained __block UIImage * weak_image_ref = image;
        __weak __block typeof(self) welf = self;
        // The bg queue is disabled because we need to have the image scaled and saved on disk
        // before we can attach it in the UI because we need to test the file's size

#ifdef USE_QUEUE_TO_SAVE_IMAGE
		dispatch_queue_t save_queue = dispatch_queue_create("save", NULL);
        dispatch_group_async(progressGroup, save_queue, ^{
#endif
            /* Rescale image before saving */

            UIImage *weakImageRef = [welf imageFromImage:weak_image_ref scaledTo:scale];
            
            if (!weakImageRef) {
                DDLogSupport(@"Can't create message attachment");
                return nil;
            }
            
            NSData * imageData = UIImagePNGRepresentation(weakImageRef);
            
            weak_image_ref = nil;
            
            /* Compress to PNG and save to disk */
            [welf.mediaFile saveDecryptedData:imageData];
            dispatch_async(dispatch_get_main_queue(), savedBlock);
            
            /* Encrypt image */
            [welf.mediaFile encrypt];
            dispatch_async(dispatch_get_main_queue(), encryptedBlock);
            
//            dispatch_release(progressGroup);
            progressGroup = nil;
#ifdef USE_QUEUE_TO_SAVE_IMAGE
        });
        dispatch_release(save_queue);
#endif
		image = nil;

        //if(progressGroup) dispatch_release(progressGroup);
    }
    return self;
}


- (void) updateMediaFile: (MediaFile *)_mediaFile{
    self.mediaFile = _mediaFile;
    [self save];
}

- (BOOL) isUploadedToServer
{
    return (self.status == AttachmentStatusUploaded       ||
            self.status == AttachmentStatusToBeDownloaded ||
            self.status == AttachmentStatusDownloading    ||
            self.status == AttachmentStatusDownloaded     ||
            self.status == AttachmentStatusDownloadFailed) &&
            self.url.length > 0;
}

- (UIImage *) imageFromImage:(UIImage *)image scaledTo:(CGFloat) scale
{
    CGSize targetSize = [image size];
    
    targetSize.width *= scale;
    targetSize.height *= scale;

    return [[ThumbnailService sharedService] resizeImage:image toSize:targetSize contentMode:UIViewContentModeScaleToFill];
}

#pragma mark - NSCopyng

- (id)copyWithZone:(NSZone *)zone
{
    MessageAttachment *attachment = [[MessageAttachment allocWithZone:zone] init];
    attachment.mediaFile = self.mediaFile;
    attachment.url = [self.url copy];
    attachment.status = self.status;
    attachment.isReceived = self.isReceived;
    attachment.attachmentId = 0;
    attachment.messageUuid = nil;
    return attachment;
}

#pragma mark - DBCoding

- (id)initWithDBCoder:(DBCoder *)decoder{
    
    self = [super init];
    if (self) {
        self.messageUuid = [decoder decodeObjectForColumn:@"uuid"];
        self.url = [decoder decodeObjectForColumn:@"url"];
        self.status = [[decoder decodeObjectForColumn:@"status"] intValue];
        self.mediaFile = [decoder decodeObjectOfClass:[MediaFile class] forColumn:@"mediafile_id"];
    }
    return self;
    
}

- (void)encodeWithDBCoder:(DBCoder *)coder{

    [coder encodeObject:self.messageUuid forColumn:@"uuid"];
    [coder encodeObject:self.url forColumn:@"url"];
    [coder encodeObject:[NSNumber numberWithInt:self.status] forColumn:@"status"];
    [coder encodeObject:self.mediaFile forColumn:@"mediafile_id"];

}

- (NSString *)dbPKProperty{
    return @"attachmentId";
}

+ (NSString *)dbPKColumn{
    return @"id";
}

+ (NSString *)dbTable{
    return @"message_attachment";
}



@end

@implementation MessageAttachment (ActiveObject)

- (BOOL) save{

    __block BOOL success = NO;
    [self.mediaFile save];
    
    [[MessageAttachmentDBService sharedService] save:self completion:^(BOOL wasInserted, id objectId, NSError *error) {
        success = (error == nil);
        if (!success) {
            DDLogError(@"Message attachment didn't saved with error: %@", [error localizedDescription]);
        } else if (!wasInserted) {
            DDLogError(@"Message attachment  didn't inserted. ID: %@", objectId);
        }
    }];
    
    return success;
}

- (void) reload{
    
    MessageAttachment * attachment = [[MessageAttachmentDBService sharedService] reloadObject:self];
    
    if (attachment){
        self.status = attachment.status;
        self.mediaFile = attachment.mediaFile;
        self.url = attachment.url;
    }
    
}

- (BOOL) removeAssociatedData{
    BOOL success = YES;
    if (status == AttachmentStatusNotInDB){
        success &= [[NSFileManager defaultManager] removeItemAtPath:self.mediaFile.decryptedPath error:nil];
        success &= [[NSFileManager defaultManager] removeItemAtPath:self.mediaFile.encryptedPath error:nil];
        success &= [[ThumbnailService sharedService] removeAllThumbnailsForAttachment:self];
    }
    return success;
}

- (UIImage *) thumbnailStyled:(BOOL)_styled{
    return [[ThumbnailService sharedService] thumbnailForAttachment:self styled:_styled];
}

- (NSString *) thumbnailBase64Encoded
{
    UIImage *thumbnail = [self thumbnailStyled:NO];
    // Adam Sowa - we should use JPEG which is much more efficient (smaller)
    // the only exception should be if source file is actualy PNG with transparency
    // However to keep app behaviour intact I continue to use PNG here
    return [MessageAttachment base64EncodeImage:thumbnail useJpeg:NO quality:0.0f];
}

+ (NSString *) base64EncodeImage:(UIImage *)image
{
    return [self base64EncodeImage:image useJpeg:YES quality:0.7f];
}

+ (NSString *) base64EncodeImage:(UIImage *)image useJpeg:(BOOL)useJpeg quality:(float)quality
{
    if (image == nil) {
        return nil;
    }
    
    NSData *thumbnailData;
    if (useJpeg) {
        thumbnailData = UIImageJPEGRepresentation(image, quality);
    } else {
        thumbnailData = UIImagePNGRepresentation(image);
    }

    NSString *thumbnailBase64String = [thumbnailData base64EncodedString];
    
    if (!thumbnailBase64String) {
        DDLogError(@"thumbnailBase64String is nil. thumbnail: %@, thumbnailData.length = %lu",image,(unsigned long)thumbnailData.length);
    }
    
    return thumbnailBase64String;
}

+ (BOOL) shouldSendThumbnailForFileName:(NSString *)fileName
{
    NSString *ext = [[fileName pathExtension] lowercaseString];
    return ([ext isEqualToString:@"jpg"] || [ext isEqualToString:@"jpeg"] || [ext isEqualToString:@"png"] || [ext isEqualToString:@"mp4"]);
}

@end

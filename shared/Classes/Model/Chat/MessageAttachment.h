//
//  ChatMessageAttachment.h
//  qliq
//
//  Created by Adam Sowa on 4/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"
#import "DBCoder.h"

@class MediaFile;
@class FMResultSet;

// Initialize Enums that are stored in the DB

typedef enum {
    AttachmentStatusNone            = 0,
    AttachmentStatusToBeUploaded    = 1,
    AttachmentStatusUploading       = 2,
    AttachmentStatusUploadFailed    = 3,
    AttachmentStatusUploaded        = 4,
    AttachmentStatusToBeDownloaded  = 5,
    AttachmentStatusDownloading     = 6,
    AttachmentStatusDownloadFailed  = 7,
    AttachmentStatusDownloaded      = 8,
    AttachmentStatusDeclined        = 9,
    AttachmentStatusNotInDB         = 10
} AttachmentStatus;

@interface MessageAttachment : NSObject <DBCoding, NSCopying>


//Attachment entity related properties
@property (nonatomic) NSInteger attachmentId;
@property (nonatomic, strong) NSString * messageUuid;
@property (nonatomic) int status;
@property (nonatomic, strong) NSString *url;
//
@property (nonatomic) BOOL isReceived;

//Attachment-file properties
@property (nonatomic, strong) MediaFile * mediaFile;     //Mediafile

@property (nonatomic, readonly) dispatch_group_t progressGroup;

- (id) initWithMediaFile:(MediaFile*)mediaFile;
- (id) initWithDictionary:(NSDictionary*)dictionary;
- (id) initWithVideoAtURL:(NSURL *)videoURL;
- (id) initWithImage:(UIImage *) image scale:(CGFloat) scale saved:(void(^)(void))savedBlock encrypted:(void(^)(void))encryptedBlock;
- (UIImage *) imageFromImage:(UIImage *)image scaledTo:(CGFloat) scale;

- (void) updateMediaFile: (MediaFile *)_mediaFile;

- (BOOL) isUploadedToServer;

@end

@interface MessageAttachment (ActiveObject)

- (UIImage *) thumbnailStyled:(BOOL) _styled;

- (NSString *) thumbnailBase64Encoded;

- (BOOL) removeAssociatedData;

- (BOOL) save;
- (void) reload;

+ (NSString *) base64EncodeImage:(UIImage *)image;
+ (NSString *) base64EncodeImage:(UIImage *)image useJpeg:(BOOL)useJpeg quality:(float)quality;

+ (BOOL) shouldSendThumbnailForFileName:(NSString *)fileName;

@end

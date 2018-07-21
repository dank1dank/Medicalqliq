//
//  MediaFile.h
//  qliqConnect
//
//  Created by Paul Bar on 12/19/11.
//  Copyright (c) 2011 Al Digit. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "DBCoder.h"

@interface MediaFile : NSObject<DBCoding>

@property(nonatomic, readwrite) NSInteger mediafileId;

@property(nonatomic, assign) double timestamp;

@property(nonatomic, strong) NSString *encryptionKey;
@property(nonatomic, strong) NSString *mimeType;

// Adam Sowa: why fileSize is of type NSString?
// Probably because it can be a large number
// we could use NSNumber instead
@property(nonatomic, strong) NSString *fileSizeString;
@property(nonatomic, strong) NSString *checksum;

//File paths (paths are absolute)
@property(nonatomic, strong) NSString * encryptedPath;
@property(nonatomic, strong) NSString * decryptedPath;

//Thumbnail
@property (nonatomic, readonly, unsafe_unretained) UIImage * thumbnail;

@property (nonatomic, strong) NSString * fileName;

+ (NSString *) generateImageFilenameWithImageType:(NSString *)type;
+ (NSString *) generateVideoFilename;
+ (NSString *) generateAudioFilename;
+ (NSString *) generateDocumentFilename;
+ (NSString *) generatePdfFilename;
+ (NSString *) audioRecordingMime;

+ (NSString *) contentTypeForImage:(UIImage *)image;
+ (NSString *) contentTypeForImageData:(NSData *)data;

- (NSString *) generateFilePathForName:(NSString *)proposedUniqueName;

- (BOOL) saveDecryptedData:(NSData *) decryptedData;

- (UIImage *) thumbnail;
// This method will return thumbnail only for file types that we should be sending thumbnails
- (NSString *) base64EncodedThumbnail;

- (BOOL) fileExists;

- (NSString *) searchDescription;

// Returns the size of the file on disk (used when sending attachment, pushing to qliqStor or uploading to EMR)
- (NSNumber *) encryptedFileSizeNumber;

@end

@interface MediaFile (ActiveObject)

- (BOOL) decrypt;
- (void) decryptAsyncCompletitionBlock:(void(^)(void)) block;

- (BOOL) encrypt;
- (void) encryptAsyncCompletitionBlock:(void(^)(void)) block;

- (BOOL) save;

@end




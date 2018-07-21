//
//  MediafilesService.h
//  qliq
//
//  Created by Paul Bar on 4/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "MediaFile.h"

@interface MediaFileService : NSObject

typedef NS_ENUM(NSInteger, MediaFileType) {
    MediaFileTypeDocument,
    MediaFileTypeAudio,
    MediaFileTypeImage,
    MediaFileTypeVideo,
    MediaFileTypeUnknown
};

+ (MediaFileService*) getInstance;

- (NSString *) directoryForMediafilesWithMimeType:(NSString *)mime andFileName:(NSString *) fileName;
+ (NSString *)generateAbsoluteDirectoryPathFor:(NSString *)mime fileName:(NSString *)fileName;

- (NSString *) imageNameForMimeType:(NSString *)_mime andFileName:(NSString *)_fileName left:(BOOL) _left;
- (NSString *) imageNameForMimeType:(NSString *)_mime andFileName:(NSString *)_fileName fileSuffix:(NSString *) _suffix;
- (BOOL) fileSupportedWithMimeType:(NSString *) _mime andFileName:(NSString *) _fileName;

- (BOOL) isGeneratableThumbMime:(NSString *)_mime FileName:(NSString *) _fileName;
- (BOOL) isAudioFileMime:(NSString*) _mime FileName:(NSString *) _fileName;
- (BOOL) isDocumentFileMime:(NSString*) _mime FileName:(NSString *) _fileName;
- (BOOL) isImageFileMime:(NSString *) _mime FileName: (NSString *) _fileName;
- (BOOL) isVideoFileMime:(NSString *) _mime FileName: (NSString *) _fileName;
- (MediaFileType) typeNameForMime:(NSString *) _mime FileName: (NSString *) _fileName;

- (NSArray *) audioMimeTypes;
- (NSArray *) videoMimeTypes;
- (NSArray *) imagesMimeTypes;
- (NSArray *) documentsMimeTypes;
- (NSArray *) pdfMimeTypes;
- (NSArray *) videoMimeTypes;

- (BOOL)isPDF:(MediaFile *)mediaFile;

- (BOOL) encryptMediaFile: (MediaFile *) _mediaFile;
- (BOOL) decryptMediaFile: (MediaFile *) _mediaFile;

- (BOOL) wipeMediafiles;

@end


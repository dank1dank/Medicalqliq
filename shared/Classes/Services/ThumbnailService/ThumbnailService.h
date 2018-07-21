//
//  ThumbnailService.h
//  qliq
//
//  Created by Aleksey Garbarev on 5/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>



#define kThumbSmallSize CGSizeMake(56.0, 56.0)

typedef enum {
    ThumbnailStyleNone,
    ThumbnailStyleRoundCorners
} ThumbnailStyle;

@class MediaFile, MessageAttachment;

@interface ThumbnailService : NSObject


+ (id) sharedService;

- (UIImage *) resizeImage:(UIImage *) _thumb toSize:(CGSize) thumbSize contentMode:(UIViewContentMode) contentMode;

// ** Thumbnail options dictionary **

/** 
   Options dictionary describe thumbnail that we need. Currently Options dictionary have next structure: {
    mime: 'mime/type',
    fileName: 'name of MediaFile'                                       //Required for thumbnail path
    generationPath: 'path to decrypted object',                         //Path to image for generation thumbnail
    generationImage: <UIImage>                                          //image for generation thumbnail. It is optionaly replacement for generationPath
    size: [NSValue valueWithCGSize:'size of thumbnail image'],
    style: {                                                            //Options that affect to thumbnail appearnce
        type: [NSNumber numberWithInd:'one of ThumbnailStyle enum value'],
        fileSuffix: 'string that will be replaced in image filename',
        opaque: [NSNumber numberWithBool:NO]                            //affect to saving thumbnail - JPG or PNG
    }
   }
*/

//Common methods to working with thumbnails
- (void) thumbnailForOptionsDict: (NSDictionary *) _options completeBlock:(CompletionBlock) complete;
- (BOOL) isThumbnailExistForOptionsDict: (NSDictionary *) _options;
- (BOOL) saveThumbnail:(UIImage *)image thumbOptions:(NSDictionary *) _options;
//

- (void) emptyCache;
///
- (NSUInteger) numberToGenerateForMediaFiles:(NSArray *) _mediaFiles;

- (UIImage *) thumbnailForMediaFile:(MediaFile *) _mediaFile; //Calls in 'Media' tab

- (UIImage *) thumbnailForAttachment:(MessageAttachment *) _attachment styled:(BOOL) _styled;
- (UIImage *) thumbnailForAttachment:(MessageAttachment *) _attachment withVideoURL:(NSURL *)videoURL;
- (UIImage *) thumbnailForAttachment:(MessageAttachment *) _attachment withImage: (UIImage *) image; //Calls when user attach new image

- (BOOL) removeAllThumbnailsForAttachment:(MessageAttachment *) _attachment;
- (BOOL) removeAllThumbnailsForMediaFile:(MediaFile*) mediaFile;

+ (UIImage *) genericThumbnailForFileName:(NSString *)fileName
                                 mimeType:(NSString *)mimeType
                                    style:(ThumbnailStyle) _styleType
                                   opaque:(BOOL) _opaque;

@end


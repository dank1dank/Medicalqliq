//
//  ThumbnailService.m
//  qliq
//
//  Created by Aleksey Garbarev on 5/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ThumbnailService.h"
#import <QuartzCore/QuartzCore.h>
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>
#import "MediaFileService.h"

#import "MediaFile.h"
#import "MessageAttachment.h"
#import "NSThread_backtrace.h"

#define kBGImageRatio 51.0f/56.0f

#define kThumbsDirectory [NSString stringWithFormat:@"%@Thumbs/",NSTemporaryDirectory()]


@implementation ThumbnailService{
    NSCache *thumbnailsCache;
}

#pragma mark - Some ugly old code, that tested and works

+ (NSString *) textForSecond:(CGFloat) second{
    
    if(second >= 3600){
        CGFloat onlyhours = floor(second/3600);
        CGFloat onlyminutes = floor((second - onlyhours*3600)/60);//floor(second/60);
        CGFloat onlySeconds = floor(second - onlyminutes*60);
        return [NSString stringWithFormat:@"%02g:%02g.%02g",onlyhours,onlyminutes,onlySeconds];
    }
    
    CGFloat minutes = floor(second/60);
    CGFloat onlySeconds = floor(second - minutes*60);
    return [NSString stringWithFormat:@"%01g:%02g",minutes,onlySeconds];
    
}

+ (UIImage *) newImageForTime:(CGFloat) _time andThumb:(UIImage *) _image{
    NSString * time = [self textForSecond:_time];
    //create object for preview
    UILabel * lengthLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 58, 75, 17)];
    lengthLabel.textColor = [UIColor whiteColor];
    lengthLabel.textAlignment = NSTextAlignmentRight;
    lengthLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:12];
    lengthLabel.backgroundColor = [UIColor clearColor];
    lengthLabel.text = time;
    
    UIView * statusView = [[UIView alloc] initWithFrame:CGRectMake(0, 58, 75, 17)];
    statusView.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.5f];
    
    UIGraphicsBeginImageContext(CGSizeMake(75, 75));
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGRect imageRect = CGRectZero;
    CGSize imageSize = CGSizeMake(75, 75);
    if (_image.size.height > _image.size.width ){
        CGFloat dW = _image.size.width / imageSize.width;
        imageRect.size.width = imageSize.width;
        imageRect.size.height = _image.size.height / dW;
        imageRect.origin.y = (imageSize.height - imageRect.size.height)/2;
        
    }else{
        CGFloat dH = _image.size.height / imageSize.height;
        
        imageRect.size.width = _image.size.width / dH;
        imageRect.origin.x = (imageSize.width - imageRect.size.width)/2;
        imageRect.size.height = imageSize.height;
    }
    
    [_image drawInRect:imageRect];
    
    CGContextBeginTransparencyLayer(context, NULL);
    
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, 0, 75-17);
    [statusView.layer renderInContext:context];
    CGContextRestoreGState(context);
    
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, 24,  75-17);
    lengthLabel.layer.frame = CGRectMake(0, 0, 46, 17);
    [lengthLabel.layer renderInContext:context];
    CGContextRestoreGState(context);
    [[UIImage imageNamed:@"camera_icon.png"] drawInRect:CGRectMake(5, 75-17+ 4, 16, 10)];
    
    CGContextEndTransparencyLayer(context);
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    return newImage;
}

#pragma mark - Image thumbnails generation mathods


- (UIImage *) imageByAddingVideoInfo:(UIImage *)image videoURL:(NSURL *)videoURL
{
    
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
    AVAssetTrack *track = [asset tracks][0];
    CGFloat seconds = CMTimeGetSeconds(track.timeRange.duration);
    
    return [ThumbnailService newImageForTime:seconds andThumb:image];
}

- (UIImage *) imageFromVideoURL:(NSURL *)videoURL
{
    UIImage *videoImage = nil;
    if (videoURL) {
        AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
        AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
        gen.appliesPreferredTrackTransform = YES;
        CMTime time = CMTimeMakeWithSeconds(0.0, 600);
        NSError *error = nil;
        CMTime actualTime;
        
        CGImageRef image = [gen copyCGImageAtTime:time actualTime:&actualTime error:&error];
        UIImage *thumb = [[UIImage alloc] initWithCGImage:image];
        CGImageRelease(image);
        
        videoImage = [self imageByAddingVideoInfo:thumb videoURL:videoURL];
    }
    
    return videoImage;
}

//Resize and style image to defined size
- (UIImage *) styledThumbnailForImage:(UIImage *) _thumb size:(CGSize) thumbSize{
    
    thumbSize = CGSizeMake(round(thumbSize.width), round(thumbSize.height));
    
    UIImage * resultImage;
    UIImage * emptyIcon = [UIImage imageNamed:@"Static-Attachment-Thumbnail-Unknown-File"]; //[UIImage imageNamed:@"Chat-Bubble-Received-Unsupported-File"];//AIIIII
    
    UIImageView * imageView = [[UIImageView alloc] initWithImage:_thumb];
    imageView.frame = CGRectMake(0, 0, thumbSize.width*kBGImageRatio, thumbSize.height*kBGImageRatio);
    imageView.layer.cornerRadius = 5.0f;
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.layer.masksToBounds = YES;
    
    
    UIGraphicsBeginImageContextWithOptions(thumbSize, NO, [[UIScreen mainScreen] scale]);
    
    [emptyIcon drawInRect:CGRectMake(0, 0, thumbSize.width, thumbSize.height) blendMode:kCGBlendModeNormal alpha:1.0];
    
    CGContextTranslateCTM(UIGraphicsGetCurrentContext(), 1, 1);
    [imageView.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    resultImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    emptyIcon = nil;
    
    return resultImage;
}


//Resizes image to defined size
- (UIImage *) resizeImage:(UIImage *) _thumb toSize:(CGSize) thumbSize contentMode:(UIViewContentMode) contentMode{
    thumbSize = CGSizeMake(round(thumbSize.width), round(thumbSize.height));
    UIImage * resultImage;
    
    if (_thumb) {
        UIImageView * imageView = [[UIImageView alloc] initWithImage:_thumb];
        imageView.frame = CGRectMake(0, 0, thumbSize.width, thumbSize.height);
        imageView.contentMode = contentMode;
        
        UIGraphicsBeginImageContextWithOptions(thumbSize, NO, 1.0);
        
        [imageView.layer renderInContext:UIGraphicsGetCurrentContext()];
        resultImage = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
    }
    
    return resultImage;
}

#pragma mark - Lifecycle of object

- (id) init{

    self = [super init];
    if (self){
        thumbnailsCache = [[NSCache alloc] init];
        [thumbnailsCache setCountLimit:100];
    
    }
    return self;
}

- (void) dealloc
{
    [self emptyCache];
    thumbnailsCache = nil;    
}

+ (id) sharedService{
    static ThumbnailService * instance;
    if (!instance){
        @synchronized(self){
            instance = [[ThumbnailService alloc] init];
            [[NSFileManager defaultManager] createDirectoryAtPath:kThumbsDirectory withIntermediateDirectories:YES attributes:NULL error:nil];
        }
    }
    return instance;
}

- (void) emptyCache{
    [thumbnailsCache removeAllObjects];
}

#pragma mark - Common methods for working with thumbnails

//Generate thumbnail path specially for options
- (NSString *) thumbPathForOptions:(NSDictionary *) _options{
    //Properties that affect to thumbnail appearnce
    CGSize size = [[_options valueForKey:@"size"] CGSizeValue];
    ThumbnailStyle style = [[[_options valueForKey:@"style"] valueForKey:@"type"] intValue];
    BOOL opaque = [[_options valueForKey:@"opaque"] boolValue];
    return [NSString stringWithFormat:@"%@%@_%gx%g_style=q%d-%d",kThumbsDirectory,[_options valueForKey:@"fileName"],size.width,size.height,style,opaque];
}

// Return success of saving thumbnail. If image already exist - return YES
- (BOOL)saveThumbnail:(UIImage *)image thumbOptions:(NSDictionary *)_options
{
    NSString * path = [self thumbPathForOptions:_options];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:path])
    {
        NSNumber * opaqueValue = [[_options valueForKey:@"style"] valueForKey:@"opaque"];
        
        if (opaqueValue && [opaqueValue boolValue])
        {
            return [UIImageJPEGRepresentation(image, 0.7) writeToFile:path atomically:YES];
        }
        else
        {
            return [UIImagePNGRepresentation(image) writeToFile:path atomically:YES];
        }
    }
    
    return YES;
}

- (BOOL) isThumbnailExistForOptionsDict: (NSDictionary *) _options{
    return [[NSFileManager defaultManager] fileExistsAtPath:[self thumbPathForOptions:_options]];
}

- (void) thumbnailForOptionsDict: (NSDictionary *) _options completeBlock:(CompletionBlock) complete{
    
    NSString * mime = [_options valueForKey:@"mime"];
    NSString * fileName = [_options valueForKey:@"fileName"];
    
    if (!fileName){
        NSError * error = [NSError errorWithDomain:errorCurrentDomain code:1 userInfo:userInfoWithDescription(@"Error: can't access to thumnbail until key 'fileName' is undefined")];
        if (complete) complete (CompletitionStatusError, nil, error);
        return;
    }
    
    NSValue * thumbSizeValue = [_options valueForKey:@"size"];
    CGSize thumbSize = [thumbSizeValue CGSizeValue];
    if (!thumbSizeValue) {
        DDLogWarn(@"Warning: key 'size' in undefined. Used default value");
        thumbSize = kThumbSmallSize;
    }
    thumbSizeValue = nil;
    
    NSDictionary * styleOptions = [_options valueForKey:@"style"];
    NSString * suffix = [styleOptions valueForKey:@"fileSuffix"];
    int styleType = [[styleOptions valueForKey:@"type"] intValue];
    
    UIImage * thumbnail = nil;
    MediaFileService * service = [MediaFileService getInstance];
    if ([service isGeneratableThumbMime:mime FileName:fileName]){ //if image
        
        NSString * path = [self thumbPathForOptions:_options];
        thumbnail = [thumbnailsCache objectForKey:path];
        
        if (!thumbnail){
            if ([[NSFileManager defaultManager] fileExistsAtPath:[self thumbPathForOptions:_options]]){
                
                thumbnail = [UIImage imageWithData:[NSData dataWithContentsOfFile:path]];//[UIImage imageWithContentsOfFile:path];
                
            }else{
                UIImage * sourceImage = [_options valueForKey:@"generationImage"];
                if (!sourceImage){
                    if ([service isImageFileMime:mime FileName:fileName]) {
//                        sourceImage = [UIImage imageWithContentsOfFile:[_options valueForKey:@"generationPath"]];
                        sourceImage = [UIImage imageNamed:[_options valueForKey:@"generationPath"]];
                    } else {
                        NSURL *videoURL = [[NSURL alloc] initFileURLWithPath:[_options valueForKey:@"generationPath"]];
                        sourceImage = [self imageFromVideoURL:videoURL];
                    }
                }
                if (sourceImage){
                    //generate thumnail
                    switch (styleType) {
                        case ThumbnailStyleNone:
                            thumbnail = [self resizeImage:sourceImage toSize:thumbSize contentMode:UIViewContentModeScaleAspectFill];
                            break;
                        case ThumbnailStyleRoundCorners:
                            thumbnail = [self styledThumbnailForImage:sourceImage size:thumbSize];
                            break;
                        default: {
                            NSString * errorDescription = [NSString stringWithFormat:@"Error: Can't generate thumbnail - 'type' style key is undefined. Generation options: %@",_options];
                            DDLogError(@"%@",errorDescription);
                            NSError * error = [NSError errorWithDomain:errorCurrentDomain code:2 userInfo:userInfoWithDescription(errorDescription)];
                            if (complete) complete (CompletitionStatusError, nil, error);
                            return;
                            break;
                        }
                    }
                    DDLogInfo(@"Thumnail is generated");
                }else{
                    NSString * errorDescription = [NSString stringWithFormat:@"Error: Can't generate thumbnail - 'generationImage' and 'generationPath' keys are undefined Generation options: %@",_options];
                    NSError * error = [NSError errorWithDomain:errorCurrentDomain code:3 userInfo:userInfoWithDescription(errorDescription)];
                    if (complete) complete (CompletitionStatusError, nil, error);
                    return;
                }
                
            }
            [thumbnailsCache setObject:thumbnail forKey:path];
        }
    } else {
        thumbnail = [UIImage imageNamed:[service imageNameForMimeType:mime andFileName:fileName fileSuffix:suffix]];
    }
    
    if (thumbnail){
        if (complete) complete (CompletitionStatusSuccess, thumbnail, nil);
    }else{
        NSString * errorDescription = [NSString stringWithFormat:@"Error: unknown error. Options: %@",_options];
        NSError * error = [NSError errorWithDomain:errorCurrentDomain code:4 userInfo:userInfoWithDescription(errorDescription)];
        if (complete) complete (CompletitionStatusError, nil, error);
    }
    
}

//Common method to generate thumbnail for options dictionary
- (UIImage *) thumbnailForOptionsDict: (NSDictionary *) _options{
    
    __block UIImage * thumbnail = nil;
    
    [self thumbnailForOptionsDict:_options completeBlock:^(CompletitionStatus status, id result, NSError *error) {
        thumbnail = result;
        if (error){
            DDLogError(@"%@",[error localizedDescription]);
            DDLogError(@"thumbnail callstack: \n%@",[NSThread callStackSymbolsWithLimit:10]);
        }
    }];
    
    return thumbnail;
}


#pragma mark - Generation thumbnails for special objects 

- (BOOL) removeAllThumbnailsForMediaFile:(MediaFile *)_mediaFile{
   
    BOOL success = YES;
    NSString * fileName = [_mediaFile fileName];
    
    for (NSString * thumbName in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:kThumbsDirectory error:nil]){
        if ([thumbName rangeOfString:fileName].length != 0){
            NSString * pathToRemove = [NSString stringWithFormat:@"%@%@",kThumbsDirectory,thumbName];
            [thumbnailsCache removeObjectForKey:pathToRemove];
            success *= [[NSFileManager defaultManager] removeItemAtPath:pathToRemove error:nil];
        }
    }

    return success;
}

//Common generation thumbnail for MediaFile
- (UIImage *) thumbnailForMediaFile:(MediaFile *) _mediaFile
                         fileSuffix:(NSString *) _fileSuffix
                              style:(ThumbnailStyle) _styleType
                             opaque:(BOOL) _opaque{
    
    NSString * fileName = [_mediaFile fileName];
    
    NSMutableDictionary * styleOptions = [[NSMutableDictionary alloc] init];
    [styleOptions setValue:[NSNumber numberWithInt:_styleType] forKey:@"type"];
    [styleOptions setValue:[NSNumber numberWithBool:_opaque] forKey:@"opaque"];
    [styleOptions setValue:_fileSuffix forKey:@"fileSuffix"];
    
    NSMutableDictionary * options = [[NSMutableDictionary alloc] init];
    [options setValue:_mediaFile.mimeType forKey:@"mime"];
    [options setValue:fileName forKey:@"fileName"];
    [options setValue:[NSValue valueWithCGSize:kThumbSmallSize] forKey:@"size"];
    [options setValue:styleOptions forKey:@"style"];
    
    BOOL shouldGenerate = NO;
    NSString *errorString = nil;
    
    if ([[MediaFileService getInstance] isGeneratableThumbMime:_mediaFile.mimeType FileName:fileName])
    {
        if (![self isThumbnailExistForOptionsDict:options])
        {
            if ([_mediaFile decrypt])
            {
                [options setValue:_mediaFile.decryptedPath forKey:@"generationPath"];
                shouldGenerate = YES;
            }
            else
            {
                errorString = [NSString stringWithFormat:@"Can't generate thumnail for mediafile: %@",_mediaFile];
            }
        }
    }
    
    UIImage *thumbnailStyled = nil;

    if (!errorString)
    {
        thumbnailStyled = [[ThumbnailService sharedService] thumbnailForOptionsDict:options];
    
        if (shouldGenerate && thumbnailStyled)
        { //If was generated - save!
            [[ThumbnailService sharedService] saveThumbnail:thumbnailStyled thumbOptions:options];
        }
    }
    else
    {
        DDLogError(@"%@",errorString);
    }
    
    return thumbnailStyled;
}

+ (UIImage *) genericThumbnailForFileName:(NSString *)fileName
                         mimeType:(NSString *)mimeType
                              style:(ThumbnailStyle) _styleType
                             opaque:(BOOL) _opaque
{
    NSMutableDictionary * styleOptions = [[NSMutableDictionary alloc] init];
    [styleOptions setValue:[NSNumber numberWithInt:_styleType] forKey:@"type"];
    [styleOptions setValue:[NSNumber numberWithBool:_opaque] forKey:@"opaque"];
    [styleOptions setValue:[fileName pathExtension] forKey:@"fileSuffix"];
    
    NSMutableDictionary * options = [[NSMutableDictionary alloc] init];
    [options setValue:mimeType forKey:@"mime"];
    [options setValue:fileName forKey:@"fileName"];
    [options setValue:[NSValue valueWithCGSize:kThumbSmallSize] forKey:@"size"];
    [options setValue:styleOptions forKey:@"style"];
    
    UIImage *thumbnail = [[ThumbnailService sharedService] thumbnailForOptionsDict:options];
    
    if (thumbnail) {
        //[[ThumbnailService sharedService] saveThumbnail:thumbnail thumbOptions:options];
    }
    
    return thumbnail;
}

- (UIImage *) thumbnailForMediaFile:(MediaFile *) _mediaFile{//Will used in 'Media' tab
    
    return [self thumbnailForMediaFile:_mediaFile fileSuffix:nil style:ThumbnailStyleRoundCorners opaque:NO];
}
- (NSUInteger) numberToGenerateForMediaFiles:(NSArray *) _mediaFiles{
    NSUInteger count = 0;
    
    for (MediaFile * file in _mediaFiles){
        
        NSMutableDictionary * options = [[NSMutableDictionary alloc] init];
        
        [options setValue:file.mimeType forKey:@"mime"];
        [options setValue:[file fileName] forKey:@"fileName"];
        [options setValue:[NSValue valueWithCGSize:kThumbSmallSize] forKey:@"size"];
        
        NSMutableDictionary * styleOptions = [[NSMutableDictionary alloc] init];
        [styleOptions setValue:[NSNumber numberWithInt:ThumbnailStyleRoundCorners] forKey:@"type"];
        [styleOptions setValue:[NSNumber numberWithBool:NO] forKey:@"opaque"];
        [styleOptions setValue:nil forKey:@"fileSuffix"];
        [options setValue:styleOptions forKey:@"style"];
        
        if (![self isThumbnailExistForOptionsDict:options]) count++;
    }
    return count;
}


#define kLeftImageModifier @"Received"
#define kRightImageModifier @"Sent"

- (UIImage *) thumbnailForAttachment:(MessageAttachment *) _attachment styled:(BOOL) _styled{
    
    return [self thumbnailForMediaFile:_attachment.mediaFile 
                            fileSuffix:_attachment.isReceived?kLeftImageModifier:kRightImageModifier 
                                 style:_styled?ThumbnailStyleRoundCorners:ThumbnailStyleNone
                                opaque:!_styled];
}

- (UIImage *) thumbnailForAttachment:(MessageAttachment *)_attachment withVideoURL:(NSURL *)videoURL {
    UIImage *thumb = [self imageFromVideoURL:videoURL];
    return [self thumbnailForAttachment:_attachment withImage:thumb];
}

- (UIImage *) thumbnailForAttachment:(MessageAttachment *) _attachment withImage: (UIImage *) image styled:(BOOL)styled
{
    NSMutableDictionary * options = [[NSMutableDictionary alloc] init];
    
    [options setValue:_attachment.mediaFile.mimeType forKey:@"mime"];
    [options setValue:[_attachment.mediaFile fileName] forKey:@"fileName"];
    [options setValue:[NSValue valueWithCGSize:kThumbSmallSize] forKey:@"size"];
    [options setValue:image forKey:@"generationImage"];
    
    ThumbnailStyle style = styled ? ThumbnailStyleRoundCorners : ThumbnailStyleNone;
    BOOL opaque = !styled;
    
    NSMutableDictionary * styleOptions = [[NSMutableDictionary alloc] init];
    [styleOptions setValue:[NSNumber numberWithInt:style] forKey:@"type"];
    [styleOptions setValue:[NSNumber numberWithBool:opaque] forKey:@"opaque"];
    [options setValue:styleOptions forKey:@"style"];
    
    UIImage * thumbnail = [[ThumbnailService sharedService] thumbnailForOptionsDict:options];
    
    if (thumbnail) {
        [[ThumbnailService sharedService] saveThumbnail:thumbnail thumbOptions:options];
    }
    
    return thumbnail;
}

- (UIImage *) thumbnailForAttachment:(MessageAttachment *)_attachment withImage:(UIImage *) image
{
    UIImage * thumbnailStyled = [self thumbnailForAttachment:_attachment withImage:image styled:NO];
    return thumbnailStyled;
}

- (BOOL) removeAllThumbnailsForAttachment:(MessageAttachment *) _attachment{

    return [self removeAllThumbnailsForMediaFile:_attachment.mediaFile];
}


@end

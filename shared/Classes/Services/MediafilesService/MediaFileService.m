//
//  MediafilesService.m
//  qliq
//
//  Created by Paul Bar on 4/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MediaFileService.h"
#import "MediaFile.h"
#import "UserSession.h"
#import "UserSessionService.h"
#import "QliqUser.h"
#import "CryptoWrapper.h"
#import "NSFileManager+CreateDirForFile.h"
#import "UIImage+ScaleAndRotate.h"
#import <QuartzCore/QuartzCore.h>
#import "DBUtil.h"
#import "MediaFileDBService.h"

#define kLeftImageModifier @"Received"
#define kRightImageModifier @"Sent"

#define kNameSearchTemplate @"Received"

#define kAudioImageName      @"Chat-Bubble-Received-AudioFile"
#define kRTFImageName        @"Chat-Bubble-Received-RTF-File"
#define kExcelImageName      @"Chat-Bubble-Received-Excel-File"
#define kTXTImageName        @"Chat-Bubble-Received-TXT-File"
#define kDOCImageName        @"Chat-Bubble-Received-Word-File"
#define kPDFImageName        @"Chat-Bubble-Received-PDF-File"
#define kPPTImageName        @"Chat-Bubble-Received-PPT-File"

#define kUnsupportedImageName @"Chat-Bubble-Received-Unsupported-File"

static MediaFileService *instance = nil;

@implementation MediaFileService{
    NSDictionary * documentsTypes;
    NSDictionary * audioTypes;
    NSArray *videoTypes;
    NSArray *imageTypes;
    
    CryptoWrapper *crypto;
}

+(MediaFileService*)getInstance
{
    @synchronized(self)
    {
        if(instance == nil)
        {
            instance = [[MediaFileService alloc] init];
        }
        return instance;
    }
}
#pragma mark - type of file

- (BOOL) isGeneratableThumbMime:(NSString *)_mime FileName:(NSString *) _fileName {
    return [self isVideoFileMime:_mime FileName:_fileName] || [self isImageFileMime:_mime FileName:_fileName];
}

- (BOOL) isAudioFileMime:(NSString*) _mime FileName:(NSString *) _fileName{
    NSString * imageName = nil;

    imageName = [audioTypes valueForKey:[_fileName pathExtension]];
    if (!imageName)
        imageName = [audioTypes valueForKey:_mime];

    return imageName != nil;
}

- (BOOL) isDocumentFileMime:(NSString*) _mime FileName:(NSString *) _fileName{
    NSString * imageName = nil;

    imageName = [documentsTypes valueForKey:[_fileName pathExtension]];
    if (!imageName)
        imageName = [documentsTypes valueForKey:_mime];

    return imageName != nil;
}

- (BOOL) isImageFileMime:(NSString *) _mime FileName: (NSString *) _fileName{

    return [imageTypes containsObject:_mime] || [imageTypes containsObject:[_fileName pathExtension]];

}
- (BOOL) isVideoFileMime:(NSString *) _mime FileName: (NSString *) _fileName {

    return [videoTypes containsObject:_mime] || [videoTypes containsObject:[_fileName pathExtension]];
}

- (MediaFileType) typeNameForMime:(NSString *) _mime FileName: (NSString *) _fileName{
    
    if ([self isDocumentFileMime:_mime FileName:_fileName]) return MediaFileTypeDocument;
    if ([self isAudioFileMime:_mime FileName:_fileName])    return MediaFileTypeAudio;
    if ([self isImageFileMime:_mime FileName:_fileName])    return MediaFileTypeImage;
    if ([self isVideoFileMime:_mime FileName:_fileName])    return MediaFileTypeVideo;

    return MediaFileTypeUnknown;
    
}

- (NSString *) imageNameForMimeType:(NSString *) _mime andFileName: (NSString *) _fileName{
    NSString * imageName = nil;
    NSString * fileExtension = [_fileName pathExtension];
    
    //for document
    if (!imageName){
        imageName = [documentsTypes valueForKey:fileExtension];
    }
    if (!imageName){
        imageName = [documentsTypes valueForKey:_mime];
    }
    //for audio
    if (!imageName){
        imageName = [audioTypes valueForKey:fileExtension];
    }
    if (!imageName){
        imageName = [audioTypes valueForKey:_mime];
    }
    
    return imageName;
}

- (NSString*) imageNameForUnsupportedTypeSuffix:(NSString *) _suffix{
    
    return [kUnsupportedImageName stringByReplacingOccurrencesOfString:kNameSearchTemplate withString:_suffix];
}

- (NSString*) imageNameForUnsupportedTypeLeft:(BOOL) _left{
    
    return [self imageNameForUnsupportedTypeSuffix:_left?kLeftImageModifier:kRightImageModifier];
}

- (NSString*) imageNameForMimeType:(NSString *)_mime andFileName:(NSString *)_fileName fileSuffix:(NSString *) _suffix{
    
    NSString * fileName = [self imageNameForMimeType:_mime andFileName:_fileName];
    
    if (fileName) {
        if (_suffix) {
            // Adam Sowa: I have no idea what is this line for? It replaces resource file name
            // by putting file suffix in the middle of it, which result in non existing file
            // It doesn't make any sense for me.
            //fileName = [fileName stringByReplacingOccurrencesOfString:kNameSearchTemplate withString:_suffix];
        }
    } else {
        if (_suffix) {
            fileName = [self imageNameForUnsupportedTypeSuffix:_suffix];
        } else {
            fileName = [self imageNameForUnsupportedTypeLeft:NO];
        }
    }

    return fileName;
}

- (NSString*) imageNameForMimeType:(NSString *)_mime andFileName:(NSString *)_fileName left:(BOOL) _left{

    return [self imageNameForMimeType:_mime andFileName:_fileName fileSuffix:_left?kLeftImageModifier:kRightImageModifier];
}

- (BOOL) fileSupportedWithMimeType:(NSString *) _mime andFileName:(NSString *) _fileName{
    
    MediaFileType type = [self typeNameForMime:_mime FileName:_fileName];
    return type != MediaFileTypeUnknown;
}

- (NSArray *) audioMimeTypes{
    return [audioTypes allKeys];
}

- (NSArray *) imagesMimeTypes{
    return imageTypes;
}
- (NSArray *) videoMimeTypes{
    return videoTypes;
}

- (NSArray *) documentsMimeTypes{
    
    NSArray *arrayDocuments = [documentsTypes allKeys];
    
    return arrayDocuments;
}

- (NSArray *) pdfMimeTypes {
    
    NSMutableArray *pdfArray = [[NSMutableArray alloc] init];
    
    for (NSString *pdfString in [documentsTypes allKeys])
    {
        if ([[documentsTypes valueForKey:pdfString] isEqualToString:kPDFImageName]) {
            [pdfArray addObject:pdfString];
        }
    }
    return [pdfArray copy];
}

- (BOOL)isPDF:(MediaFile *)mediaFile
{
    NSSet* pdfMimeTypeSet = [NSSet setWithArray:[[MediaFileService getInstance] pdfMimeTypes]];
    return [pdfMimeTypeSet containsObject:mediaFile.mimeType];
}

- (NSString*) directoryForMediafilesWithMimeType:(NSString *)mime andFileName:(NSString *) fileName {
    
    NSString * mediaFolder = @"Unknown/";
    if ([self isImageFileMime:mime FileName:fileName]){
        mediaFolder = @"Images/";
    }else if ([self isDocumentFileMime:mime FileName:fileName]){
        mediaFolder = @"Documents/";
    }else if ([self isAudioFileMime:mime FileName:fileName]){
        mediaFolder = @"Audios/";
    }else if ([self isVideoFileMime:mime FileName:fileName]){
        mediaFolder = @"Videos/";
    }
    
    NSString *usersDir = [NSString stringWithFormat:@"Documents/%@",[UserSessionService currentUserSession].user.qliqId];//[UserSessionService currentUsersDirPath];
    NSString *mediaFilesDirPath = [NSString stringWithFormat:@"%@/Media/%@",usersDir,mediaFolder];
    
    return mediaFilesDirPath;
}

+ (NSString *)generateAbsoluteDirectoryPathFor:(NSString *)mime fileName:(NSString *)fileName
{
    NSString * directoryPath = [[MediaFileService getInstance] directoryForMediafilesWithMimeType:mime andFileName:fileName];
    NSString * absoluteDirectoryPath = nil;
    
    if (directoryPath)
    {
        NSString * documentsRootPath =  [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByDeletingLastPathComponent];
        absoluteDirectoryPath = [NSString stringWithFormat:@"%@/%@",documentsRootPath,directoryPath];
    }
    
    if (absoluteDirectoryPath.length > 0)
        [[NSFileManager defaultManager] createDirectoryAtPath:absoluteDirectoryPath withIntermediateDirectories:YES attributes:NULL error:nil];
    else
        return nil;
    
    return absoluteDirectoryPath;
}

-(id) init
{
    self = [super init];
    if(self)
    {
        crypto = [[CryptoWrapper alloc] init];
        
        audioTypes = [NSDictionary dictionaryWithObjectsAndKeys:
                       kAudioImageName,@"audio/aiff",
                       kAudioImageName,@"audio/x-aiff",
                       kAudioImageName,@"audio/mpeg3",
                       kAudioImageName,@"audio/x-mpeg-3",
                       kAudioImageName,@"audio/wav",
                       kAudioImageName,@"audio/x-wav",
                       kAudioImageName,@"mp3",
                       kAudioImageName,@"wav",
                       kAudioImageName,@"MP3",
                       kAudioImageName,@"WAV",
                       kAudioImageName,@"aiff",
                       kAudioImageName,@"audio/mpeg",
                       kAudioImageName,@"caf",
                       kAudioImageName,@"audio/caf",
                       kAudioImageName,@"audio/m4a",
                       kAudioImageName,@"audio/aac",
                       kAudioImageName,@"m4a",
                       kAudioImageName,@"audio/mp4",
                       nil];
        
        documentsTypes = [NSDictionary dictionaryWithObjectsAndKeys: //AIIIII pptx
                           kRTFImageName,@"text/rtf",
                           kRTFImageName,@"rtf",
                           kExcelImageName,@"application/vnd.ms-excel",
                           kExcelImageName,@"application/msexcel",
                           kExcelImageName,@"xls",
                           kExcelImageName,@"xlsx",
                           kTXTImageName,@"txt",
                           kTXTImageName,@"csv",
                           kTXTImageName,@"text/plain",
                           kUnsupportedImageName,@"application/zip", //Maybe problem with this type
                           kTXTImageName,@"application/txt",
                           kDOCImageName,@"application/msword", // .doc                          
                           kDOCImageName,@"application/vnd.msword",
                           kDOCImageName,@"application/vnd.ms-office",
                           kDOCImageName,@"application/vnd.openxmlformats-officedocument.wordprocessingml.document", // .docx
                           kDOCImageName,@"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", // .xlsx
                           kPPTImageName,@"application/vnd.openxmlformats-officedocument.presentationml.presentation", //pptx
                           kDOCImageName,@"doc",
                           kDOCImageName,@"docx",
                           kPDFImageName,@"pdf",
                           kPDFImageName,@"application/pdf",
                           kPDFImageName,@"application/x-pdf",
                           nil];
        
        imageTypes = [NSArray arrayWithObjects:
                       @"application/tiff",
                       @"application/x-tiff",
                       @"application/jpeg",
                       @"application/jpg",
                       @"application/pjpeg",
                       @"application/gif",
                       @"application/png",
                       @"application/bmp",
                       @"application/x-icon",
                       @"application/x-xbitmap",
                       @"application/x-xbm",
                       @"application/xbm",
                       @"image/tiff",
                       @"image/x-tiff",
                       @"image/jpeg",
                       @"image/jpg",
                       @"image/pjpeg",
                       @"image/gif",
                       @"image/png",
                       @"image/bmp",
                       @"image/x-icon",
                       @"image/x-xbitmap",
                       @"image/x-xbm",
                       @"image/xbm",
                       @"jpg",
                       @"jpeg",
                       @"png",
                       @"PNG",
                       @"xbm",
                       @"gif",
                       @"bmp",
                       nil];
        
        videoTypes = [NSArray arrayWithObjects:
                      @"video/mp4",
                      @"video/quicktime",
                      @"mov",
                      @"mp4",
                      nil];
        
        
    }
    return self;
}

//decrypt from 'encryptedPath' to 'decryptedPath'

- (BOOL) decryptMediaFile: (MediaFile *) _mediaFile{
//    NSDate * stratDate = [NSDate date];
    
    if (_mediaFile.decryptedPath || !_mediaFile.encryptedPath)
        return (_mediaFile.decryptedPath != nil);
   
    [[NSFileManager defaultManager] createDirectoryAtPath:kDecryptedDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *toPath = [NSString stringWithFormat:@"%@%@",kDecryptedDirectory,[_mediaFile.encryptedPath lastPathComponent]];
    NSString *extension = [toPath pathExtension];
    if (extension.length == 0) {
        // Encrypted path may be without extension, but when decrypting
        // we need to append a valid extension to allow opening the decrypted file properly
        extension = [_mediaFile.fileName pathExtension];
        if (extension.length > 0) {
            toPath = [toPath stringByAppendingFormat:@".%@", extension];
        }
    }
    [[NSFileManager defaultManager] removeItemAtPath:toPath error:nil];
    
    if([crypto decryptFileAthPath:_mediaFile.encryptedPath withKey:_mediaFile.encryptionKey andSaveToPath:toPath]){
        _mediaFile.decryptedPath = toPath;
//         DDLogSupport(@"decrypted: %f", -[stratDate timeIntervalSinceNow]);
        return YES;
    }
    
    return NO;
}


//encrypt from 'decryptedPath' to 'encryptedPath'
- (BOOL) encryptMediaFile: (MediaFile *) _mediaFile{
    
    if (!_mediaFile.decryptedPath || _mediaFile.encryptedPath)
        return (_mediaFile.encryptedPath != nil);
    
    NSString *libFileName = [_mediaFile generateFilePathForName:_mediaFile.fileName];
    NSString *checksum = nil;
    NSString *key = [crypto encryptFileAtPath:_mediaFile.decryptedPath andSaveToPath:libFileName outChecksum:&checksum];
    if(key != nil){
        _mediaFile.encryptionKey = key;
        _mediaFile.encryptedPath = libFileName;
        _mediaFile.checksum = checksum;
        _mediaFile.fileSizeString = [[_mediaFile encryptedFileSizeNumber] stringValue];
        _mediaFile.timestamp = [NSDate date].timeIntervalSince1970;
        return YES;
    }
    return NO;
}

- (BOOL) wipeMediafiles{
    
    __block BOOL success = YES;
    
    MediaFileDBService * dbService = [MediaFileDBService sharedService];
    
    NSDictionary * mediaFilesItemsRequest = [NSDictionary dictionaryWithObjectsAndKeys:
                                             [dbService mediafilesWithMimeTypes:[self imagesMimeTypes] archived:NO],@"Photos",
                                             [dbService mediafilesWithMimeTypes:[self audioMimeTypes] archived:NO],@"Audio",
                                             [dbService mediafilesWithMimeTypes:[self videoMimeTypes] archived:NO],@"Video",
                                             [dbService mediafilesWithMimeTypes:[self documentsMimeTypes] archived:NO],@"Documents",
                                             nil];
    
    /* wipe mediafiles */
    [mediaFilesItemsRequest enumerateKeysAndObjectsUsingBlock:^(NSString * itemName, NSArray * mediaFiles, BOOL *stop) {
        success &= [dbService markAsDeletedMediafiles:mediaFiles];
    }];
    
    /* wipe decrypted dir */
    for (NSString * path in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:kDecryptedDirectory error:nil]){
        success &= [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@%@",kDecryptedDirectory,path] error:nil];
    }
    
    return success;
}

@end




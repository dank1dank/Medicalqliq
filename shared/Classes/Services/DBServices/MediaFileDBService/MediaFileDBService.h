//
//  MediaFileDBService.h
//  qliq
//
//  Created by Aleksey Garbarev on 12/25/12.
//
//

#import "QliqDBService.h"
#import "MediaFile.h"

@interface MediaFileDBService : QliqDBService

+ (MediaFileDBService *) sharedService;

-(MediaFile*) mediafileWithId:(NSInteger)mediafileId;
- (MediaFile *)mediafileWithName:(NSString *)fileName;

- (NSArray*) mediafiles;
- (NSArray*) mediafilesWithMimeTypes:(NSArray*)mimeTypes archived:(BOOL)archived;
- (NSInteger)countOfMediaFilesWithMimeTypes:(NSArray *)mimeTypes containsFormatInName:(NSString *)nameFormat;
- (BOOL) markAsArchivedMediafiles:(NSArray*)mediafiles;
- (BOOL) markAsDeletedMediafiles:(NSArray*)mediafiles;

- (BOOL) deleteMediaFile:(MediaFile *)mediaFile;
- (BOOL) deleteMediaFileWithId:(NSInteger)mediaFileId;
- (BOOL) deleteMediaFilesWithoutAttachments;
- (BOOL) deleteMediaFilesOlderThan:(NSTimeInterval)ti;

- (void)removeMediaFileAndAttachment:(MediaFile *)mediaFile;

@end

//
//  MediaFileUploadDBService.h
//  qliq
//
//  Created by Adam Sowa on 14/04/17.
//
//

#import <Foundation/Foundation.h>
#import "MediaFileUpload.h"

@interface MediaFileUploadDBService : NSObject

+ (MediaFileUpload *) getWithId:(int)databaseId;
// Returns count of uploads to EMR or qliqStor
+ (int) countWithShareType:(MediaFileUploadShareType)shareType;
+ (int) successfullyCountgWithShareType:(MediaFileUploadShareType)shareType skip:(int)skip limit:(int)limit;
+ (NSMutableArray *) getWithShareType:(MediaFileUploadShareType)shareType skip:(int)skip limit:(int)limit;

+ (void) removeUploadAndMediaFile:(QxMediaFile *)mediaFile;
// Delete upload from db table only
+ (BOOL) deleteRowWithId:(int)databaseId;
// Delete upload that has specified media file
+ (BOOL) deleteRowWithMediaFileId:(int)databaseId;

@end

@interface QxMediaFileDBService : NSObject

+ (QxMediaFile *) getWithId:(int)databaseId;
+ (BOOL) deleteRowWithId:(int)databaseId;

@end


@interface MediaFileUploadEventDBService : NSObject

+ (NSMutableArray *) getWithUploadId:(int)uploadId;

@end

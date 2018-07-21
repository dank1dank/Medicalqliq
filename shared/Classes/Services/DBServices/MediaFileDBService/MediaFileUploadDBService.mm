//
//  MediaFileUploadDBService.m
//  qliq
//
//  Created by Adam Sowa on 14/04/17.
//
//

#import "MediaFileUploadDBService.h"
#import "qxlib/platform/ios/QxPlatfromIOSHelpers.h"
#include "qxlib/dao/QxMediaFileDao.hpp"
#include "qxlib/dao/QxMediaFileUploadDao.hpp"
#include "qxlib/dao/qliqstor/QxMediaFileUploadEventDao.hpp"

#import "MediaFileService.h"

@implementation MediaFileUploadDBService

+ (MediaFileUpload *) getWithId:(int)databaseId
{
    qx::MediaFileUpload cpp = qx::MediaFileUploadDao::selectOneBy(qx::MediaFileUploadDao::IdColumn, std::to_string(databaseId));
    cpp.mediaFile = qx::MediaFileDao::selectOneBy(qx::MediaFileDao::IdColumn, std::to_string(cpp.mediaFile.databaseId));
    return [[MediaFileUpload alloc] initWithCpp2:&cpp];
}

+ (int) countWithShareType:(MediaFileUploadShareType)shareType
{
    qx::dao::Query query;
    query.append(qx::MediaFileUploadDao::ShareTypeColumn, std::to_string(shareType));
    return qx::MediaFileUploadDao::count(query);
}

+ (int) successfullyCountgWithShareType:(MediaFileUploadShareType)shareType skip:(int)skip limit:(int)limit
{
    std::vector<qx::MediaFileUpload> cppVec = qx::MediaFileUploadDao::selectBy(qx::MediaFileUploadDao::ShareTypeColumn, std::to_string(shareType), skip, limit);
    int successfullCount = 0;
    for (qx::MediaFileUpload& cpp: cppVec) {
        cpp.mediaFile = qx::MediaFileDao::selectOneBy(qx::MediaFileDao::IdColumn, std::to_string(cpp.mediaFile.databaseId));
        MediaFileUpload *upload = [[MediaFileUpload alloc] initWithCpp2:&cpp];
        if (upload.status == FinalProcessingSuccesfulMediaFileUploadStatus) {
            successfullCount += 1;
        }
    }
    return successfullCount;
}

+ (NSMutableArray *) getWithShareType:(MediaFileUploadShareType)shareType skip:(int)skip limit:(int)limit
{
    std::vector<qx::MediaFileUpload> cppVec = qx::MediaFileUploadDao::selectBy(qx::MediaFileUploadDao::ShareTypeColumn, std::to_string(shareType), skip, limit);
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:cppVec.size()];
    for (qx::MediaFileUpload& cpp: cppVec) {
        cpp.mediaFile = qx::MediaFileDao::selectOneBy(qx::MediaFileDao::IdColumn, std::to_string(cpp.mediaFile.databaseId));
        MediaFileUpload *upload = [[MediaFileUpload alloc] initWithCpp2:&cpp];
        [array addObject:upload];
    }
    return array;
}

+ (BOOL) deleteRowWithId:(int)databaseId
{
    qx::MediaFileUpload upload = qx::MediaFileUploadDao::selectOneBy(qx::MediaFileUploadDao::IdColumn, std::to_string(databaseId));
    if (upload.mediaFile.databaseId > 0) {
        [QxMediaFileDBService deleteRowWithId:upload.mediaFile.databaseId];
    }
    return qx::MediaFileUploadDao::delete_(qx::MediaFileUploadDao::IdColumn, std::to_string(upload.databaseId));
}

+ (BOOL) deleteRowWithMediaFileId:(int)databaseId
{
    qx::MediaFileUpload upload = qx::MediaFileUploadDao::selectOneBy(qx::MediaFileUploadDao::MediaFileIdColumn, std::to_string(databaseId));
    if (upload.mediaFile.databaseId > 0) {
        [QxMediaFileDBService deleteRowWithId:upload.mediaFile.databaseId];
    }
    return qx::MediaFileUploadDao::delete_(qx::MediaFileUploadDao::IdColumn, std::to_string(upload.databaseId));
}

+ (void) removeUploadAndMediaFile:(QxMediaFile *)mediaFile
{
    [QxMediaFileDBService deleteRowWithId:mediaFile.databaseId];
    [self deleteRowWithMediaFileId:mediaFile.databaseId];
}

@end

@implementation QxMediaFileDBService

+ (QxMediaFile *) getWithId:(int)databaseId
{
    qx::MediaFile cpp = qx::MediaFileDao::selectOneBy(qx::MediaFileDao::IdColumn, std::to_string(databaseId));
    if (cpp.databaseId > 0) {
        return [[QxMediaFile alloc] initWithCpp2:&cpp];
    } else {
        return nil;
    }
}

+ (BOOL) deleteRowWithId:(int)databaseId
{
    return qx::MediaFileDao::delete_(qx::MediaFileDao::IdColumn, std::to_string(databaseId));
}

@end

@implementation MediaFileUploadEventDBService

+ (NSMutableArray *) getWithUploadId:(int)uploadId
{
    std::vector<qx::MediaFileUploadEvent> cppVec = qx::MediaFileUploadEventDao::selectBy(qx::MediaFileUploadEventDao::UploadIdColumn, std::to_string(uploadId));
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:cppVec.size()];
    for (qx::MediaFileUploadEvent& cpp: cppVec) {
        MediaFileUploadEvent *event = [[MediaFileUploadEvent alloc] initWithCpp2:&cpp];
        [array addObject:event];
    }
    return array;
}

@end

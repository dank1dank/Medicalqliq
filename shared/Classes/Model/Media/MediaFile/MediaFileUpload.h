//
//  MediaFileUpload.h
//  qliq
//
//  Created by Adam Sowa on 14/04/17.
//
//

#import <Foundation/Foundation.h>

// WARNING:
// all attributes of FHIR objects are read-only, changes will not propagate to C++ layer
// If attribute/object is mutable then it has explicity set or initWith methods in the interface below

typedef NS_ENUM(NSInteger, QxMediaFileStatus) {
    NormalQxMediaFileStatus = 0,
    ArchivedQxMediaFileStatus = 1,
    DeletedQxMediaFileStatus = 2,
    UploadedToQliqStorQxMediaFileStatus = 3,
    UploadedToEmrQxMediaFileStatus = 4,
    UploadedToFaxQxMediaFileStatus = 5
};

@interface QxMediaFile : NSObject

- (int) databaseId;
- (NSString *) mimeType;
- (NSString *) fileName;
- (NSString *) thumbnail;
- (NSString *) url;
- (NSString *) key;
- (NSString *) encryptedFilePath;
- (NSString *) decryptedFilePath;
- (QxMediaFileStatus) status;

// Methods
- (NSString *) timestampToUiText;
- (UIImage *) thumbnailAsImage;

// Methods for viewing (UI)
//
// Returns path ready to open or null
- (NSString *) filePathForView;
/// Returns true if file can be opened immediately
- (BOOL) isCanView;
/// Returns true if file is on disk and can be decrypted
- (BOOL) isCanDecrypt;
/// Returns true if the \ref url is not empty and file can be downloaded
- (BOOL) isCanDownload;

- (id) initWithCpp2:(void *)cppObject;
- (void *) cppValue;

@end

typedef void (^QxMediaFileManagerCompletionBlock)(int mediaFileId, NSString *errorMessage);

@interface QxMediaFileManager : NSObject

+ (BOOL) decrypt:(QxMediaFile *)mediaFile;
+ (BOOL) download:(QxMediaFile *)mediaFile withCompletion:(QxMediaFileManagerCompletionBlock)completion;

/// Removes the decrypted file from disk and updates QxMediaFile in database
+ (BOOL) removeDecrypted:(QxMediaFile *)mediaFile;

/// Removes the QxMediaFile from database and related files from disk
+ (BOOL) remove:(MediaFile *)mediaFile;

@end

typedef NS_ENUM(NSInteger, MediaFileUploadShareType) {
    UnknownMediaFileUploadShareType = 0,
    UploadedToQliqStorMediaFileUploadShareType = 1,
    UploadedToEmrMediaFileUploadShareType = 2,
    UploadedToFaxMediaFileUploadShareType = 3
};

typedef NS_ENUM(NSInteger, MediaFileUploadStatus) {
    UnknownMediaFileUploadStatus = 0,                  // uknown, ie. comes from newer app
    PendingUploadMediaFileUploadStatus = 1,            // waiting for upload to cloud
    UploadingMediaFileUploadStatus = 2,                // uploading to cloud right now
    UploadToCloudFailedMediaFileUploadStatus = 3,      // either network or cloud error
    UploadedToCloudMediaFileUploadStatus = 4,          // uploaded to cloud (200 OK)
    FinalProcessingSuccesfulMediaFileUploadStatus = 5, // stored on qS or uploaded to EMR system
    TemporaryQliqStorFailureErrorMediaFileUploadStatus = 6,
    TargetNotFoundMediaFileUploadStatus = 7,           // EMR target (ie patient, encounter) not found, sender should not reply
    PermanentQliqStorFailureErrorMediaFileUploadStatus = 8,
    ThirdPartySuccessStatusMediaFileUploadStatus = 9,
    ThirdPartyFailureStatusMediaFileUploadStatus = 10,
};

@interface MediaFileUpload : NSObject
// Attributes
- (int) databaseId;
- (NSString *) uploadUuid;
- (NSString *) qliqStorQliqId;
- (QxMediaFile *) mediaFile;
- (MediaFileUploadShareType) shareType;
- (MediaFileUploadStatus) status;

// Methods
- (BOOL) isEmpty;
- (BOOL) isUploaded;
- (BOOL) isFailed;
- (BOOL) canRetry;
- (NSString *) statusToUiText;
- (id) initWithCpp2:(void *)cppObject;
- (void *) cppValue;

@end

typedef NS_ENUM(NSInteger, MediaFileUploadObserverEvent) {
    CreatedMediaFileUploadEvent = 0,
    UpdatedMediaFileUploadEvent = 1,
    DeletedMediaFileUploadEvent = 2
};

@protocol MediaFileUploadObserver
- (void) mediaFileUploadEvent:(MediaFileUploadObserverEvent)event databaseId:(int)databaseId;
@end

@interface MediaFileUploadObservable : NSObject

- (void)addObserver:(id<MediaFileUploadObserver>)observer;
- (void)removeObserver:(id<MediaFileUploadObserver>)observer;

+ (MediaFileUploadObservable *) sharedInstance;

@end

@interface MediaFileUploadEvent : NSObject
// Attributes
- (time_t) timestamp;
- (int) type;
- (NSString *) eventString;
- (NSString *) message;

// Methods
- (id) initWithCpp2:(void *)cppObject;

+ (NSString *) typeToString:(int)eventType forShareType:(MediaFileUploadShareType)shareType;
@end

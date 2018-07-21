//
//  MediaFileUpload.m
//  qliq
//
//  Created by Adam Sowa on 14/04/17.
//
//

#import "MediaFileUpload.h"
#import "NSData+MKBase64.h"
#import "AIObservable.h"
#import "NSInvocation+AIConstructors.h"
#import "ThumbnailService.h"
#import "qxlib/platform/ios/QxPlatfromIOSHelpers.h"
#include "qxlib/model/QxMediaFile.hpp"
#include "qxlib/controller/QxMediaFileManager.hpp"

using qx::toStdString;
using qx::toNSString;

@interface QxMediaFile() {
    qx::MediaFile cpp;
}

@end

@implementation QxMediaFile

- (id) initWithCpp:(const qx::MediaFile&) cppObject
{
    self = [super init];
    if (self) {
        cpp = cppObject;
    }
    return self;
}

- (id) initWithCpp2:(void *)cppObject
{
    return [self initWithCpp:*reinterpret_cast<qx::MediaFile *>(cppObject)];
}

- (void *) cppValue
{
    return &cpp;
}

- (int) databaseId
{
    return cpp.databaseId;
}

- (NSString *) mimeType
{
    return toNSString(cpp.mime);
}

- (NSString *) fileName
{
    return toNSString(cpp.fileName);
}

- (NSString *) thumbnail
{
    return toNSString(cpp.thumbnail);
}

- (NSString *) url
{
    return toNSString(cpp.url);
}

- (NSString *) key
{
    return toNSString(cpp.key);
}

- (NSString *) encryptedFilePath
{
    return toNSString(cpp.encryptedFilePath);
}

- (NSString *) decryptedFilePath
{
    return toNSString(cpp.decryptedFilePath);
}

- (QxMediaFileStatus) status
{
    return (QxMediaFileStatus)cpp.status;
}

- (NSString *) timestampToUiText
{
    return qx::toNSString(cpp.timestampToUiText());
}

- (UIImage *) thumbnailAsImage
{
    if (cpp.thumbnail.empty()) {
        return [ThumbnailService genericThumbnailForFileName:self.fileName mimeType:self.mimeType style:ThumbnailStyleRoundCorners opaque:NO];
    } else {
        NSData *thumbData = [NSData dataFromBase64String:self.thumbnail];
        return [UIImage imageWithData:thumbData];
    }
}

- (NSString *) filePathForView
{
    return qx::toNSString(cpp.filePathForView());
}

- (BOOL) isCanView
{
    return cpp.isCanView();
}

- (BOOL) isCanDecrypt
{
    return cpp.isCanDecrypt();
}

- (BOOL) isCanDownload
{
    return cpp.isCanDownload();
}

@end

@interface MediaFileUpload() {
    qx::MediaFileUpload cpp;
}

@end

@implementation QxMediaFileManager

+ (BOOL) decrypt:(QxMediaFile *)mediaFile
{
    return qx::MediaFileManager::decrypt((qx::MediaFile *)mediaFile.cppValue);
}

+ (BOOL) download:(QxMediaFile *)mediaFile withCompletion:(QxMediaFileManagerCompletionBlock)completion
{
    return qx::MediaFileManager::download((qx::MediaFile *)mediaFile.cppValue, [=](int mediaFileId, const std::string& errorMessage) {
        if (completion) {
            completion(mediaFileId, qx::toNSString(errorMessage));
        }
    });
}

+ (BOOL) removeDecrypted:(QxMediaFile *)mediaFile
{
    return qx::MediaFileManager::removeDecrypted((qx::MediaFile *)mediaFile.cppValue);
}

+ (BOOL) remove:(QxMediaFile *)mediaFile
{
    return qx::MediaFileManager::remove((qx::MediaFile *)mediaFile.cppValue);
}

@end

@implementation MediaFileUpload

- (id) initWithCpp:(const qx::MediaFileUpload&) cppObject
{
    self = [super init];
    if (self) {
        cpp = cppObject;
    }
    return self;
}

- (id) initWithCpp2:(void *)cppObject
{
    return [self initWithCpp:*reinterpret_cast<qx::MediaFileUpload *>(cppObject)];
}

- (void *) cppValue
{
    return &cpp;
}

- (int) databaseId
{
    return cpp.databaseId;
}

- (NSString *) uploadUuid
{
    return toNSString(cpp.uploadUuid);
}

- (NSString *) qliqStorQliqId
{
    return toNSString(cpp.qliqStorQliqId);
}

- (QxMediaFile *) mediaFile
{
    return [[QxMediaFile alloc] initWithCpp:cpp.mediaFile];
}

- (MediaFileUploadShareType) shareType
{
    return (MediaFileUploadShareType)cpp.shareType;
}

- (MediaFileUploadStatus) status
{
    return (MediaFileUploadStatus)cpp.status;
}

- (BOOL) isEmpty
{
    return cpp.isEmpty();
}

- (BOOL) isUploaded
{
    return cpp.isUploaded();
}

- (BOOL) isFailed
{
    return cpp.isFailed();
}

- (BOOL) canRetry
{
    return cpp.canRetry();
}

- (NSString *) statusToUiText
{
    return qx::toNSString(cpp.statusToUiText());
}

@end

/////////////////////////////////////////////////////////////////////////////////////////////////////////

class MediaFileUploadSubscriberImpl;

@interface MediaFileUploadObservable() {
    MediaFileUploadSubscriberImpl *cppSubscriber;
}

@property (nonatomic, strong) AIObservable* observable;

- (void) notifyObservers:(NSInteger)event databaseId:(int)databaseId;

@end

class MediaFileUploadSubscriberImpl : public qx::MediaFileUploadSubscriber {
public:
    MediaFileUploadSubscriberImpl(void *self) :
    m_self(self)
    {}
    
    void onMediaFileUploadEvent(Event event, int databaseId) override
    {
        [(__bridge id)m_self notifyObservers:(NSInteger)event databaseId:databaseId];
    }
    
private:
    void *m_self;
};

@implementation MediaFileUploadObservable

- (id) init
{
    self = [super init];
    if (self) {
        _observable = [[AIObservable alloc] init];
        cppSubscriber = new MediaFileUploadSubscriberImpl((__bridge void *)self);
        qx::MediaFileUploadNotifier::instance()->subscribe(cppSubscriber);
    }
    return self;
}

- (void) dealloc
{
    qx::MediaFileUploadNotifier::instance()->subscribe(cppSubscriber);
    delete cppSubscriber;
}

+ (id) sharedInstance
{
    static MediaFileUploadObservable *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (void)addObserver:(id<MediaFileUploadObserver>)observer
{
    [self.observable addObserver:observer];
}

- (void)removeObserver:(id<MediaFileUploadObserver>)observer
{
    [self.observable removeObserver:observer];
}

- (void) notifyObservers:(NSInteger)event databaseId:(int)databaseId
{
    MediaFileUploadObserverEvent objcEvent = (MediaFileUploadObserverEvent)event;
    NSInvocation* invocation = [NSInvocation invocationWithProtocol:@protocol(MediaFileUploadObserver)
                                                           selector:@selector(mediaFileUploadEvent:databaseId:)];
    [invocation setArgument:&objcEvent atIndex:2];
    [invocation setArgument:&databaseId atIndex:3];
    [self.observable notifyObservers:invocation];
}

@end

@interface MediaFileUploadEvent() {
    qx::MediaFileUploadEvent cpp;
}
@end

@implementation MediaFileUploadEvent

- (id) initWithCpp:(const qx::MediaFileUploadEvent&) cppObject
{
    self = [super init];
    if (self) {
        cpp = cppObject;
    }
    return self;
}

- (id) initWithCpp2:(void *)cppObject
{
    return [self initWithCpp:*reinterpret_cast<qx::MediaFileUploadEvent *>(cppObject)];
}

- (time_t) timestamp
{
    return cpp.timestamp;
}

- (int) type
{
    return static_cast<int>(cpp.type);
}

- (NSString *) eventString
{
    return toNSString(cpp.typeToString());
}

- (NSString *) message
{
    return toNSString(cpp.message);
}

+ (NSString *) typeToString:(int)eventType forShareType:(MediaFileUploadShareType)shareType
{
    qx::MediaFileUploadEvent::Type cppType = static_cast<qx::MediaFileUploadEvent::Type>(eventType);
    qx::MediaFileUpload::ShareType cppShareType = static_cast<qx::MediaFileUpload::ShareType>(shareType);
    return toNSString(qx::MediaFileUploadEvent::typeToString(cppType, cppShareType));
}

@end

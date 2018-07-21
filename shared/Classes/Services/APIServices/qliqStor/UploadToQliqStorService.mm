//
//  UploadToQliqStorService.m
//  qliq
//
//  Created by Adam Sowa on 14/04/17.
//
//

#import "UploadToQliqStorService.h"
#import "MediaFileUpload.h"
#import "QliqGroupDBService.h"
#import "qxlib/platform/ios/QxPlatfromIOSHelpers.h"
#include "qxlib/controller/qliqstor/QxUploadToQliqStorTask.hpp"

@interface UploadToQliqStorService() {
    qx::UploadToQliqStorTask *cppTask;
}
@end

@implementation UploadToQliqStorService

- (id) init
{
    self = [super init];
    if (self) {
        cppTask = new qx::UploadToQliqStorTask();
    }
    return self;
}

- (void) dealloc
{
    delete cppTask;
}

- (void) uploadFile:(NSString *)filePath displayFileName:(NSString *)displayFileName thumbnail:(NSString *)thumbnail to:(QliqStorUploadParams *)uploadParams publicKey:(NSString *)publicKey withCompletion:(CompletionBlock)completionBlock withIsCancelled:(IsCancelledBlock)isCancelledBlock
{
    using namespace qx;
    using namespace qx::web;
    
    UploadToQliqStorWebService::UploadParams cppParams;
    cppParams.uploadUuid = toStdString(uploadParams.uploadUuid);
    cppParams.qliqStorQliqId = toStdString(uploadParams.qliqStorQliqId);
    cppParams.qliqStorDeviceUuid = toStdString(uploadParams.qliqStorDeviceUuid);
    // Fax
    cppParams.fax.number = toStdString(uploadParams.faxNumber);
    cppParams.fax.voiceNumber = toStdString(uploadParams.faxVoiceNumber);
    cppParams.fax.organization = toStdString(uploadParams.faxOrganization);
    cppParams.fax.contactName = toStdString(uploadParams.faxContactName);
    cppParams.fax.subject = toStdString(uploadParams.faxSubject);
    cppParams.fax.body = toStdString(uploadParams.faxBody);
 
    return cppTask->uploadFile(cppParams, toStdString(filePath), toStdString(displayFileName), toStdString(thumbnail), toStdString(publicKey), [completionBlock](const qx::web::QliqWebError& qliqWebError) {
        CompletitionStatus objcStatus;
        NSError *objcError = nil;
        id objcResult = nil;
        
        if (!qliqWebError) {
            objcStatus = CompletitionStatusSuccess;
        } else {
            objcStatus = CompletitionStatusError;
            objcError = qliqWebErrorToNSError(qliqWebError, "UploadToQliqStorService");
        }
        
        if (completionBlock) {
            completionBlock(objcStatus, objcResult, objcError);
        }
    }, [isCancelledBlock]() -> bool {
        return isCancelledBlock && isCancelledBlock();
    });
}

- (void) reuploadFile:(MediaFileUpload *)upload publicKey:(NSString *)publicKey withCompletion:(CompletionBlock)completionBlock withIsCancelled:(IsCancelledBlock)isCancelledBlock
{
    qx::MediaFileUpload *cppUpload = reinterpret_cast<qx::MediaFileUpload *>([upload cppValue]);
    cppTask->reuploadFile(*cppUpload, qx::toStdString(publicKey), [completionBlock](const qx::web::QliqWebError& qliqWebError) {
        CompletitionStatus objcStatus;
        NSError *objcError = nil;
        id objcResult = nil;
        
        if (!qliqWebError) {
            objcStatus = CompletitionStatusSuccess;
        } else {
            objcStatus = CompletitionStatusError;
            objcError = qliqWebErrorToNSError(qliqWebError, "UploadToQliqStorService");
        }
        
        if (completionBlock) {
            completionBlock(objcStatus, objcResult, objcError);
        }
    }, [isCancelledBlock]() -> bool {
        return isCancelledBlock && isCancelledBlock();
    });
}

+ (void) processChangeNotification:(NSString *)subject payload:(NSString *)payload
{
    qx::UploadToQliqStorTask::processChangeNotification(qx::toStdString(subject), qx::toStdString(payload));
}

@end

@implementation QliqStorUploadParams

- (id) initWithFaxContact:(FaxContact *)contact
{
    if (self = [super init]) {
        self.faxNumber = contact.faxNumber;
        self.faxVoiceNumber = contact.voiceNumber;
        self.faxOrganization = contact.organization;
        self.faxContactName = contact.contactName;
        if (contact.groupQliqId.length > 0) {
            QliqGroup *group = [[QliqGroup alloc] init];
            group.qliqId = contact.groupQliqId;
            self.qliqStorQliqId = [QliqGroupDBService getQliqStorIdForGroup:group];
        }
        
        self.uploadUuid = [[NSUUID UUID] UUIDString];
    }
    return self;
}

@end

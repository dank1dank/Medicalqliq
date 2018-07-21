//
//  UploadToEmrService.m
//  qliq
//
//  Created by Adam Sowa on 24/01/17.
//
//

#import "UploadToEmrService.h"
#import "qxlib/platform/ios/QxPlatfromIOSHelpers.h"
#import "FhirResources.h"
#import "QliqGroupDBService.h"
#include "qxlib/web/emr/QxUploadToEmrWebService.hpp"
#include "qxlib/crypto/QxCrypto.hpp"
#include "qxlib/controller/qliqstor/QxUploadToQliqStorTask.hpp"

@interface UploadToEmrService() {
    qx::web::UploadToEmrWebService *cppService;
    qx::UploadToQliqStorTask *cppTask;
}
@end

@implementation UploadToEmrService

- (id) init
{
    self = [super init];
    if (self) {
        cppService = new qx::web::UploadToEmrWebService();
        cppTask = new qx::UploadToQliqStorTask();
    }
    return self;
}

- (void) dealloc
{
    delete cppService;
    delete cppTask;
}

- (void) uploadConversation:(NSString *)conversationUuid to:(EmrUploadParams *)uploadParams publicKey:(NSString *)publicKey withCompletition:(CompletionBlock)completionBlock withIsCancelled:(IsCancelledBlock)isCancelledBlock
{
    using namespace qx;
    using namespace qx::web;
    
    ExportConversation::ConversationMessageList cppList;
    cppList.conversationUuid = qx::toStdString(conversationUuid);
    //    if (list.messageUuids.count > 0) {
    //        for (NSString *uuid in list.messageUuids) {
    //            cppList.messageUuids.push_back(qx::toStdString(uuid));
    //        }
    //    }
    
    UploadToEmrWebService::UploadParams cppParams;
    cppParams.uploadUuid = toStdString(uploadParams.uploadUuid);
    cppParams.qliqStorQliqId = toStdString(uploadParams.qliqStorQliqId);
    cppParams.qliqStorDeviceUuid = toStdString(uploadParams.qliqStorDeviceUuid);
    cppParams.emr.type = toStdString(uploadParams.emrTargetType);
    cppParams.emr.uuid = toStdString(uploadParams.emrTargetUuid);
    cppParams.emr.hl7Id = toStdString(uploadParams.emrTargetHl7Id);
    cppParams.emr.name = toStdString(uploadParams.emrTargetName);
    
    return cppTask->uploadConversation(cppParams, cppList, toStdString(publicKey), [completionBlock](const qx::web::QliqWebError& qliqWebError) {
        CompletitionStatus objcStatus;
        NSError *objcError = nil;
        id objcResult = nil;
        
        if (!qliqWebError) {
            objcStatus = CompletitionStatusSuccess;
        } else {
            objcStatus = CompletitionStatusError;
            objcError = qliqWebErrorToNSError(qliqWebError, "UploadToEmrService");
        }
        
        if (completionBlock) {
            completionBlock(objcStatus, objcResult, objcError);
        }
    }, [isCancelledBlock]() -> bool {
        return isCancelledBlock && isCancelledBlock();
    });
}

- (void) uploadFile:(NSString *)filePath displayFileName:(NSString *)displayFileName thumbnail:(NSString *)thumbnail to:(EmrUploadParams *)uploadParams publicKey:(NSString *)publicKey withCompletition:(CompletionBlock)completionBlock withIsCancelled:(IsCancelledBlock)isCancelledBlock
{
    using namespace qx;
    using namespace qx::web;
    
    UploadToEmrWebService::UploadParams cppParams;
    cppParams.qliqStorQliqId = toStdString(uploadParams.qliqStorQliqId);
    cppParams.qliqStorDeviceUuid = toStdString(uploadParams.qliqStorDeviceUuid);
    cppParams.emr.type = toStdString(uploadParams.emrTargetType);
    cppParams.emr.uuid = toStdString(uploadParams.emrTargetUuid);
    cppParams.emr.hl7Id = toStdString(uploadParams.emrTargetHl7Id);
    cppParams.emr.name = toStdString(uploadParams.emrTargetName);
    cppParams.uploadUuid = toStdString(uploadParams.uploadUuid);
  
    return cppTask->uploadFile(cppParams, toStdString(filePath), toStdString(displayFileName), toStdString(thumbnail), toStdString(publicKey), [completionBlock](const qx::web::QliqWebError& qliqWebError) {
        CompletitionStatus objcStatus;
        NSError *objcError = nil;
        id objcResult = nil;
        
        if (!qliqWebError) {
            objcStatus = CompletitionStatusSuccess;
        } else {
            objcStatus = CompletitionStatusError;
            objcError = qliqWebErrorToNSError(qliqWebError, "UploadToEmrService");
        }
        
        if (completionBlock) {
            completionBlock(objcStatus, objcResult, objcError);
        }
    }, [isCancelledBlock]() -> bool {
        return isCancelledBlock && isCancelledBlock();
    });
}

+ (EmrUploadParams *) uploadParamsForPatient:(FhirPatient *)patient
{
    EmrUploadParams *up = [[EmrUploadParams alloc] init];
    up.qliqStorQliqId = [QliqGroupDBService getFirstQliqStorId];
    up.emrTargetType = @"patient";
    up.emrTargetUuid = patient.uuid;
    up.emrTargetHl7Id = patient.hl7id;
    up.emrTargetName = patient.displayName;
    up.uploadUuid = [[NSUUID UUID] UUIDString];
    return up;
}

@end

@implementation EmrUploadParams
@end

@implementation EmrUploadConversationMessageList
@end

@implementation EmrUploadFile
@end

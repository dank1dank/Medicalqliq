//
//  SearchPatientsService.m
//  qliq
//
//  Created by Adam Sowa on 13/01/17.
//
//

#import "SearchPatientsService.h"
#import "QxPlatfromIOSHelpers.h"
#include "qxlib/web/QxSearchPatientsWebService.hpp"
#include "qxlib/crypto/QxCrypto.hpp"

FhirPatientArray *FhirPatientArrayNewFromCpp(const std::vector<fhir::Patient>& patients);

@interface SearchPatientsService() {
    qx::web::SearchPatientsWebService *cppService;
}
@end

@implementation SearchPatientsService

- (id) init
{
    self = [super init];
    if (self) {
        auto crypto = qx::Crypto::instance();
        cppService = new qx::web::SearchPatientsWebService(crypto);
    }
    return self;
}

- (void) dealloc
{
    delete cppService;
}

- (void) call:(SearchPatientsServiceQuery *)query page:(int)page perPage:(int)perPage withCompletition:(CompletionBlock)completionBlock withIsCancelled:(IsCancelledBlock)isCancelledBlock
{
    using qx::toStdString;
    using qx::toNSString;
    using qx::web::qliqWebErrorToNSError;
    
    qx::web::SearchPatientsWebService::Query q;
    q.firstName = toStdString(query.firstName);
    q.lastName = toStdString(query.lastName);
    q.mrnOrVisitId = toStdString(query.mrn);
    q.dob = toStdString(query.dob);
    q.searchUuid = toStdString(query.searchUuid);
    q.qliqStorQliq = toStdString(query.qliqStorQliqId);
    
    cppService->call(q, page, perPage, [completionBlock](const qx::web::QliqWebError& qliqWebError, const qx::web::SearchPatientsWebService::Result& result) {
        CompletitionStatus objcStatus;
        NSError *objcError = nil;
        id objcResult = nil;
        
        if (!qliqWebError) {
            objcStatus = CompletitionStatusSuccess;

            SearchPatientsServiceResult *serviceResult = [[SearchPatientsServiceResult alloc] init];
            serviceResult.searchUuid = toNSString(result.searchUuid);
            serviceResult.patients = FhirPatientArrayNewFromCpp(result.patients);
            serviceResult.totalCount = result.totalCount;
            serviceResult.totalPages = result.totalPages;
            serviceResult.perPage = result.perPage;
            serviceResult.currentPage = result.currentPage;
            serviceResult.emrSourceQliqId = toNSString(result.emrSource.qliqId);
            serviceResult.emrSourceDeviceUuid = toNSString(result.emrSource.deviceUuid);
            serviceResult.emrSourcePublicKey = toNSString(result.emrSource.publicKey);
            objcResult = serviceResult;
        } else {
            objcStatus = CompletitionStatusError;
            objcError = qliqWebErrorToNSError(qliqWebError, "SearchPatientsService");
        }
        
        if (completionBlock) {
            completionBlock(objcStatus, objcResult, objcError);
        }
    }, [isCancelledBlock]() -> bool {
        return isCancelledBlock && isCancelledBlock();
    });
}

@end


@implementation SearchPatientsServiceQuery
@end

@implementation SearchPatientsServiceResult
@end

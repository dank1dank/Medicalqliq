 //
//  Created by Adam Sowa.
//
#import "ModifyFaxContactsWebService.h"
#import "FaxContact.h"
#import "qxlib/platform/ios/QxPlatfromIOSHelpers.h"
#include "qxlib/web/fax/QxModifyFaxContactsWebService.hpp"

using qx::toStdString;
using qx::toNSString;

@interface ModifyFaxContactsWebService() {
    qx::web::ModifyFaxContactsWebService cpp;
}

@end

@implementation ModifyFaxContactsWebService

- (void) callForContact:(FaxContact *)contact operation:(ModifyFaxContactOperation)operation withCompletition:(CompletionBlock)completionBlock;
{
    using qx::web::qliqWebErrorToNSError;
    
    qx::web::ModifyFaxContactsWebService::Operation op = static_cast<qx::web::ModifyFaxContactsWebService::Operation>(operation);
    const qx::FaxContact& cppContact = *reinterpret_cast<qx::FaxContact *>([contact cppValue]);
    cpp.call(cppContact, op, [completionBlock](const qx::web::QliqWebError& qliqWebError) {
        CompletitionStatus objcStatus;
        NSError *objcError = nil;
        id objcResult = nil;
        
        if (!qliqWebError) {
            objcStatus = CompletitionStatusSuccess;
            objcResult = nil;
        } else {
            objcStatus = CompletitionStatusError;
            objcError = qliqWebErrorToNSError(qliqWebError, "ModifyFaxContactsWebService");
        }
        
        if (completionBlock) {
            completionBlock(objcStatus, objcResult, objcError);
        }
    });
}

@end

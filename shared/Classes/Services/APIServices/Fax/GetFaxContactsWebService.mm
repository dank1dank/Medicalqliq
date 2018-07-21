 //
//  Created by Adam Sowa.
//
#import "GetFaxContactsWebService.h"
#import "qxlib/platform/ios/QxPlatfromIOSHelpers.h"
#include "qxlib/web/fax/QxGetFaxContactsWebService.hpp"

using qx::toStdString;
using qx::toNSString;

@interface GetFaxContactsWebService() {
    qx::web::GetFaxContactsWebService cpp;
}

@end

@implementation GetFaxContactsWebService

- (void) callWithCompletition:(CompletionBlock)completionBlock
{
    using qx::web::qliqWebErrorToNSError;
    
    cpp.call([completionBlock](const qx::web::QliqWebError& qliqWebError) {
        CompletitionStatus objcStatus;
        NSError *objcError = nil;
        id objcResult = nil;
        
        if (!qliqWebError) {
            objcStatus = CompletitionStatusSuccess;
            objcResult = nil;
        } else {
            objcStatus = CompletitionStatusError;
            objcError = qliqWebErrorToNSError(qliqWebError, "GetFaxContactsWebService");
        }
        
        if (completionBlock) {
            completionBlock(objcStatus, objcResult, objcError);
        }
    });
}

@end

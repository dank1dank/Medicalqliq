//
//  QxPlatfromIOSHelpers.h
//  qliq
//
//  Created by Adam Sowa on 24/01/17.
//
//

#import <Foundation/Foundation.h>
#include <string>

namespace json11 {
    class Json;
}

namespace qx {

    // string
    NSString *toNSString(const std::string& cpp);
    std::string toStdString(NSString *nss);
    std::string toStdStringAsciiOnly(NSString *nss);
    
    // JSON to NSDictionary
    NSMutableDictionary *toNSDictionary(const json11::Json& json);
    NSObject *json11ToNSObject(const json11::Json& json);

namespace web {
    class QliqWebError;

    NSError *qliqWebErrorToNSError(const qx::web::QliqWebError& qwe, const char *domain);
} // web

} // qx

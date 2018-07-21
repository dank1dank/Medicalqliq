//
//  QxPlatfromIOSHelpers.m
//  qliq
//
//  Created by Adam Sowa on 24/01/17.
//
//

#import "QxPlatfromIOSHelpers.h"
#include "qxlib/web/QxWebClient.hpp"

namespace qx {
    
    NSString *toNSString(const std::string& cpp)
    {
        if (cpp.empty()) {
            return [NSString new];
        } else {
            return [NSString stringWithUTF8String:cpp.c_str()];
        }
    }
    
    std::string toStdString(NSString *nss)
    {
        return (nss ? std::string([nss UTF8String], [nss length]) : "");
    }

    std::string toStdStringAsciiOnly(NSString *nss)
    {
        if (nss == nil) {
            return "";
        } else {
            NSData *data = [nss dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
            nss = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
            return (nss ? std::string([nss UTF8String], [nss length]) : "");
        }
    }

    NSMutableDictionary *toNSDictionary(const json11::Json& json)
    {
        NSMutableDictionary *dict = [NSMutableDictionary new];
        for (const auto& kv: json.object_items()) {
            NSString *key = toNSString(kv.first);
            NSObject *value = json11ToNSObject(kv.second);
            [dict setObject:value forKey:key];
        }
        return dict;
    }
    
    NSObject *json11ToNSObject(const json11::Json& json)
    {
        switch (json.type()) {
            case json11::Json::BOOL:
                return [NSNumber numberWithBool:json.bool_value()];
                
            case json11::Json::NUMBER:
                // TODO: JSON does not distinguish between double and int
                // however since in our app we basically only use int, so I use int here
                return [NSNumber numberWithInt:json.int_value()];
                
            case json11::Json::STRING:
                return toNSString(json.string_value());
                
            case json11::Json::ARRAY:
            {
                NSMutableArray *array = [NSMutableArray new];
                for (const auto& e: json.array_items()) {
                    [array addObject:json11ToNSObject(e)];
                }
                return array;
            }
                
            case json11::Json::OBJECT:
            {
                return toNSDictionary(json);
            }
                
            case json11::Json::NUL:
            default:
                return [NSNull null];
        }
    }
    
    namespace web {
        NSError *qliqWebErrorToNSError(const qx::web::QliqWebError& qwe, const char *domain)
        {
            return [[NSError alloc] initWithDomain: [NSString stringWithUTF8String:domain]
                                              code: (qwe.code != 0 ? qwe.code : qwe.networkErrorOrHttpStatus)
                                          userInfo: @{NSLocalizedDescriptionKey: toNSString(qwe.toString())}];
        }
    } // web
    
} // qx

//
//  Multiparty.m
//  qliq
//
//  Created by Adam Sowa on 28/06/16.
//
//

#import "Multiparty.h"
#include "qxlib/model/chat/QxMultiparty.hpp"
#include "qxlib/dao/chat/QxMultipartyDao.hpp"

namespace {
    
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
        return std::string([nss UTF8String], [nss length]);
    }
    
} // namespace

@interface Multiparty() {
    qx::Multiparty cppMultiparty;
}

@end

@implementation Multiparty

- (id) initWithCpp:(const qx::Multiparty&) cpp
{
    self = [super init];
    if (self) {
        cppMultiparty = cpp;
    }
    return self;
}

- (NSString *) qliqId
{
    return toNSString(cppMultiparty.qliqId);
}

- (NSArray *) participantQliqIds
{
    NSMutableArray *ret = [NSMutableArray new];
    for (const auto& p: cppMultiparty.participants) {
        [ret addObject:toNSString(p.qliqId)];
    }
    return ret;
}

- (BOOL) containsParticipant:(NSString *)qliqId
{
    return cppMultiparty.contains(toStdString(qliqId));
}

- (NSString *) roleForQliqId:(NSString *)qliqIdArg
{
    std::string qliqId = toStdString(qliqIdArg);
    for (const auto& p: cppMultiparty.participants) {
        if (p.qliqId == qliqId) {
            return toNSString(p.role);
        }
    }
    return nil;
}

+ (Multiparty *) parseJson:(NSString *)json
{
    qx::Multiparty cpp = qx::Multiparty::parseJson(toStdString(json));
    if (cpp.isEmpty()) {
        return nil;
    } else {
        Multiparty *objc = [[Multiparty alloc] initWithCpp:cpp];
        return objc;
    }
}

+ (BOOL) insertOrUpdate:(Multiparty *)mp
{
    return qx::MultipartyDao::insertOrUpdate(mp->cppMultiparty);
}

@end

@implementation MultipartyDao

+ (BOOL) existsWithQliqId:(NSString *)qliqId
{
    return qx::MultipartyDao::exists(qx::MultipartyDao::QliqIdColumn, toStdString(qliqId));
}

+ (Multiparty *) selectOneWithQliqId:(NSString *)qliqId
{
    qx::Multiparty cpp = qx::MultipartyDao::selectOneBy(qx::MultipartyDao::QliqIdColumn, toStdString(qliqId));
    if (cpp.isEmpty()) {
        return nil;
    } else {
        Multiparty *objc = [[Multiparty alloc] initWithCpp:cpp];
        return objc;
    }
}

+ (BOOL) insertOrUpdate:(Multiparty *)mp
{
    return [Multiparty insertOrUpdate:mp];
}

@end

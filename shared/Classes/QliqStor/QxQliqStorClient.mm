//
//  QxQliqStorClient.m
//  qliq
//
//  Created by Adam Sowa on 02/06/17.
//
//

#import "QxQliqStorClient.h"
#import "qxlib/platform/ios/QxPlatfromIOSHelpers.h"
#include "qxlib/controller/qliqstor/QxQliqStorClient.hpp"

using qx::toStdString;
using qx::toNSString;

@interface QliqStorPerGroup() {
    qx::QliqStorClient::QliqStorPerGroup cpp;
}

@end

@implementation QliqStorPerGroup

- (id) initWithCpp:(const qx::QliqStorClient::QliqStorPerGroup&) cppObject
{
    self = [super init];
    if (self) {
        cpp = cppObject;
    }
    return self;
}

- (id) initWithCpp2:(void *)cppObject
{
    return [self initWithCpp:*reinterpret_cast<qx::QliqStorClient::QliqStorPerGroup *>(cppObject)];
}

- (void *) cppValue
{
    return &cpp;
}

- (NSString *) qliqStorQliqId
{
    return toNSString(cpp.qliqStorQliqId);
}

- (NSString *) groupQliqId
{
    return toNSString(cpp.groupQliqId);
}

- (NSString *) groupName
{
    return toNSString(cpp.groupName);
}

- (BOOL) isEmpty
{
    return cpp.isEmpty();
}

- (NSString *) displayName
{
    return qx::toNSString(cpp.displayName());
}

@end

@implementation QxQliqStorClient

+ (QliqStorPerGroup *) defaultQliqStor
{
    qx::QliqStorClient::QliqStorPerGroup qg = qx::QliqStorClient::defaultQliqStor();
    if (!qg.isEmpty()) {
        return [[QliqStorPerGroup alloc] initWithCpp:qg];
    } else {
        return nil;
    }
}

+ (void) setDefaultQliqStor:(NSString *)qliqStorQliqId groupQliqId:(NSString *)groupQliqId
{
    qx::QliqStorClient::QliqStorPerGroup qg;
    qg.qliqStorQliqId = toStdString(qliqStorQliqId);
    qg.groupQliqId = toStdString(groupQliqId);
    qx::QliqStorClient::setDefaultQliqStor(qg);
}

+ (BOOL) shouldShowQliqStorSelectionDialog
{
    return qx::QliqStorClient::shouldShowQliqStorSelectionDialog();
}

+ (NSArray *) qliqStors
{
    auto cppVec = qx::QliqStorClient::qliqStors();
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:cppVec.size()];
    for (const auto& cpp: cppVec) {
        QliqStorPerGroup *obj = [[QliqStorPerGroup alloc] initWithCpp:cpp];
        [array addObject:obj];
    }
    return array;
}

@end

 //
//  FaxContact.m
//  qliq
//
//  Created by Adam Sowa.
//
//

#import "FaxContact.h"
#import "qxlib/platform/ios/QxPlatfromIOSHelpers.h"
#include "qxlib/model/fax/QxFaxContact.hpp"

using qx::toStdString;
using qx::toNSString;

@interface FaxContact() {
    qx::FaxContact cpp;
}

@end

@implementation FaxContact

- (id) initWithCpp:(const qx::FaxContact&) cppObject
{
    self = [super init];
    if (self) {
        cpp = cppObject;
    }
    return self;
}

- (id) initWithCpp2:(void *)cppObject
{
    return [self initWithCpp:*reinterpret_cast<qx::FaxContact *>(cppObject)];
}

- (void *) cppValue
{
    return &cpp;
}

- (int) databaseId
{
    return (cpp.databaseId);
}

- (NSString *) uuid
{
    return toNSString(cpp.uuid);
}

- (NSString *) faxNumber
{
    return toNSString(cpp.faxNumber);
}

- (void) setFaxNumber: (NSString *)value
{
    cpp.faxNumber = toStdString(value);
}

- (NSString *) voiceNumber
{
    return toNSString(cpp.voiceNumber);
}

- (void) setVoiceNumber: (NSString *)value
{
    cpp.voiceNumber = toStdString(value);
}

- (NSString *) organization
{
    return toNSString(cpp.organization);
}

- (void) setOrganization: (NSString *)value
{
    cpp.organization = toStdString(value);
}

- (NSString *) contactName
{
    return toNSString(cpp.contactName);
}

- (void) setContactName: (NSString *)value
{
    cpp.contactName = toStdString(value);
}

- (BOOL) isCreatedByUser
{
    return (cpp.isCreatedByUser);
}

- (void) setIsCreatedByUser: (BOOL)value
{
    cpp.isCreatedByUser = value;
}

- (NSString *) groupQliqId
{
    return toNSString(cpp.groupQliqId);
}

- (NSString *) toMultiLineString
{
    return toNSString(cpp.toMultiLineString());
}

@end

//
//  ContactAddressbookValue.m
//  qliq
//
//  Created by Aleksey Garbarev on 29.07.13.
//
//

#import "AddressbookMappingValue.h"

@implementation AddressbookMappingValue

BOOL IsStringType(CFStringRef stringRef);

+ (id) newWithPropertyID:(ABPropertyID)property
{
    AddressbookMappingValue *newObject = [AddressbookMappingValue new];
    newObject.propertyId = property;
    return newObject;
}

+ (id) newWithPropertyID:(ABPropertyID)property andLabel:(CFStringRef)label
{
    AddressbookMappingValue *newObject = [self newWithPropertyID:property];
    if (label != NULL) {
        newObject.multivalueTestBlock = ^(CFStringRef currentLabel){
            if (IsStringType(currentLabel)) {
                return (BOOL)(CFStringCompare(currentLabel, label, 0) == kCFCompareEqualTo);
            } else {
                return NO;
            }
        };
    }
    return newObject;
}

+ (id) newWithPropertyID:(ABPropertyID)property andNotLabel:(CFStringRef)label
{
    AddressbookMappingValue *newObject = [self newWithPropertyID:property];
    if (label != NULL) {
        newObject.multivalueTestBlock = ^(CFStringRef currentLabel){
            if (IsStringType(currentLabel)) {
                return (BOOL)(CFStringCompare(currentLabel, label, 0) != kCFCompareEqualTo);
            } else {
                return NO;
            }
        };
    }
    return newObject;
}

BOOL IsStringType(CFStringRef stringRef)
{
    return (stringRef != NULL && CFGetTypeID(stringRef) == CFStringGetTypeID());
}



@end

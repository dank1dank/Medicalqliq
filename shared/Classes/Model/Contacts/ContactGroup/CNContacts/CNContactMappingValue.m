//
//  CNContactMappingValue.m
//  qliq
//
//  Created by Valerii Lider on 8/16/16.
//
//

#import "CNContactMappingValue.h"

@implementation CNContactMappingValue

BOOL isStringType(id label);


+ (id) newWithKey:(NSString *)key
{
    CNContactMappingValue *newObject = [CNContactMappingValue new];
    newObject.key = key;
    return newObject;

}
+ (id) newWithKey:(NSString *)key andLabelType:(NSString *)labelType
{
    CNContactMappingValue *newObject = [self newWithKey:key];
    if (labelType) {
        newObject.multivalueTestBlock = ^(id testLabelType){
            if (isStringType(testLabelType)) {
                return [labelType isEqualToString:testLabelType];
            } else {
                return NO;
            }
        };
    }
    return newObject;
}

+ (id) newWithKey:(NSString *)key andNotLabelType:(NSString *)labelType
{
    CNContactMappingValue *newObject = [self newWithKey:key];
    if (labelType) {
        newObject.multivalueTestBlock = ^(id testLabelType){
            if (isStringType(testLabelType)) {
                BOOL isNotEqual = ![labelType isEqualToString:testLabelType];
                return isNotEqual;
            }
            else
            {
                return NO;
            }
        };
    }
    return newObject;
}

BOOL isStringType(id label)
{
    return [label isKindOfClass:[NSString class]];
}

@end

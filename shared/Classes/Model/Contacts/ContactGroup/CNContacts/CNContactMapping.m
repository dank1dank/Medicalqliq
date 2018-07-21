//
//  CNContactMapping.m
//  qliq
//
//  Created by Valerii Lider on 8/16/16.
//
//

#import "CNContactMapping.h"

@implementation CNContactMapping{
    NSDictionary *mappingDictionary;
}

- (id) initWithMappingDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (self) {
        mappingDictionary = dictionary;
    }
    return self;
}

- (void) mapObject:(NSObject *)object fromCNContact:(CNContact *)cnContact
{
    for (NSString *key in [mappingDictionary allKeys]) {
        
        CNContactMappingValue *cnContactMappingValue = [mappingDictionary valueForKey:key];
        
        NSObject *labeledValue = [cnContact valueForKey:cnContactMappingValue.key];
        
        if (labeledValue) {
            NSObject *value = [self valueFromCNContactMappingValue:cnContactMappingValue andLabeledValue:labeledValue];
            [object setValue:value forKey:key];
        }
    }
}


- (NSObject *) valueFromCNContactMappingValue:(CNContactMappingValue *)cnContactMappingValue andLabeledValue:(NSObject *)labeledValue
{
    NSObject *value = nil;
    if ([self isSingleStringValue:labeledValue]) {
        if ([labeledValue isKindOfClass:[CNLabeledValue class]]) {
          value = ((CNLabeledValue *)labeledValue).value;
        } else {
            value = labeledValue;
        }
    }
    else {
        value = [self valueWithTestBlock:cnContactMappingValue.multivalueTestBlock fromMultiValue:labeledValue];
    }
    return value;
}

- (BOOL) isSingleStringValue:(NSObject *)value
{
    return ![value isKindOfClass:[NSArray class]]/* && ![value isKindOfClass:[NSDictionary class]] && ![value isKindOfClass:[NSSet class]]*/;
}

- (NSObject *) valueWithTestBlock:(CNContactMappingValueTestBlock)testBlock fromMultiValue:(NSObject *)multiValue
{
    NSObject *resultValue = nil;
    if ([multiValue isKindOfClass:[NSArray class]]) {
        NSArray *multiValueArray = (NSArray *)multiValue;
        
        NSInteger targetIndex = NSNotFound;
        NSUInteger count = multiValueArray.count;
        
        for (int i = 0; i < count; i++)
        {
            NSObject *undefinedValue = [multiValueArray objectAtIndex:i];

            if (undefinedValue && testBlock)
            {
                if ([undefinedValue isKindOfClass:[CNLabeledValue class]]) {
                   
                    BOOL isTargetLabel = testBlock(((CNLabeledValue *)undefinedValue).label);
                    if (isTargetLabel) {
                        targetIndex = i;
                        break;
                    }
                }
            }
        }
        
        if (targetIndex >= 0 && targetIndex < count) {
            resultValue = ((CNLabeledValue *)[multiValueArray objectAtIndex:targetIndex]).value;
        } else {
            resultValue = ((CNLabeledValue *)multiValueArray.firstObject).value;
        }
        
        if ([resultValue isKindOfClass:[CNPhoneNumber class]]) {
            resultValue = ((CNPhoneNumber *)resultValue).stringValue;
        }
    }
    
    return resultValue;
}

@end

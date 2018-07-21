//
//  CNContactMapping.h
//  qliq
//
//  Created by Valerii Lider on 8/16/16.
//
//

#import <Foundation/Foundation.h>
#import <Contacts/Contacts.h>

#import "CNContactMappingValue.h"

@interface CNContactMapping : NSObject

/* Mapping dictionary with format - { "object property name" : "CNContactMappingValue" } */
- (id) initWithMappingDictionary:(NSDictionary *)mappingDictionary;

/* Fills object's properties from CNContact using mappingDictionary */
- (void) mapObject:(NSObject *)object fromCNContact:(CNContact *)cnContact;

@end


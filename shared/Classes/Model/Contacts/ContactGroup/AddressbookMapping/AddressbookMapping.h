//
//  AddressbookMapping.h
//  qliq
//
//  Created by Aleksey Garbarev on 30.07.13.
//
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>

#import "AddressbookMappingValue.h"

@interface AddressbookMapping : NSObject

/* Mapping dictionary with format - { "object property name" : "AddressbookMappingValue" } */
- (id) initWithMappingDictionary:(NSDictionary *)mappingDictionary;

/* Fills object's properties from ABRecordRef using mappingDictionary */
- (void) mapObject:(NSObject *)object fromABRecordRef:(ABRecordRef)abRecordRef;

@end

//
//  ContactAddressbookValue.h
//  qliq
//
//  Created by Aleksey Garbarev on 29.07.13.
//
//

#import <Foundation/Foundation.h>
#import <AddressBook/ABAddressBook.h>

typedef BOOL(^AddressbookMappingValueTestBlock)(CFStringRef label);

@interface AddressbookMappingValue : NSObject

@property (nonatomic) ABPropertyID propertyId;
@property (nonatomic, strong) AddressbookMappingValueTestBlock multivalueTestBlock;

+ (id) newWithPropertyID:(ABPropertyID)property;
+ (id) newWithPropertyID:(ABPropertyID)property andLabel:(CFStringRef)label;
+ (id) newWithPropertyID:(ABPropertyID)property andNotLabel:(CFStringRef)label;


@end

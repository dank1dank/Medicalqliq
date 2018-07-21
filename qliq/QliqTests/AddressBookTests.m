//
//  AddressBookTests.m
//  qliq
//
//  Created by Aleksey Garbarev on 06.08.13.
//
//

#import "AddressBookTests.h"
#import "AddressbookMappingValue.h"

@implementation AddressBookTests

- (void) testAddressbookMappingValue
{
    AddressbookMappingValue *value = [AddressbookMappingValue newWithPropertyID:0 andLabel:(CFStringRef)@"Label"];
    
    STAssertEquals(value.multivalueTestBlock((CFStringRef)@"Label2"), NO, @"");
    STAssertEquals(value.multivalueTestBlock((CFStringRef)@"Label"), YES, @"");
    STAssertEquals(value.multivalueTestBlock(NULL), NO, @"");
    NSInteger number = 123;
    CFNumberRef numberRef = CFNumberCreate(NULL, kCFNumberNSIntegerType, &number);
    STAssertEquals(value.multivalueTestBlock((CFStringRef)numberRef), NO, @"");
}

@end

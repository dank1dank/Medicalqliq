//
//  UIDevice+UUID.m
//  qliq
//
//  Created by Aleksey Garbarev on 24.09.13.
//
//

#import "UIDevice+UUID.h"
#import "Lockbox.h"

static NSString *kDeviceUUIDKey = @"DeviceUUID";

@implementation UIDevice (UIDevice_UUID)

- (NSString *) uuidStored
{
    NSString *result = nil;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    result = [defaults valueForKey:@"qliqUUID"];
    
    if (result) {
        return result;
    }
    
    if ([self isAvailableInKeychain]) {
        result = [self readFromKeychain];
        [defaults setValue:result forKey:@"qliqUUID"];
    } else {
        result = [self generateUuid];
        [self writeToKeychain:result];
        [defaults setValue:result forKey:@"qliqUUID"];
    }
    
    return result;
}

- (NSString *) qliqUUID
{
    return [self uuidStored];
}

- (BOOL) isAvailableInKeychain
{
    BOOL isAvailable = YES;
    NSString *result = [self readFromKeychain];
    
    if (result == nil || [result isEqualToString:@"1234567890"] || [result hasPrefix:@"FFFFFFFF"])
        isAvailable = NO;
        
    return isAvailable;
}

- (NSString *) readFromKeychain
{
    return [Lockbox stringForKey:kDeviceUUIDKey];
}

- (void) writeToKeychain:(NSString *)uuid
{
    [Lockbox setString:uuid forKey:kDeviceUUIDKey];
}

- (NSString *) generateUuid
{
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    NSString *UUID = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, uuid);
    CFRelease(uuid);
    
    return UUID;
}

@end

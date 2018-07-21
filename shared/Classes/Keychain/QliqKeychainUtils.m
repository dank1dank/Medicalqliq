//
//  QliqKeychainUtils.m
//  CCiPhoneApp
//
//  Created by Ravi Ada on 8/17/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import "QliqKeychainUtils.h"
#import <Security/Security.h>
#import "Constants.h"

static NSString *QliqKeychainUtilsErrorDomain = @"QliqKeychainUtilsErrorDomain";

@implementation QliqKeychainUtils

+ (NSString *)getItemForKey:(NSString *)key error:(NSError **)errorOut
{
    return [self getItemForKey:key error:errorOut andLogError:YES];
}

+ (NSString *)getItemForKey:(NSString *)key error:(NSError **)errorOut andLogError:(BOOL)logError
{
	NSString *serviceName = @"qliq";
    NSError *error = nil;
    NSString *value = nil;
    
	if (!key || !serviceName)
    {
        error = [NSError errorWithDomain:QliqKeychainUtilsErrorDomain code: -2000 userInfo:nil];
	}
    else
    {
        // Set up a query dictionary with the base query attributes: item type (generic), key, and service
        
        NSArray *keys = [[[NSArray alloc] initWithObjects: (NSString *) kSecClass, kSecAttrAccount, kSecAttrService, nil] autorelease];
        NSArray *objects = [[[NSArray alloc] initWithObjects: (NSString *) kSecClassGenericPassword, key, serviceName, nil] autorelease];
        
        NSMutableDictionary *query = [[[NSMutableDictionary alloc] initWithObjects:objects forKeys:keys] autorelease];
        
        // First do a query for attributes, in case we already have a Keychain item with no value data set.
        
        NSDictionary *attributeResult = NULL;
        NSMutableDictionary *attributeQuery = [query mutableCopy];
        [attributeQuery setObject:(id) kCFBooleanTrue forKey:(id) kSecReturnAttributes];
        OSStatus status = SecItemCopyMatching((CFDictionaryRef) attributeQuery, (CFTypeRef *) &attributeResult);
        
        [attributeResult release];
        [attributeQuery release];
        
        if (status != noErr)
        {
            // No existing item found--simply return nil for the value
            if (status != errSecItemNotFound)
            {
                //Only return an error if a real exception happened--not simply for "not found."
                error = [NSError errorWithDomain: QliqKeychainUtilsErrorDomain code: status userInfo: nil];
            }
            else if (logError)
            {
                DDLogSupport(@"Value doesn't exist for key: '%@'", key);
            }
            
            // Will return nil
        }
        else
        {
            // We have an existing item, now query for the value data associated with it.
            
            NSData *resultData = nil;
            NSMutableDictionary *valueQuery = [query mutableCopy];
            [valueQuery setObject: (id) kCFBooleanTrue forKey: (id) kSecReturnData];
            
            status = SecItemCopyMatching((CFDictionaryRef) valueQuery, (CFTypeRef *) &resultData);
            
            [resultData autorelease];
            [valueQuery release];
            
            if (status != noErr) {
                if (status == errSecItemNotFound) {
                    // We found attributes for the item previously, but no value now, so return a special error.
                    // Users of this API will probably want to detect this error and prompt the user to
                    // re-enter their credentials.  When you attempt to store the re-entered credentials
                    // using storeItemForKey:andPassword:forServiceName:updateExisting:error
                    // the old, incorrect entry will be deleted and a new one with a properly encrypted
                    // value will be added.
                    error = [NSError errorWithDomain: QliqKeychainUtilsErrorDomain code: -1999 userInfo: nil];
                }
                else {
                    // Something else went wrong. Simply return the normal Keychain API error code.
                    error = [NSError errorWithDomain: QliqKeychainUtilsErrorDomain code: status userInfo: nil];
                }
                
                // Will return nil
            }
            else
            {
                if (resultData) {
                    value = [[[NSString alloc] initWithData: resultData encoding: NSUTF8StringEncoding] autorelease];
                }
                else {
                    // There is an existing item, but we weren't able to get value data for it for some reason,
                    // Possibly as a result of an item being incorrectly entered by the previous code.
                    // Set the -1999 error so the code above us can prompt the user again.
                    error = [NSError errorWithDomain: QliqKeychainUtilsErrorDomain code: -1999 userInfo: nil];
                }
            }
        }
    }
    
    if (errorOut)
        *errorOut = error;
    
    if (logError && error != nil && ([error code] != noErr)) {
        DDLogError(@"Cannot get value for key '%@', error: %ld, %@", key, (long)[error code], [error description]);
//        DDLogError(@"getItemForKey called from:\n%@",[NSThread callStackSymbols]);
    }
	
	return value;
}

+ (BOOL) storeItemForKey:(NSString *)key andValue:(NSString *)val error:(NSError **)errorOut
{
    return [self storeItemForKey:key andValue:val error:errorOut withAttrAccessible:kSecAttrAccessibleAlways];
}

+ (BOOL)storeItemForKey:(NSString *)key andValue:(NSString *)val error:(NSError **)errorOut withAttrAccessible:(CFTypeRef)secAttrAccessible
{		
	NSString *serviceName = @"qliq";
    NSError *error = nil;
    
	if (!key || !val || !serviceName) 
	{
        error = [NSError errorWithDomain: QliqKeychainUtilsErrorDomain code: -2000 userInfo: nil];
	}
    else
    {
        // See if we already have a value entered for these credentials.
        NSString *existingValue = [QliqKeychainUtils getItemForKey: key error:&error andLogError:NO];
        
        if ([error code] == noErr) 
        {
            OSStatus status = noErr;
            if (existingValue)
            {
                // We have an existing, properly entered item with a value.
                // Update the existing item.
                
                if (![existingValue isEqualToString:val]) 
                {
                    //Only update if we're allowed to update existing.  If not, simply do nothing.
                    
//                    NSArray *keys = [[[NSArray alloc] initWithObjects: (NSString *) kSecClass, 
//                                      kSecAttrService, 
//                                      kSecAttrLabel, 
//                                      kSecAttrAccount,
//                                      kSecAttrAccessible,
//                                      nil] autorelease];
//                    
//                    NSArray *objects = [[[NSArray alloc] initWithObjects: (NSString *) kSecClassGenericPassword, 
//                                         serviceName,
//                                         serviceName,
//                                         key,
//                                         secAttrAccessible,
//                                         nil] autorelease];

                    NSArray *keys = [[[NSArray alloc] initWithObjects: (NSString *) kSecClass, kSecAttrAccount, kSecAttrService, nil] autorelease];
                    NSArray *objects = [[[NSArray alloc] initWithObjects: (NSString *) kSecClassGenericPassword, key, serviceName, nil] autorelease];
                    
                    NSDictionary *query = [[[NSDictionary alloc] initWithObjects: objects forKeys: keys] autorelease];

                //Should update keychain with specific kSecAttrAccessible attribute on the keychain items it manages (which the original code did not do - presumably as it pre-dated these attributes)
                //Valerii Lider, 11/10/17
//                    status = SecItemDelete((CFDictionaryRef)query);
//                    DDLogSupport(@"Deleted old keychain value for key: '%@' with status: %d", key, (int)status);
//                    existingValue = nil;
                    
                    DDLogSupport(@"Updating a new keychain entry");
                    NSDictionary *attributesToUpdate = @{(NSString *)kSecValueData      : [val dataUsingEncoding: NSUTF8StringEncoding],
                                                     (NSString *)kSecAttrAccessible : (NSString *)kSecAttrAccessibleAfterFirstUnlock};
                    status = SecItemUpdate((CFDictionaryRef) query, (CFDictionaryRef) attributesToUpdate);

//                    status = SecItemUpdate((CFDictionaryRef) query, (CFDictionaryRef) [NSDictionary dictionaryWithObject: [val dataUsingEncoding: NSUTF8StringEncoding] forKey: (NSString *) kSecValueData]);
                }
                else
                {
                    DDLogSupport(@"Cannot update item for key %@ because it already has the specified value %@", key, val);
                    return TRUE;
                }
            }
            
            if (existingValue == nil)
            {
                // No existing entry (or an existing, improperly entered, and therefore now
                // deleted, entry).  Create a new entry.
                
                NSArray *keys = [[[NSArray alloc] initWithObjects: (NSString *) kSecClass, 
                                  kSecAttrService, 
                                  kSecAttrLabel, 
                                  kSecAttrAccount,
                                  kSecAttrAccessible,
                                  kSecValueData, 
                                  nil] autorelease];
                
                NSArray *objects = [[[NSArray alloc] initWithObjects: (NSString *) kSecClassGenericPassword, 
                                     serviceName,
                                     serviceName,
                                     key,
                                     /*secAttrAccessible,*/
                                     kSecAttrAccessibleAfterFirstUnlock,
                                     [val dataUsingEncoding: NSUTF8StringEncoding],
                                     nil] autorelease];
                
                NSDictionary *query = [[[NSDictionary alloc] initWithObjects: objects forKeys: keys] autorelease];			
                
                DDLogSupport(@"Adding a new keychain entry");
                status = SecItemAdd((CFDictionaryRef) query, NULL);
            }
            
            if (status != noErr) 
            {
                // Something went wrong with adding the new item. Return the Keychain error code.
                error = [NSError errorWithDomain: QliqKeychainUtilsErrorDomain code: status userInfo: nil];
            }
        }
        else
        {
            DDLogError(@"Don't storing keychain value because cannot determine if previous exists for key: %@", key);
        }
    }
	
    if (errorOut)
        *errorOut = error;
    
    if (error != nil && ([error code] != noErr)) {
        DDLogError(@"Cannot set value '%@' for key '%@', error: %ld, %@", val, key, (long)[error code], [error localizedDescription]);
    }
    return (error == nil);
}

+ (BOOL)deleteItemForKey:(NSString *)key error:(NSError **)error
{
	NSString *serviceName = @"qliq";
	
	if (!key || !serviceName) 
	{
		if (error != nil) 
		{
			*error = [NSError errorWithDomain: QliqKeychainUtilsErrorDomain code: -2000 userInfo: nil];
		}
		return NO;
	}
	
	if (error != nil) 
	{
		*error = nil;
	}
	
	NSArray *keys = [[[NSArray alloc] initWithObjects: (NSString *) kSecClass, kSecAttrAccount, kSecAttrService, kSecReturnAttributes, nil] autorelease];
	NSArray *objects = [[[NSArray alloc] initWithObjects: (NSString *) kSecClassGenericPassword, key, serviceName, kCFBooleanTrue, nil] autorelease];
	
	NSDictionary *query = [[[NSDictionary alloc] initWithObjects: objects forKeys: keys] autorelease];
	
	OSStatus status = SecItemDelete((CFDictionaryRef) query);
	
	if (error != nil && status != noErr) 
	{
		*error = [NSError errorWithDomain: QliqKeychainUtilsErrorDomain code: status userInfo: nil];
        DDLogError(@"Cannot delete key '%@', error: %ld, %@", key, (long)[*error code], [*error localizedDescription]);
		return NO;
	}
	
	return YES;
}

+ (void)rewriteAllKeysWithNewSecAttributes
{
    NSMutableDictionary *query = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                  (id)kCFBooleanTrue, (id)kSecReturnAttributes,
                                  (id)kSecMatchLimitAll, (id)kSecMatchLimit,
                                  nil];
    [query setObject:(id)kSecClassGenericPassword forKey:(id)kSecClass];
    
    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((CFDictionaryRef)query, &result);
    if (status == errSecSuccess && result != nil) {
        DDLogSupport(@"Rewriting keychain keys with new security attribute");
        NSError *error = nil;
        NSArray *array = (NSArray *)result;
        for (NSDictionary *dict in array) {
            NSString *key = [dict objectForKey:@"acct"];
            NSString *value = [self getItemForKey:key error:&error];
            [self deleteItemForKey:key error:&error];
            //NSLog(@"key: %@, value: %@", key, value);
            [self storeItemForKey:key andValue:value error:&error];
        }
        CFRelease(result);
    }
}


@end

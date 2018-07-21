//
//  QliqKeychainUtils.h
//  CCiPhoneApp
//
//  Created by Ravi Ada on 8/17/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//


#define KS_KEY_USERNAME             @"key_username"
#define KS_KEY_PASSWORD             @"key_password"
#define KS_KEY_API_KEY              @"key_api_key"
#define KS_KEY_FILE_SERVER_URL      @"key_file_server_url"
#define KS_KEY_PIN                  @"key_pin"
#define KS_KEY_ARCHIVED_PINS        @"key_archived_pins"
#define KS_KEY_PIN_LAST_SET_TIME    @"key_pin_last_set_time"
#define KS_KEY_PRIVATE_KEY          @"key_private_key"
#define KS_KEY_PUBLIC_KEY           @"key_public_key"
#define KS_KEY_LOCKED               @"key_locked"
#define KS_KEY_WIPED                @"key_wiped"
#define KS_KEY_WHEN_UNLOCKED_ITEM   @"key_when_unlocked_item"
#define KS_KEY_DEVICE_LOCK_ENABLED  @"key_device_lock_enabled"

#define KS_DBKEY_PREFIX @"dbkeyfor_"

@interface QliqKeychainUtils : NSObject

+ (NSString *)getItemForKey:(NSString *)key error:(NSError **)error;
+ (NSString *)getItemForKey:(NSString *)key error:(NSError **)errorOut andLogError:(BOOL)logError;

+ (BOOL)storeItemForKey:(NSString *)key andValue:(NSString *)val error:(NSError **)error;
+ (BOOL)storeItemForKey:(NSString *)key andValue:(NSString *)val error:(NSError **)errorOut withAttrAccessible:(CFTypeRef)secAttrAccessible;

+ (BOOL)deleteItemForKey:(NSString *)key error:(NSError **)error;
+ (void)rewriteAllKeysWithNewSecAttributes;

@end

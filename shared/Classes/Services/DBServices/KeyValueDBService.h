//
//  ReceivedPushNotificationDBService.h
//  qliq
//
//  Created by Adam on 01/07/15.
//
//

#import <Foundation/Foundation.h>
#import "ReceivedPushNotification.h"

@interface KeyValueDBService : NSObject

+ (BOOL) insert:(NSString *)key withValue:(NSString *)value;
+ (BOOL) update:(NSString *)key withValue:(NSString *)value;
+ (BOOL) insertOrUpdate:(NSString *)key withValue:(NSString *)value;
+ (BOOL) remove:(NSString *)key;
+ (NSString *) select:(NSString *)key;
+ (BOOL) exists:(NSString *)key;

@end

//
//  QliqReachability.h
//  qliq
//
//  Created by Aleksey Garbarev on 10/5/12.
//
//

#import <Foundation/Foundation.h>

extern NSString * QliqReachabilityChangedNotification;

@interface QliqReachability : NSObject

- (void) startListening;
- (void) stopListening;

- (void) startNotifications;
- (void) stopNotifications;

- (NSString *) restReachabilityString;

- (BOOL) restReachable;
- (BOOL) sipReachable;

- (BOOL) isReachable;

- (BOOL) wasRegistered;

- (BOOL) hasIPAddressChanged:(BOOL)update;

+ (QliqReachability *) sharedInstance;
+ (void) setSharedInstance:(QliqReachability *)instance;

@end

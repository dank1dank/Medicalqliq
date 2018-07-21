//
//  QliqNetwork.h
//  qliq
//
//  Created by Aleksey Garbarev on 10/5/12.
//
//

#import <Foundation/Foundation.h>

#import "QliqReachability.h"
#import "QliqProgressHandlers.h"
#import "QliqPresences.h"

/**
 I'll use this class to get all instances which works with network in one place
 and get rid of singletons for all services.
 */

@interface QliqNetwork : NSObject

@property (nonatomic, readonly, strong) QliqReachability * reachability;
@property (nonatomic, readonly, strong) QliqProgressHandlers * progressHandlers;
@property (nonatomic, readonly, strong) QliqPresences * presences;

- (BOOL) hasIPAddressChanged:(BOOL)update;

+ (QliqNetwork *) sharedInstance;
+ (void) setSharedInstance:(QliqNetwork *)instance;

@end

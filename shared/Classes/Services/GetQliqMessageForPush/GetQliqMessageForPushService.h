//
//  GetQliqMessageForPushService.h
//  qliq
//
//  Created by Adam on 5/3/18.
//

#import <Foundation/Foundation.h>
#import "QliqAPIService.h"

@interface GetQliqMessageForPushService : QliqAPIService

// Method for real world usage
- (id) initWithPushNotification:(NSDictionary *)aps;

// Method for development/testing
- (id) initWithCallId:(NSString *)callId
         serverContext:(NSString *)serverContext
              fromUser:(NSString *)fromUser
     pushNotification:(NSDictionary *)aps;

+ (void) handlePushNotification:(NSDictionary *)aps;

@end

//
//  ReceivedPushNotification.h
//  qliq
//
//  Created by Adam on 01/07/15.
//
//

#import <Foundation/Foundation.h>

@interface ReceivedPushNotification : NSObject

@property (nonatomic, strong) NSString *callId;
@property (nonatomic, readwrite) NSTimeInterval receivedAt;
@property (nonatomic, readwrite) bool isSentToServer;

@end

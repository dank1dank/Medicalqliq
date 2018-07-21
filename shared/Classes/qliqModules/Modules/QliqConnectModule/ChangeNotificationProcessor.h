//
//  ChangeNotificationProcessor.h
//  qliq
//
//  Created by Adam Sowa on 11/15/17.
//

#import <Foundation/Foundation.h>

@class QliqSipMessage;

@interface ChangeNotificationProcessor : NSObject

- (BOOL) handleSipMessage:(QliqSipMessage *)message;
- (BOOL) onChangeNotificationReceived:(int) databaseId subject:(NSString *)subject qliqId:(NSString *)qliqId data:(NSString *)data;

@end

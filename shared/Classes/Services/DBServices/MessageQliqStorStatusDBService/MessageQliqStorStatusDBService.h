//
//  MessageQliqStorStatusDBService.h
//  qliq
//
//  Created by Adam on 10/19/12.
//
//

#import <Foundation/Foundation.h>

enum QliqStorMessagePushStatus {
    ErrorQliqStorMessagePushStatus = -1,
    NotPushedQliqStorMessagePushStatus = 0,
    PushedQliqStorMessagePushStatus = 1
};

@interface MessageQliqStorStatusDBService : NSObject

+ (BOOL) hasRowsForMessageId:(NSInteger)messageId;
+ (BOOL) insertRowsForMessageId:(NSInteger)messageId qliqStorIds:(NSSet *)aQliqStorIdsSet;
+ (BOOL) insertOrUpdateRowsForMessageId:(NSInteger)messageId qliqStorIds:(NSSet *)aQliqStorIdsSet status:(NSInteger)aStatus;
+ (BOOL) setStatusForMessageId:(NSInteger)messageId qliqStorId:(NSString *)aQliqStorId status:(NSInteger)aStatus;
+ (BOOL) deleteRowsForMessageId:(NSInteger)messageId;
+ (NSMutableArray *) qliqStorIdsForMessageIdAndStatus:(NSInteger)messageId status:(NSInteger)aStatus;
+ (NSMutableArray *) qliqStorIdsForMessageIdAndStatusNotEqual:(NSInteger)messageId status:(NSInteger)aStatus;
+ (BOOL) deleteForQliqStorId:(NSString *)qliqId;

@end

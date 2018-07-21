//
//  ReceivedPushNotificationDBService.m
//  qliq
//
//  Created by Adam on 01/07/15.
//
//

#import "ReceivedPushNotificationDBService.h"
#import "DBUtil.h"
#import "FMDatabase.h"

@implementation ReceivedPushNotificationDBService

+ (BOOL) insert:(NSString *)callId
{
    __block BOOL ret = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString *sql = @"INSERT INTO received_push_notification(call_id, received_at, sent_to_server) VALUES "
        "(?, ?, 0)";
        ret = [db executeUpdate:sql, callId, [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]]];
    }];
    return ret;
}

+ (BOOL) saveAsSentToServer:(NSString *)callId
{
    __block BOOL ret = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString *sql = @"UPDATE received_push_notification SET sent_to_server = 1 WHERE call_id = ?";
        ret = [db executeUpdate:sql, callId];
    }];
    return ret;
}

+ (BOOL) remove:(NSString *)callId
{
    __block BOOL ret = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString *sql = @"DELETE FROM received_push_notification WHERE call_id = ?";
        ret = [db executeUpdate:sql, callId];
    }];
    return ret;
}

+ (BOOL) deleteOlderThen:(NSTimeInterval)timestamp
{
    __block BOOL ret = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString *sql = @"DELETE FROM received_push_notification WHERE received_at < ?";
        ret = [db executeUpdate:sql, [NSNumber numberWithDouble:timestamp]];
    }];
    return ret;
}

+ (NSArray *) selectNoSentToServer
{
    __block NSMutableArray *ret = [NSMutableArray new];
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString *sql = @"SELECT * FROM received_push_notification WHERE sent_to_server = 0";
        FMResultSet *rs = [db executeQuery:sql];
        while ([rs next]) {
            ReceivedPushNotification *obj = [[ReceivedPushNotification alloc] init];
            obj.callId = [rs stringForColumn:@"call_id"];
            obj.receivedAt = [rs doubleForColumn:@"received_at"];
            obj.isSentToServer = [rs intForColumn:@"sent_to_server"] > 0;
            [ret addObject:obj];
        }
        [rs close];
        
    }];
    return ret;
}

+ (ReceivedPushNotification *) selectWithCallId:(NSString *)callId
{
    __block ReceivedPushNotification *obj = nil;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString *sql = @"SELECT * FROM received_push_notification WHERE call_id = ? LIMIT 1";
        FMResultSet *rs = [db executeQuery:sql, callId];
        if ([rs next]) {
            obj = [[ReceivedPushNotification alloc] init];
            obj.callId = [rs stringForColumn:@"call_id"];
            obj.receivedAt = [rs doubleForColumn:@"received_at"];
            obj.isSentToServer = [rs intForColumn:@"sent_to_server"] > 0;
        }
        [rs close];
        
    }];
    return obj;
}

@end

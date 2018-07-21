//
//  MessageQliqStorStatusDBService.m
//  qliq
//
//  Created by Adam on 10/19/12.
//
//

#import "MessageQliqStorStatusDBService.h"
#import "DBUtil.h"

@interface MessageQliqStorStatusDBService(Private)
@end

@implementation MessageQliqStorStatusDBService

+ (BOOL) hasRowsForMessageId:(NSInteger)messageId
{
    __block BOOL ret = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString *sql = @"SELECT message_id FROM message_qliqstor_status WHERE message_id = ? LIMIT 1";

        FMResultSet *rs = [db executeQuery:sql,[NSNumber numberWithInteger:messageId]];
        if ([rs next])
            ret = YES;
        [rs close];
    }];
    return ret;
}

+ (BOOL) insertRowsForMessageId:(NSInteger)messageId qliqStorIds:(NSSet *)aQliqStorIdsSet
{
    __block BOOL ret = YES;
    [[DBUtil sharedQueue] inTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSString *sql = @"INSERT INTO message_qliqstor_status(message_id, qliqstor_qliq_id, status) VALUES(?, ?, 0)";
        
        for (NSString* qliqId in aQliqStorIdsSet) {
            if (![db executeUpdate:sql, [NSNumber numberWithInteger:messageId], qliqId]) {
                ret = NO;
                break;
            }
        }
        
        if (!ret) {
            *rollback = YES;
        }
    }];
    return ret;
}

+ (BOOL) insertOrUpdateRowsForMessageId:(NSInteger)messageId qliqStorIds:(NSSet *)aQliqStorIdsSet status:
(NSInteger)aStatus
{
    __block BOOL ret = YES;
    [[DBUtil sharedQueue] inTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSString *sql = @"INSERT OR REPLACE INTO message_qliqstor_status(message_id, qliqstor_qliq_id, status) VALUES(?, ?, ?)";
    
        for (NSString* qliqId in aQliqStorIdsSet) {
            if ([qliqId length] > 0) {
                if (![db executeUpdate:sql, [NSNumber numberWithInteger:messageId], qliqId, [NSNumber numberWithInteger:aStatus]]) {
                    ret = NO;
                    break;
                }
            }
        }
        
        if (!ret) {
            *rollback = YES;
        }
    }];
     
    return ret;
}

+ (BOOL) setStatusForMessageId:(NSInteger)messageId qliqStorId:(NSString *)aQliqStorId status:(NSInteger)aStatus
{
    __block BOOL ret = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString *sql = @"UPDATE message_qliqstor_status SET status = ? WHERE message_id = ? AND qliqstor_qliq_id = ?";
        ret = [db executeUpdate:sql, [NSNumber numberWithInteger:aStatus], [NSNumber numberWithInteger:messageId], aQliqStorId];
    }];
    return ret;
}

+ (BOOL) deleteRowsForMessageId:(NSInteger)messageId
{
    __block BOOL ret = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString *sql = @"DELETE FROM message_qliqstor_status WHERE message_id = ?";
        ret = [db executeUpdate:sql, [NSNumber numberWithInteger:messageId]];
    }];
    return ret;
}

+ (NSMutableArray *) qliqStorIdsForMessageIdAndStatus:(NSInteger)messageId status:(NSInteger)aStatus
{
    __block NSMutableArray *ret = [[NSMutableArray alloc] init];
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString *sql = @"SELECT qliqstor_qliq_id FROM message_qliqstor_status WHERE message_id = ? AND status = ?";
        FMResultSet *rs = [db executeQuery:sql,[NSNumber numberWithInteger:messageId], [NSNumber numberWithInteger:aStatus]];
        while ([rs next])
        {
            [ret addObject:[rs stringForColumnIndex:0]];
        }
        [rs close];
    }];
    return ret;
}

+ (NSArray *) qliqStorIdsForMessageIdAndStatusNotEqual:(NSInteger)messageId status:(NSInteger)aStatus
{
    __block NSMutableArray *ret = [[NSMutableArray alloc] init];
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString *sql = @"SELECT qliqstor_qliq_id FROM message_qliqstor_status WHERE message_id = ? AND status != ?";
        FMResultSet *rs = [db executeQuery:sql,[NSNumber numberWithInteger:messageId], [NSNumber numberWithInteger:aStatus]];
        while ([rs next])
        {
            [ret addObject:[rs stringForColumnIndex:0]];
        }
        [rs close];
    }];
    return ret;
}

+ (BOOL) deleteForQliqStorId:(NSString *)qliqId
{
    __block BOOL ret = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString *sql = @"DELETE FROM message_qliqstor_status WHERE qliqstor_qliq_id = ?";
        ret = [db executeUpdate:sql, qliqId];
    }];
    return ret;
}

@end

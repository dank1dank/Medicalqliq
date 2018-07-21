//
//  ReceivedPushNotificationDBService.m
//  qliq
//
//  Created by Adam on 01/07/15.
//
//

#import "KeyValueDBService.h"
#import "DBUtil.h"
#import "FMDatabase.h"

@implementation KeyValueDBService

+ (BOOL) insert:(NSString *)key withValue:(NSString *)value
{
    __block BOOL ret = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString *sql = @"INSERT INTO key_value(key, value) VALUES "
        "(?, ?)";
        ret = [db executeUpdate:sql, key, value];
    }];
    return ret;
}

+ (BOOL) update:(NSString *)key withValue:(NSString *)value
{
    __block BOOL ret = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString *sql = @"UPDATE key_value SET value = ? WHERE key = ?";
        ret = [db executeUpdate:sql, value, key];
    }];
    return ret;
}

+ (BOOL) insertOrUpdate:(NSString *)key withValue:(NSString *)value
{
    __block BOOL ret = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString *sql = @"SELECT key FROM key_value WHERE key = ?";
        FMResultSet *rs = [db executeQuery:sql, key];
        if ([rs next]) {
            ret = YES;
        }
        [rs close];
        
        if (ret) {
            sql = @"UPDATE key_value SET value = ? WHERE key = ?";
            ret = [db executeUpdate:sql, value, key];
        } else {
            sql = @"INSERT INTO key_value(key, value) VALUES "
            "(?, ?)";
            ret = [db executeUpdate:sql, key, value];
        }
    }];
    return ret;
}

+ (BOOL) remove:(NSString *)key
{
    __block BOOL ret = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString *sql = @"DELETE FROM key_value WHERE key = ?";
        ret = [db executeUpdate:sql, key];
    }];
    return ret;
}

+ (NSString *) select:(NSString *)key
{
    __block NSString *ret = nil;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString *sql = @"SELECT value FROM key_value WHERE key = ?";
        FMResultSet *rs = [db executeQuery:sql, key];
        if ([rs next]) {
            ret = [rs stringForColumnIndex:0];
        }
        [rs close];
        
    }];
    return ret;
}

+ (BOOL) exists:(NSString *)key
{
    __block BOOL ret = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString *sql = @"SELECT key FROM key_value WHERE key = ?";
        FMResultSet *rs = [db executeQuery:sql, key];
        if ([rs next]) {
            ret = YES;
        }
        [rs close];
    }];
    return ret;
}

@end

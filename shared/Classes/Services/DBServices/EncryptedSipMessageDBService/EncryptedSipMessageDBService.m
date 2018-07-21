//
//  EncryptedSipMessageDBService.m
//  qliq
//
//  Created by Adam on 12/3/12.
//
//

#import "EncryptedSipMessageDBService.h"
#import "DBUtil.h"

@interface EncryptedSipMessageDBService()
- (BOOL) insert: (EncryptedSipMessage *)msg inDB:(FMDatabase *)db;
- (NSArray *) messagesWithToQliqId: (NSString *)toQliqId limit:(int)limit inDB:(FMDatabase *)db;
- (BOOL) delete_: (int)messageId inDB:(FMDatabase *)db;
- (BOOL) deleteOlderThen:(NSTimeInterval)timestamp inDB:(FMDatabase *)db;

@end

@implementation EncryptedSipMessageDBService

@synthesize database;

+ (EncryptedSipMessageDBService *) sharedService
{
    static dispatch_once_t pred;
    static EncryptedSipMessageDBService *shared = nil;
    dispatch_once(&pred, ^{
        shared = [[EncryptedSipMessageDBService alloc] init];
        
    });
    return shared;
}

- (id) initWithDatabase:(FMDatabase *) _database{
    self = [super init];
    if (self) {
        self.database = _database;
    }
    return self;
}

- (BOOL) insert: (EncryptedSipMessage *)msg
{
    __block BOOL ret = NO;
    if (self.database) {
        ret = [self insert:msg inDB:self.database];
    } else {
        [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
            ret = [self insert:msg inDB:db];
        }];
    }
    return ret;
}

- (BOOL) insert: (EncryptedSipMessage *)msg inDB:(FMDatabase *)db
{
    NSString *extraHeaders = nil;
    if (msg.extraHeaders.count > 0) {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:msg.extraHeaders
                                                            options:0
                                                              error:&error];
        if (jsonData) {
            extraHeaders = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        } else {
            DDLogError(@"Cannot convert extraHeaders to JSON: %@", error.localizedDescription);
        }
    }
    
    NSString *sql = @"INSERT INTO encrypted_sip_message(from_uri, to_uri, body, timestamp, mime, extra_headers) VALUES "
    "(?, ?, ?, ?, ?, ?)";
    return [db executeUpdate:sql, msg.fromQliqId, msg.toQliqId, msg.body, [NSNumber numberWithDouble:msg.timestamp], msg.mime, extraHeaders];
}

- (NSArray *) messagesWithToQliqId: (NSString *)toQliqId limit:(int)limit
{
    __block NSArray *ret = NO;
    if (self.database) {
        ret = [self messagesWithToQliqId:toQliqId limit:limit inDB:self.database];
    } else {
        [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
            ret = [self messagesWithToQliqId:toQliqId limit:limit inDB:db];
        }];
    }
    return ret;
}

- (NSArray *) messagesWithToQliqId: (NSString *)qliqId limit:(int)limit inDB:(FMDatabase *)db
{
    NSString *sql = @"SELECT * FROM encrypted_sip_message WHERE to_uri = ?";
    FMResultSet *rs;
    if (limit > 0) {
        sql = [sql stringByAppendingString:@" LIMIT ?"];
        rs = [db executeQuery:sql, qliqId, [NSNumber numberWithInt:limit]];
    } else {
        rs = [db executeQuery:sql, qliqId];
    }
    
    NSMutableArray *ret = [[NSMutableArray alloc] init];
    while ([rs next]) {
        EncryptedSipMessage *msg = [[EncryptedSipMessage alloc] init];
        msg.messageId = [rs intForColumn:@"id"];
        msg.fromQliqId = [rs stringForColumn:@"from_uri"];
        msg.toQliqId = [rs stringForColumn:@"to_uri"];
        msg.body = [rs stringForColumn:@"body"];
        msg.timestamp = [rs doubleForColumn:@"timestamp"];
        msg.mime = [rs stringForColumn:@"mime"];
        
        NSString *extraHeaders = [rs stringForColumn:@"extra_headers"];
        if (extraHeaders.length > 0) {
            NSData *data = [extraHeaders dataUsingEncoding:NSUTF8StringEncoding];
            if (data != nil) {
                NSError *error;
                msg.extraHeaders = [NSJSONSerialization
                                     JSONObjectWithData:data
                                                options:kNilOptions
                                                  error:&error];
            }
        }
        [ret addObject: msg];
    }
 	[rs close];
    return ret;
}

- (BOOL) delete_: (int)messageId
{
    __block BOOL ret = NO;
    if (self.database) {
        ret = [self delete_:messageId inDB:self.database];
    } else {
        [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
            ret = [self delete_:messageId inDB:db];
        }];
    }
    return ret;
}

- (BOOL) delete_: (int)messageId inDB:(FMDatabase *)db
{
    NSString *sql = @"DELETE FROM encrypted_sip_message WHERE id = ?";
    return [db executeUpdate:sql, [NSNumber numberWithInt:messageId]];
}

- (BOOL)deleteOlderThen:(NSTimeInterval)timestamp
{
    __block BOOL ret = NO;
    if (self.database) {
        ret = [self deleteOlderThen:timestamp inDB:self.database];
    } else {
        [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
            ret = [self deleteOlderThen:timestamp inDB:db];
        }];
    }
    return ret;
}

- (BOOL) deleteOlderThen:(NSTimeInterval)timestamp inDB:(FMDatabase *)db
{
    NSString *sql = @"DELETE FROM encrypted_sip_message WHERE timestamp < ?";
    return [db executeUpdate:sql, [NSNumber numberWithDouble:timestamp]];
}
	
@end

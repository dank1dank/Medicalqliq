//
//  QliqStorDBService.m
//  qliq
//
//  Created by Adam Sowa on 1/29/14.
//
//

#import "QliqStorDBService.h"
#import "DBUtil.h"

@implementation QliqStorDBService

+ (int) lastSubjectSeq:(NSString *)subject forUser:(NSString *)qliqId andOperation:(int)operation
{
	__block int seq = 0;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString *query = @"SELECT "
        " seq "
        " FROM last_subject_seq "
        " WHERE subject = ? "
        " AND user_id = ? "
        " AND operation = ? ";
        
        FMResultSet *rs = [db executeQuery:query, subject, qliqId, [NSNumber numberWithInt:operation]];
        
        if ([rs next])
        {
            seq = [rs intForColumnIndex:0];
        }
        [rs close];
    }];
    return seq;
}

+ (NSString *) lastSubjectDatabaseUuid:(NSString *)subject forUser:(NSString *)qliqId andOperation:(int)operation
{
	__block NSString *ret = nil;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString *query = @"SELECT "
        " database_uuid "
        " FROM last_subject_seq "
        " WHERE subject = ? "
        " AND user_id = ? "
        " AND operation = ? ";
        
        FMResultSet *rs = [db executeQuery:query, subject, qliqId, [NSNumber numberWithInt:operation]];
        
        if ([rs next])
        {
            ret = [rs stringForColumnIndex:0];
        }
        [rs close];
    }];
    return ret;
}

+ (void) setLastSubjectSeq:(int)seq forSubject:(NSString *)subject forUser:(NSString *)qliqId andOperation:(int)operation
{
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString *query = @"SELECT "
        " id, seq "
        " FROM last_subject_seq "
        " WHERE subject = ? "
        " AND user_id = ? "
        " AND operation = ? ";
        
        int rowId = 0;
        int prevSeq = 0;
        FMResultSet *rs = [db executeQuery:query, subject, qliqId, [NSNumber numberWithInt:operation]];
        
        if ([rs next])
        {
            rowId = [rs intForColumnIndex:0];
            prevSeq = [rs intForColumnIndex:1];
        }
        [rs close];
        
        if (seq < prevSeq)
            DDLogWarn(@"Overwriting lower seq number for subject %@ for user: %@ now: %d, was: %d", subject, qliqId, seq, prevSeq);
        
        NSTimeInterval timestamp = [[NSDate date] timeIntervalSince1970];
        
        if (rowId == 0) {
            query = @"INSERT INTO last_subject_seq "
            " (subject, user_id, seq, last_update, operation) VALUES "
            " (?, ?, ?, ?, ?) ";
        } else {
            query = @"UPDATE last_subject_seq "
            " SET subject = ?, user_id = ?, seq = ?, last_update = ?, operation = ?"
            " WHERE id = ? ";
        }
        
        [db executeUpdate:query, subject, qliqId,
         [NSNumber numberWithInt:seq],
         [NSNumber numberWithDouble:timestamp],
         [NSNumber numberWithInt:operation],
         [NSNumber numberWithInt:rowId]];
    }];
}

+ (void) setLastSubjectDatabaseUuid:(NSString *)databaseUuid forSubject:(NSString *)subject forUser:(NSString *)qliqId andOperation:(int)operation
{
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString *query = @"SELECT "
        " id, database_uuid "
        " FROM last_subject_seq "
        " WHERE subject = ? "
        " AND user_id = ? "
        " AND operation = ? ";
        
        int rowId = 0;
        FMResultSet *rs = [db executeQuery:query, subject, qliqId, [NSNumber numberWithInt:operation]];
        
        if ([rs next])
        {
            rowId = [rs intForColumnIndex:0];
        }
        [rs close];
        
        if (rowId == 0) {
            query = @"INSERT INTO last_subject_seq "
            " (subject, user_id, database_uuid, last_update, operation) VALUES "
            " (?, ?, ?, ?, ?) ";
        } else {
            query = @"UPDATE last_subject_seq "
            " SET subject = ?, user_id = ?, database_uuid = ?, last_update = ?, operation = ?"
            " WHERE id = ? ";
        }
        
        NSTimeInterval timestamp = [[NSDate date] timeIntervalSince1970];
        
        [db executeUpdate:query, subject, qliqId,
         databaseUuid,
         [NSNumber numberWithDouble:timestamp],
         [NSNumber numberWithInt:operation],
         [NSNumber numberWithInt:rowId]];
    }];
}

+ (void) setLastSubjectSeqIfGreater:(int)seq forSubject:(NSString *)subject forUser:(NSString *)qliqId andOperation:(int)operation
{
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString *query = @"SELECT "
        " id, seq "
        " FROM last_subject_seq "
        " WHERE subject = ? "
        " AND user_id = ? "
        " AND operation = ? ";
        
        int rowId = 0;
        int prevSeq = 0;
        FMResultSet *rs = [db executeQuery:query, subject, qliqId, [NSNumber numberWithInt:operation]];
        
        if ([rs next])
        {
            rowId = [rs intForColumnIndex:0];
            prevSeq = [rs intForColumnIndex:1];
        }
        [rs close];
        
        NSTimeInterval timestamp = [[NSDate date] timeIntervalSince1970];
        
        if (seq > prevSeq) {
            
            if (rowId == 0) {
                query = @"INSERT INTO last_subject_seq "
                " (subject, user_id, seq, last_update, operation) VALUES "
                " (?, ?, ?, ?, ?) ";
            } else {
                query = @"UPDATE last_subject_seq "
                " SET subject = ?, user_id = ?, seq = ?, last_update = ?, operation = ? "
                " WHERE id = ? ";
            }
            
            BOOL ret = [db executeUpdate:query, subject, qliqId,
                        [NSNumber numberWithInt:seq],
                        [NSNumber numberWithDouble:timestamp],
                        [NSNumber numberWithInt:operation],
                        [NSNumber numberWithInt:rowId]];
            
            if (!ret)
                DDLogError(@"Cannot update last_subject_seq for subject: %@", subject);
        }
    }];
}

@end

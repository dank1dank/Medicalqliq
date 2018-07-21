//
//  MessageStatusLogDBService.m
//  qliq
//
//  Created by Paul Bar on 4/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MessageStatusLogDBService.h"
#import "MessageStatusLog.h"
#import "ChatMessage.h"

@interface MessageStatusLogDBService(Private)

-(BOOL) saveMessageStatusLog:(MessageStatusLog*)messageStatusLog inDB:(FMDatabase*)database;
-(NSArray*) getMessageStatusLogForMessage:(ChatMessage*)message inDB:(FMDatabase*)database;
-(BOOL) messageStatusLogExists:(MessageStatusLog*)messageStatusLog inDB:(FMDatabase *)database;
-(BOOL) insertMessageStatusLog:(MessageStatusLog*)messageStatusLog inDB:(FMDatabase *)database;
-(BOOL) updateMessageStatusLog:(MessageStatusLog*)messageStatusLog inDB:(FMDatabase *)database;

@end

@implementation MessageStatusLogDBService

+ (MessageStatusLogDBService *) sharedService{
    static dispatch_once_t pred;
    static id shared = nil;
    dispatch_once(&pred, ^{
        shared = [[MessageStatusLogDBService alloc] init];
        
    });
    return shared;
}

-(BOOL) saveMessageStatusLog:(MessageStatusLog *)messageStatusLog
{
    __block BOOL ret = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        ret = [self saveMessageStatusLog:messageStatusLog inDB:db];
    }];
	return ret;
}


-(BOOL) saveMessageStatusLog:(MessageStatusLog *)messageStatusLog inDB:(FMDatabase *)database
{
    BOOL rez = NO;
    
//    if([self messageStatusLogExists:messageStatusLog inDB:database])
//    {
//        rez = [self updateMessageStatusLog:messageStatusLog inDB:database];
//    }
//    else
    {
        rez = [self insertMessageStatusLog:messageStatusLog inDB:database];
    }
    return rez;
}

-(NSArray*) getMessageStatusLogForMessage:(ChatMessage *)message
{
    __block NSArray *ret = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        ret = [self getMessageStatusLogForMessage:message inDB:db];
    }];
	return ret;
}

-(NSArray*) getMessageStatusLogForMessage:(ChatMessage *)message inDB:(FMDatabase *)database
{
    NSMutableArray *mutableRez = [[NSMutableArray alloc] init];
    
    NSString *selectQuery = @""
    " SELECT * FROM message_status_log WHERE message_id = ? ORDER BY timestamp, rowid";
    
    FMResultSet *rs = [database executeQuery:selectQuery,[NSNumber numberWithInteger:message.messageId]];
    
    while ([rs next])
    {
		MessageStatusLog *messageStatusLog = [[MessageStatusLog alloc] init]; 
		messageStatusLog.messageId = [rs intForColumn:@"message_id"];
		messageStatusLog.timestamp = [rs doubleForColumn:@"timestamp"];
		messageStatusLog.status = [rs intForColumn:@"status"];
        messageStatusLog.statusText = [rs stringForColumn:@"status_text"];
        messageStatusLog.qliqId = [rs stringForColumn:@"qliq_id"];
        [mutableRez addObject:messageStatusLog];
		[messageStatusLog release];
    }
    [rs close];
    NSArray *rez = [NSArray arrayWithArray:mutableRez];
    [mutableRez release];
    
    return rez;
}

-(BOOL) deleteMessageStatusLogForMessage:(ChatMessage *)message withStatus:(NSInteger)status inDB:(FMDatabase *)database
{
    NSString *query = @"DELETE FROM message_status_log WHERE message_id = ? AND status = ?";    
    return [database executeUpdate:query,[NSNumber numberWithInteger:message.messageId],
                       [NSNumber numberWithInteger:status]];
}

#pragma mark -
#pragma mark Private

-(BOOL) messageStatusLogExists:(MessageStatusLog *)messageStatusLog inDB:(FMDatabase *)database
{
    NSString *selectQuery = @""
    "SELECT message_id FROM message_status_log where message_id = ? AND timestamp = ?";
    
    FMResultSet *rs = [database executeQuery:selectQuery,
                      [NSNumber numberWithInteger:messageStatusLog.messageId],
					  [NSNumber numberWithDouble:messageStatusLog.timestamp]];
    BOOL rez = NO;
    if([rs next])
    {
        rez = YES;
    }
    
    [rs close];
    return rez;
}

-(BOOL) insertMessageStatusLog:(MessageStatusLog *)messageStatusLog inDB:(FMDatabase *)database
{
	NSString *insertQuery = @""
    "INSERT INTO message_status_log ("
    " message_id, " 
    " timestamp, "
    " status, "
    " status_text, "
    " qliq_id "
    ") VALUES (?,?,?,?,?) ";
    
    BOOL rez = [database executeUpdate:insertQuery,
                [NSNumber numberWithInteger:messageStatusLog.messageId],
				[NSNumber numberWithInt:messageStatusLog.timestamp],
                [NSNumber numberWithInteger:messageStatusLog.status],
                messageStatusLog.statusText,
                messageStatusLog.qliqId];
    return rez;
}

-(BOOL) updateMessageStatusLog:(MessageStatusLog *)messageStatusLog inDB:(FMDatabase *)database
{
    NSString *updateQuery = @""
    " UPDATE message_status_log SET "
    " status = ?, "
    " status_text = ?, "
    " qliq_id = ? "
    " WHERE message_id = ? "
	" AND timestamp = ? " ;
    
    BOOL rez = [database executeUpdate:updateQuery,
                [NSNumber numberWithInteger:messageStatusLog.status],
                messageStatusLog.statusText,
                messageStatusLog.qliqId,
                [NSNumber numberWithInteger:messageStatusLog.messageId],
				[NSNumber numberWithInt:messageStatusLog.timestamp]];
    return rez;
}

- (BOOL) deleteWithMessageId:(int)messageId inDB:(FMDatabase *)database
{
    return [database executeUpdate:@"DELETE FROM message_status_log WHERE message_id = ?", [NSNumber numberWithInt:messageId]];
}

@end
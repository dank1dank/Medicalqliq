//
//  QuickMessage.m
//  qliq
//
//  Created by Paul Bar on 2/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QuickMessage.h"
#import "DBHelperConversation.h"

@implementation QuickMessage
@synthesize quickMessageId, message, displayOrder,uuid,category;

+ (NSMutableArray *) getQuickMessages
{
	__block NSMutableArray *quickMessagesArray = [[NSMutableArray alloc] init];
	[[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString *selectQuickMessagesQuery = @"SELECT "
        " id as quick_message_id, "
        " message, "
        " display_order "
        " FROM quick_message "
        " ORDER BY display_order ";
        
        FMResultSet *quick_message_rs = [db executeQuery:selectQuickMessagesQuery];
        
        while ([quick_message_rs next])
        {
            NSInteger primaryKey = [quick_message_rs intForColumn:@"quick_message_id"];
            QuickMessage *quickMessageObj = [[QuickMessage alloc] initWithPrimaryKey:primaryKey];
            quickMessageObj.message = [quick_message_rs stringForColumn:@"message"];
            quickMessageObj.displayOrder = [quick_message_rs intForColumn:@"display_order"];
            
            [quickMessagesArray addObject:quickMessageObj];
        }
        [quick_message_rs close];
    }];
	//after looping thru the result set, return the array
	return quickMessagesArray;
}

+ (NSInteger) addQuickMessage:(QuickMessage *)newQuickMsg
{
    __block NSInteger ret = 0;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        if ([db executeUpdate:@"INSERT INTO quick_message (message, display_order, uuid,category ) VALUES (?, ?,?,?)",newQuickMsg.message, [NSNumber numberWithInteger:newQuickMsg.displayOrder],newQuickMsg.uuid, newQuickMsg.category]) {
                ret = [db lastInsertRowId];
        }
    }];
    return ret;
}

+ (BOOL) updateQuickMessage:(QuickMessage *)quickMsg
{
    __block BOOL ret = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        ret = [db executeUpdate:@"UPDATE quick_message SET message=?, uuid=?, category=? where id=?",
                quickMsg.message, quickMsg.uuid, quickMsg.category, [NSNumber numberWithInteger:quickMsg.quickMessageId]];
    }];
    return ret;
}

+ (BOOL) updateQuickMessageOrder:(QuickMessage *)quickMsg 
{
    __block BOOL ret = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        ret = [db executeUpdate:@"UPDATE quick_message SET display_order=? where id=?",
               [NSNumber numberWithInteger:quickMsg.displayOrder],
               [NSNumber numberWithInteger:quickMsg.quickMessageId]];
    }];
    return ret;
}

+ (BOOL) deleteQuickMessage:(QuickMessage *)quickMsg 
{
    __block BOOL ret = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        ret = [db executeUpdate:@"DELETE FROM quick_message where id=?",
               [NSNumber numberWithInteger:quickMsg.quickMessageId]];
    }];
    return ret;
}

+ (BOOL) deletePriorQuickMessages
{
    __block BOOL ret = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        ret = [db executeUpdate:@"DELETE FROM quick_message where uuid IS NOT NULL"];
    }];
    return ret;
}

+ (BOOL) isQuickMessageExistWithMessage:(NSString*)message 
{
    __block BOOL ret = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        FMResultSet *quick_message_rs = [db executeQuery:@"SELECT * FROM quick_message WHERE message = ?", message];
        if ([quick_message_rs next])
        {
            ret = YES;
        }
        [quick_message_rs close];
    }];
	return ret;
}

- (id) initWithPrimaryKey:(NSInteger) pk {
    
    self = [super init];
    quickMessageId = pk;
    return self;
}


@end

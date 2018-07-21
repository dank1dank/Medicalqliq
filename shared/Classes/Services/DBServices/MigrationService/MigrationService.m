//
//  MigrationService.m
//  qliq
//
//  Created by Ravi Ada on 07/10/2012
//  Copyright (c) 2012 qliqSoft All rights reserved.
//

#import "MigrationService.h"
#import "UserSession.h"
#import "UserSessionService.h"
#import "CocoaLumberjack.h"
#import "ContactDBService.h"
#import "QliqUserDBService.h"
#import "ChatMessage.h"
#import "ChatMessageService.h"
#import "NSString+Path.h"

@interface MigrationService()

- (NSString*) getOldDatabasePath;

@end


@implementation MigrationService

+ (MigrationService *) sharedService{
    static dispatch_once_t pred;
    static id shared = nil;
    dispatch_once(&pred, ^{
        shared = [[MigrationService alloc] init];
        
    });
    return shared;
}

- (NSString*)documentsDir {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
    return [paths objectAtIndex:0];
}

- (NSString*) getOldDatabasePath{
	QliqUser *user = [UserSessionService currentUserSession].user;
	NSString *dbPath=nil;
	NSString *userId = user.email;
    NSString *documentsDirectory = [self documentsDir];
    NSString *relativeDBPath = [NSString stringWithFormat:@"%@/%@.sqlite", userId, userId];
    dbPath = [documentsDirectory stringByAppendingPathComponent:relativeDBPath];
	
    DDLogInfo(@"DB file: %@", dbPath);
	
    return dbPath;
}



-(BOOL) migrateConversationsFromOldDatabase
{ 
	BOOL rez=TRUE;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *oldDBPath = [self getOldDatabasePath];
	UserSession *currentSession = [UserSessionService currentUserSession];
	
	if(oldDBPath != nil && [fileManager fileExistsAtPath:oldDBPath]){
		DDLogInfo(@"%@  exists",oldDBPath);
		NSMutableString *attach_qry = [NSMutableString stringWithFormat:@"ATTACH DATABASE \"%@\" AS old_db",oldDBPath];
		DDLogInfo(@"%@",currentSession.dbKey);
		if(currentSession.dbKey != nil)
		{
			[attach_qry appendFormat:@" KEY \'%@\'", currentSession.dbKey];
		}
		DDLogInfo(@"attach stmt; %@",attach_qry);
		rez &= [[DBUtil sharedDBConnection]  executeUpdate:attach_qry];
		
		NSString *selectRequest = @"SELECT * FROM old_db.conversation";
		FMResultSet *rs = [[DBUtil sharedDBConnection]  executeQuery:selectRequest];
		while ([rs next])
		{
			NSInteger oldConversaionId = [rs intForColumn:@"id"];

			rez &= [[DBUtil sharedDBConnection]  executeUpdate:@"INSERT INTO conversation (subject, created_at, last_updated) VALUES (?,?,?)", 
			 [rs stringForColumn:@"subject"],
			 [NSNumber numberWithDouble:[rs doubleForColumn:@"created_at"]],
			 [NSNumber numberWithDouble:[rs doubleForColumn:@"last_updated"]]];
			
			NSInteger newConversationId = [[DBUtil sharedDBConnection]  lastInsertRowId];
			
			FMResultSet *rs1 = [[DBUtil sharedDBConnection]  executeQuery:@"SELECT * FROM old_db.conversation_leg WHERE conversation_id=?",
								[NSNumber numberWithInteger:oldConversaionId]];
			
			while ([rs1 next])
			{
				NSString *legUserId = [rs1 stringForColumn:@"user_id"];
				Contact *contact = [[ContactDBService sharedService] getContactByEmail:legUserId];
				QliqUser *qliqUser = [[QliqUserDBService sharedService] getUserForContact:contact];
				
				rez &= [[DBUtil sharedDBConnection]  executeUpdate:@"INSERT INTO conversation_leg (conversation_id,qliq_id, joined_at) VALUES (?,?,?)", 
				 [NSNumber numberWithInteger:newConversationId],
				 qliqUser.qliqId,
				 [NSNumber numberWithDouble:[rs1 doubleForColumn:@"joined_at"]]];			
			}
			[rs1 close];
			
			FMResultSet *rs2 = [[DBUtil sharedDBConnection]  executeQuery:@"SELECT * FROM old_db.message WHERE conversation_id =?",
								[NSNumber numberWithDouble:oldConversaionId]];
			while ([rs2 next])
			{
				NSString *fromUserId = [rs2 stringForColumn:@"from_user_id"];
				Contact *fromContact = [[ContactDBService sharedService] getContactByEmail:fromUserId];
				QliqUser *fromQliqUser = [[QliqUserDBService sharedService] getUserForContact:fromContact];
				
				NSString *toUserId = [rs2 stringForColumn:@"to_user_id"];
				Contact *toContact = [[ContactDBService sharedService] getContactByEmail:toUserId];
				QliqUser *toQliqUser = [[QliqUserDBService sharedService] getUserForContact:toContact];
				
				ChatMessage *chatMessage = [[ChatMessage alloc] init];
				chatMessage.conversationId = newConversationId;
				chatMessage.fromQliqId = fromQliqUser.qliqId;
				chatMessage.toQliqId = toQliqUser.qliqId;
				chatMessage.text = [rs2 stringForColumn:@"message"];
				chatMessage.ackRequired=[rs2 intForColumn:@"ack_required"];
				chatMessage.timestamp = [rs2 doubleForColumn:@"timestamp"];
				chatMessage.deliveryStatus = [rs2 intForColumn:@"delivery_status"];
				chatMessage.failedAttempts = [rs2 intForColumn:@"failed_attempts"];
				chatMessage.createdAt = [rs2 doubleForColumn:@"last_sent_at"];
				chatMessage.ackReceivedAt = [rs2 doubleForColumn:@"ack_received_at"];
				chatMessage.receivedAt = [rs2 doubleForColumn:@"received_at"];
				chatMessage.readAt = [rs2 doubleForColumn:@"read_at"];
				chatMessage.ackSentAt = [rs2 doubleForColumn:@"ack_sent_at"];
				chatMessage.localCreationTimestamp = [rs2 doubleForColumn:@"local_created_time"];
				chatMessage.callId = [rs2 stringForColumn:@"call_id"];
				chatMessage.hasAttachment = [rs2 boolForColumn:@"has_attachment"];
				chatMessage.metadata.uuid = [rs2 stringForColumn:@"uuid"];
				chatMessage.metadata.rev = [rs2 stringForColumn:@"rev"];
				chatMessage.metadata.author = [rs2 stringForColumn:@"author"];
				chatMessage.metadata.seq =  [rs2 intForColumn:@"seq"];
				chatMessage.metadata.isRevisionDirty =  [rs2 boolForColumn:@"is_rev_dirty"];
				[[ChatMessageService sharedService]  saveMessage:chatMessage];
			}	
			[rs2 close];
		}
		[rs close];
		rez &= [[DBUtil sharedDBConnection]  executeUpdate:@"INSERT INTO main.mediafiles (id,file_mime_type,file_path,encryption_key) SELECT * FROM old_db.mediafiles"];
		rez &= [[DBUtil sharedDBConnection]  executeUpdate:@"INSERT INTO main.message_attachment SELECT * FROM old_db.message_attachment"];
		rez &= [[DBUtil sharedDBConnection]  executeUpdate:@"INSERT INTO main.last_subject_seq SELECT * FROM old_db.last_subject_seq"];
        
        //TODO: 1) move the media files from "/Documents/<email>/media" to "/Documents/<qliqid>/media" folder  
        //2) media files and message_attachements need to be updates with the right path to the files
        //3) delete the "/Documents/<email> folder so that it wont process it again.
        
        NSString * documentDir = [self documentsDir];
        
        NSString *updateMediaQuery = @" UPDATE main.mediafiles SET file_path = ? WHERE id = ?";
        FMResultSet *mediaRs = [[DBUtil sharedDBConnection]  executeQuery:@"SELECT * FROM main.mediafiles"];
        while ([mediaRs next])
        {
            NSInteger mId = [mediaRs intForColumn:@"id"];
            NSString * filePath = [mediaRs stringForColumn:@"file_path"];
            NSString * newFilePath = [documentDir stringByAppendingFormat:@"/%@/Media/%@", currentSession.user.qliqId, [filePath lastFolderAndFilename]];
            rez &= [[DBUtil sharedDBConnection]  executeUpdate:updateMediaQuery, newFilePath, [NSNumber numberWithInteger:mId]];
        }
        [mediaRs close];
        
        NSString *updateAttachmentQuery = @" UPDATE main.mediafiles SET file_path = ? WHERE id = ?";
        FMResultSet *attachmentRs = [[DBUtil sharedDBConnection]  executeQuery:@"SELECT * FROM main.message_attachment"];
        while ([attachmentRs next])
        {
            NSInteger mId = [attachmentRs intForColumn:@"id"];
            NSString * filePath = [attachmentRs stringForColumn:@"file_path"];
            NSString * newFilePath = [documentDir stringByAppendingFormat:@"/%@/Media/%@", currentSession.user.qliqId, [filePath lastFolderAndFilename]];
            rez &= [[DBUtil sharedDBConnection]  executeUpdate:updateAttachmentQuery, newFilePath, [NSNumber numberWithInteger:mId]];
        }
        [attachmentRs close];
        [[DBUtil sharedDBConnection]  clearCachedStatements];
		[[DBUtil sharedDBConnection]  closeOpenResultSets];
		
		rez &= [[DBUtil sharedDBConnection]  executeUpdate:@"DETACH DATABASE old_db"];
		if(rez)
			[fileManager removeItemAtPath:[NSString stringWithFormat:@"%@/%@", documentDir, currentSession.user.email] error:nil];
	}else{
		DDLogInfo(@"Old database is not exist. Skip conversation migration.");
	}

    return rez;
}

@end

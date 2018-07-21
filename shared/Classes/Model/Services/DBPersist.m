//
//  DBPersist.m
//  CCiPhoneApp
//
//  Created by Ravi Ada on 4/12/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import "DBPersist.h"
#import "NSString+Version.h"
#import "JSONKit.h"
#import "Helper.h"
#import "NSMutableDictionary+Inits.h"
#import "QliqKeychainUtils.h"
#import "NSDate+Helper.h"
#import "Log.h"
#import "DBUtil.h"

@interface DBPersist()

@end

// Buffer size when reading from the file in bytes (=100 kbytes)
//static const NSUInteger ReadBufferSize = 131072;


@implementation DBPersist
#pragma mark Singleton Methods

+ (id)instance
{
    static DBPersist *_instance = nil;
    @synchronized(self) {
        if(_instance == nil)
            _instance = [[super alloc] init];
    }
    return _instance;
}

#pragma mark -
#pragma mark Buddy

//Buddy queries
- (NSMutableDictionary *) getBuddyList:(NSString *) qliqId
{
	//query all buddies associated with this user_id
	NSString *selectBuddyListQuery = @"SELECT "
	" buddylist.user_id, "
	" buddylist.buddy_user_id, "
	" user_sip_config.display_name, "
	" user_sip_config.sip_uri, "
	" user_sip_config.public_key "
	" FROM buddylist "
	" INNER JOIN user_sip_config ON (buddy_user_id = user_sip_config.user_id) ";
	//" WHERE buddylist.user_id = ? "; 
	
	//FMResultSet *buddy_rs = [[DBUtil sharedDBConnection]   executeQuery:selectBuddyListQuery,qliqId];
	FMResultSet *buddy_rs = [[DBUtil sharedDBConnection]   executeQuery:selectBuddyListQuery];
	
	NSMutableDictionary *buddyDict = [[[NSMutableDictionary alloc] init] autorelease];
	while ([buddy_rs next])
	{
		NSString *primaryKey = [buddy_rs stringForColumn:@"user_id"];
		Buddy *buddyObj = [[Buddy alloc] init];
		buddyObj.qliqId = primaryKey;				   
		buddyObj.buddyQliqId = [buddy_rs stringForColumn:@"buddy_user_id"];
		buddyObj.displayName = [buddy_rs stringForColumn:@"display_name"];
		buddyObj.publicKey = [buddy_rs stringForColumn:@"public_key"];
		[buddyDict setObject:buddyObj forKey:buddyObj.sipUri];
		//		DDLogSupport (@"buddy sipUri: %@", buddyObj.sipUri);
		[buddyObj release];
	}
	[buddy_rs close];
	[selectBuddyListQuery release];
	//after looping thru the result set, return the array
	return buddyDict;
}

- (BOOL) addBuddy:(Buddy *) buddy
{
    NSString *userToProcess = nil;
    
	//USR_SIP_CONFIG UPDATE/INSERT
	NSString *selectUsrSipConfigQuery = @"SELECT "
	" user_id "
	" FROM user_sip_config "
	" WHERE user_id = ?";
    
	FMResultSet *usr_sip_config_rs=nil;
	if([buddy.qliqId isEqualToString:buddy.buddyQliqId]){
		userToProcess =buddy.qliqId;
	}else{
		userToProcess =buddy.buddyQliqId;
	}
	usr_sip_config_rs = [[DBUtil sharedDBConnection]   executeQuery:selectUsrSipConfigQuery,userToProcess];
    
	BOOL recordFound=FALSE;
	while ([usr_sip_config_rs next]) {
		recordFound = TRUE;
	}
	[usr_sip_config_rs close];

	//begin transation to lock the table while inserting
	
	
	//update if recordFound otherwise insert
	if (recordFound)
    {
		if ([[DBUtil sharedDBConnection]   executeUpdate:@"UPDATE user_sip_config set display_name=?,sip_uri=?,public_key=?,last_updated_user=?, last_updated=? WHERE user_id=? ",
			 buddy.displayName,
			 buddy.sipUri,
			 buddy.publicKey,
			 buddy.qliqId,
			 [NSString stringWithFormat:@"%.0f",[[NSDate date] timeIntervalSince1970]],		 
			 buddy.buddyQliqId]==FALSE) 
		{
			
			return FALSE;
		}
        else
        {
			[[DBUtil sharedDBConnection]   executeUpdate:@"DELETE from user_role WHERE user_id =?",userToProcess];
			/*
			for(NSString* role in buddy.roles)
            {
				[[DBUtil sharedDBConnection]   executeUpdate:@"INSERT INTO user_role(user_id,role) VALUES(?,?)",userToProcess,role];
			}*/
		}
	}
    else
    {
		if ([[DBUtil sharedDBConnection]   executeUpdate:@"INSERT INTO user_sip_config (user_id, display_name, sip_uri, public_key,last_updated_user, last_updated) VALUES (?,?,?,?,?,?) ",
			 buddy.buddyQliqId,
			 buddy.displayName,
			 buddy.sipUri,
			 buddy.publicKey,
			 buddy.qliqId,
			 [NSString stringWithFormat:@"%.0f",[[NSDate date] timeIntervalSince1970]]]==FALSE)
		{
			
			//error - return 0;
			return FALSE;
		}else{
			/*
			for(NSString* role in buddy.roles){
				//[[DBUtil sharedDBConnection]   executeUpdate:@"INSERT INTO user_role(user_id,role) VALUES(?,?)",userToProcess,role];
			}*/
		}
	}
	
	//BUDDYLIST INSERT
	NSString *selectBuddyInfoQuery = @"SELECT "
	" user_id "
	" FROM buddylist "
	" WHERE user_id = ?"
	" AND buddy_user_id = ?";
	FMResultSet *buddylist_rs = [[DBUtil sharedDBConnection]   executeQuery:selectBuddyInfoQuery,buddy.qliqId, buddy.buddyQliqId];
	recordFound=FALSE;
	while ([buddylist_rs next]) {
		recordFound = TRUE;
	}
	[buddylist_rs close];

	//insert if not recordFound
	if (!recordFound){
		if (buddy.qliqId!=buddy.buddyQliqId) {
			if ([[DBUtil sharedDBConnection]   executeUpdate:@"INSERT INTO buddylist (user_id, buddy_user_id,last_updated_user, last_updated) VALUES (?,?,?,?) ",
				 buddy.qliqId,
				 buddy.buddyQliqId,
				 buddy.qliqId,
				 [NSString stringWithFormat:@"%.0f",[[NSDate date] timeIntervalSince1970]]]==FALSE)
			{
				
				//error - return 0;
				return FALSE;
			}
		}
	}
	
	//success - commit
	
	
	//success
	return TRUE;
}

// get the sip server information
- (NSMutableDictionary *) getSipServerInfo
{
	//query all buddies associated with this user_id
	NSString *selectSipServerInfoQuery = @"SELECT "
	" id as sip_server_id, "
	" fqdn, "
	" port, "
	" transport, "
    " multi_device "
	" FROM sip_server_info ";
	
	FMResultSet *sip_server_rs = [[DBUtil sharedDBConnection]   executeQuery:selectSipServerInfoQuery];
	
	NSMutableDictionary *sipServerDict = [[[NSMutableDictionary alloc] init] autorelease];
	while ([sip_server_rs next])
	{
		NSInteger primaryKey = [sip_server_rs intForColumn:@"sip_server_id"];
		SipServerInfo *sipServerObj = [[SipServerInfo alloc] initWithPrimaryKey:primaryKey];
		
		sipServerObj.fqdn = [sip_server_rs stringForColumn:@"fqdn"];
		sipServerObj.port = [sip_server_rs intForColumn:@"port"];
		sipServerObj.transport = [sip_server_rs stringForColumn:@"transport"];
        sipServerObj.multiDevice = [sip_server_rs boolForColumn:@"multi_device"];
		[sipServerDict setObject:sipServerObj forKey:sipServerObj.fqdn];
		[sipServerObj release];
	}
	[sip_server_rs close];
	//after looping thru the result set, return the array
	return sipServerDict;
}

// add/update sipserver
- (BOOL) addSipServerInfo:(SipServerInfo *) sipserver
{
	//query all buddies associated with this user_id
	NSString *selectSipServerInfoQuery = @"SELECT "
	" id as sip_server_id "
	" FROM sip_server_info "
	" WHERE fqdn = ?";
	
	FMResultSet *sip_server_rs = [[DBUtil sharedDBConnection]   executeQuery:selectSipServerInfoQuery,sipserver.fqdn];
	BOOL recordFound=FALSE;
	while ([sip_server_rs next]) {
		recordFound = TRUE;
	}
	[sip_server_rs close];
	//begin transation to lock the table while inserting
	
	
	//update if recordFound otherwise insert
	if (recordFound){
		if ([[DBUtil sharedDBConnection]   executeUpdate:@"UPDATE sip_server_info set port=?,transport=?,multi_device=?,last_updated_user=?,last_updated=? WHERE fqdn=? ",
			 [NSNumber numberWithInt:sipserver.port],
			 sipserver.transport,
             [NSNumber numberWithBool:sipserver.multiDevice],
			 [Helper getMyQliqId],
			 [NSString stringWithFormat:@"%.0f",[[NSDate date] timeIntervalSince1970]],		 
			 sipserver.fqdn]==FALSE)
		{
			
			return FALSE;
		}
	}else {
		if ([[DBUtil sharedDBConnection]   executeUpdate:@"INSERT INTO sip_server_info (fqdn,port,transport,multi_device,last_updated_user, last_updated) VALUES(?,?,?,?,?,?)",
			 sipserver.fqdn,
			 [NSNumber numberWithInt:sipserver.port],
			 sipserver.transport,
             [NSNumber numberWithBool:sipserver.multiDevice],
			 [Helper getMyQliqId],
			 [NSString stringWithFormat:@"%.0f",[[NSDate date] timeIntervalSince1970]]]==FALSE)
		{
			
			return FALSE;
		}
	}
	//success
	
	
	return TRUE;
}

- (BOOL) deleteAllSipServerInfo
{
    return [[DBUtil sharedDBConnection] executeUpdate:@"DELETE FROM sip_server_info"];
}

#pragma mark -
#pragma mark Generic Lists
- (void)dealloc {
	// Should never be called, but just here for clarity really.
	//[[DBUtil sharedDBConnection]   close];
	//[pool release];
	[super dealloc];
}
+ (Metadata *) loadMetadataFromResultSet: (FMResultSet *)rs
{
    Metadata *md = nil;
    NSString *uuid = [rs stringForColumn:@"uuid"];
    if ([uuid length] > 0) {
        md = [[[Metadata alloc] init] autorelease];
        md.uuid = uuid;
        md.rev = [rs stringForColumn:@"rev"];
        md.author = [rs stringForColumn:@"author"];
        md.seq = [rs intForColumn:@"seq"];
        md.isRevisionDirty = [rs boolForColumn:@"is_rev_dirty"];
    }
    return md;
}

- (int) lastSubjectSeq:(NSString *)subject forUser:(NSString *)qliqId andOperation:(int)operation
{
	NSString *query = @"SELECT "
	" seq "
	" FROM last_subject_seq "
	" WHERE subject = ? "
    " AND user_id = ? "
    " AND operation = ? ";    
	
	int seq = 0;
	FMResultSet *rs = [[DBUtil sharedDBConnection]   executeQuery:query, subject, qliqId, [NSNumber numberWithInt:operation]];
	
	if ([rs next])
	{
		seq = [rs intForColumnIndex:0];
	}
	[rs close];
    return seq;
}

- (NSString *) lastSubjectDatabaseUuid:(NSString *)subject forUser:(NSString *)qliqId andOperation:(int)operation
{
	NSString *query = @"SELECT "
	" database_uuid "
	" FROM last_subject_seq "
	" WHERE subject = ? "
    " AND user_id = ? "
    " AND operation = ? ";    
	
	NSString *ret = nil;
	FMResultSet *rs = [[DBUtil sharedDBConnection]   executeQuery:query, subject, qliqId, [NSNumber numberWithInt:operation]];
	
	if ([rs next])
	{
        ret = [rs stringForColumnIndex:0];
	}
	[rs close];
    return ret;    
}

- (void) setLastSubjectSeq:(int)seq forSubject:(NSString *)subject forUser:(NSString *)qliqId andOperation:(int)operation
{
	NSString *query = @"SELECT "
	" id, seq "
	" FROM last_subject_seq "
	" WHERE subject = ? "
    " AND user_id = ? "
    " AND operation = ? ";
    
	int rowId = 0;
    int prevSeq = 0;
	FMResultSet *rs = [[DBUtil sharedDBConnection]   executeQuery:query, subject, qliqId, [NSNumber numberWithInt:operation]];
    
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
    
    [[DBUtil sharedDBConnection]   executeUpdate:query, subject, qliqId,
     [NSNumber numberWithInt:seq],
     [NSNumber numberWithDouble:timestamp],     
     [NSNumber numberWithInt:operation],
     [NSNumber numberWithInt:rowId]];    
}

- (void) setLastSubjectDatabaseUuid:(NSString *)databaseUuid forSubject:(NSString *)subject forUser:(NSString *)qliqId andOperation:(int)operation
{
	NSString *query = @"SELECT "
	" id, database_uuid "
	" FROM last_subject_seq "
	" WHERE subject = ? "
    " AND user_id = ? "
    " AND operation = ? ";
    
	int rowId = 0;
	FMResultSet *rs = [[DBUtil sharedDBConnection]   executeQuery:query, subject, qliqId, [NSNumber numberWithInt:operation]];
    
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
    
    [[DBUtil sharedDBConnection]   executeUpdate:query, subject, qliqId,
     databaseUuid,
     [NSNumber numberWithDouble:timestamp],     
     [NSNumber numberWithInt:operation],
     [NSNumber numberWithInt:rowId]];    
}

- (void) setLastSubjectSeqIfGreater:(int)seq forSubject:(NSString *)subject forUser:(NSString *)qliqId andOperation:(int)operation
{
	NSString *query = @"SELECT "
	" id, seq "
	" FROM last_subject_seq "
	" WHERE subject = ? "
    " AND user_id = ? "
    " AND operation = ? ";
    
	int rowId = 0;
    int prevSeq = 0;
	FMResultSet *rs = [[DBUtil sharedDBConnection]   executeQuery:query, subject, qliqId, [NSNumber numberWithInt:operation]];
    
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
        
        BOOL ret = [[DBUtil sharedDBConnection]   executeUpdate:query, subject, qliqId,
         [NSNumber numberWithInt:seq],
         [NSNumber numberWithDouble:timestamp],
         [NSNumber numberWithInt:operation],
         [NSNumber numberWithInt:rowId]];
        
        if (!ret)
            DDLogError(@"Cannot update last_subject_seq for subject: %@", subject);
    }
}

- (void) resetLastSubjectSeqForOperation:(int)operation
{
    NSString *query = @"UPDATE last_subject_seq SET seq = 0 WHERE operation = ? ";
    [[DBUtil sharedDBConnection]   executeUpdate:query, [NSNumber numberWithInt:operation]];
}

- (NSMutableArray *) subjectRowIdsWithGreaterSeq:(NSString *)table :(NSUInteger)seq
{
	NSString *query = [NSString stringWithFormat:@"SELECT id FROM %@ WHERE seq > ? ORDER BY seq ", table];
	FMResultSet *rs = [[DBUtil sharedDBConnection]   executeQuery:query, [NSNumber numberWithUnsignedInteger:seq]];
	
	NSMutableArray *idsArray = [[[NSMutableArray alloc] init] autorelease];
	while ([rs next])
	{
		NSNumber *number = [NSNumber numberWithInt:[rs intForColumnIndex:0]];
		[idsArray addObject:number];
	}
	[rs close];
	return idsArray;
}

- (NSMutableArray *) subjectRowIdsWithGreaterSeq:(NSString *)table :(NSUInteger)seq andAuthor:(NSString *)author
{
	NSString *query = [NSString stringWithFormat:@"SELECT id FROM %@ WHERE seq > ? AND author = ? ORDER BY seq ", table];
	FMResultSet *rs = [[DBUtil sharedDBConnection]   executeQuery:query, [NSNumber numberWithUnsignedInteger:seq], author];
	
	NSMutableArray *idsArray = [[[NSMutableArray alloc] init] autorelease];
	while ([rs next])
	{
		NSNumber *number = [NSNumber numberWithInt:[rs intForColumnIndex:0]];
		[idsArray addObject:number];
	}
	[rs close];
	return idsArray;
}

- (NSTimeInterval) getSubjectLastUpdated:(NSString *)subject forQliqId:(NSString *)qliqId
{
    NSString *query = @"SELECT "
	" last_update "
	" FROM last_updated_subject "
	" WHERE subject = ? "
    " AND username = ? ";
    
    NSTimeInterval ret = 0.0;
	FMResultSet *rs = [[DBUtil sharedDBConnection]   executeQuery:query, subject, qliqId];
    
	if ([rs next])
	{
		ret = [rs doubleForColumnIndex:0];
	}
	[rs close];
    return ret;    
}

- (void) setSubjectLastUpdated:(NSString *)subject forQliqId:(NSString *)qliqId updated:(NSTimeInterval)ti
{
    NSString *query = @"SELECT "
	" id "
	" FROM last_updated_subject "
	" WHERE subject = ? "
    " AND username = ? ";
	
    int rowId = 0;
	FMResultSet *rs = [[DBUtil sharedDBConnection]   executeQuery:query, subject, qliqId];
	if ([rs next])
	{
		rowId = [rs intForColumnIndex:0];
	}
	[rs close];
    
    if (rowId > 0) {
        query = @"UPDATE last_updated_subject SET last_update = ? WHERE id = ?";
        [[DBUtil sharedDBConnection]   executeUpdate:query, subject, qliqId, [NSNumber numberWithDouble:ti], [NSNumber numberWithInt:rowId]];
    } else {
        query = @"INSERT INTO last_updated_subject(subject, username, last_update) VALUES(?, ?, ?)";
        [[DBUtil sharedDBConnection]   executeUpdate:query, subject, qliqId, [NSNumber numberWithDouble:ti]];        
    }    
}

- (NSUInteger) databaseSeq
{
    NSUInteger ret = 0;
    NSString *query = @"SELECT "
	" value "
	" FROM database_sequence "
	" LIMIT 1 "; // this table should contain just 1 row anyway
    
	FMResultSet *rs = [[DBUtil sharedDBConnection]   executeQuery:query];
	if ([rs next])
	{
		ret = [rs intForColumnIndex:0];
	}
	[rs close];
	
    return ret;
}

- (NSUInteger) incrementDatabaseSeq
{
    NSUInteger ret = 0;    
    NSString *query = @"UPDATE database_sequence "
	" SET value = value +1 ";
    
	
    [[DBUtil sharedDBConnection]   executeUpdate:query, nil];
    ret = [self databaseSeq];
	
    return ret;
}
#pragma reload DB file
-(BOOL)reloadDBFile
{
    return YES;
	 
}
- (BOOL) updateTableMetadata: (NSString *)table forRowId:(NSUInteger)rowId withMetadata:(Metadata *)md
{
    // Update metadata
    BOOL ret = NO;
    if (md) {
        NSString *sql = [NSString stringWithFormat:@"UPDATE %@ SET uuid = ?, rev = ?, author = ?, seq = ?, is_rev_dirty = ? WHERE id = ?", table];
        ret = [[DBUtil sharedDBConnection]   executeUpdate:sql,
			   md.uuid,
			   md.rev,
			   md.author,
			   [NSNumber numberWithUnsignedInt:md.seq],
			   [NSNumber numberWithBool:md.isRevisionDirty],               
			   [NSNumber numberWithUnsignedInt:rowId]];
    }
    return ret;
}

- (BOOL) updateTableMetadataAuthor: (NSString *)table forRowId:(NSUInteger)rowId author:(NSString *)author
{
    NSString *sql = [NSString stringWithFormat:@"UPDATE %@ SET author = ? WHERE id = ?", table];
    return [[DBUtil sharedDBConnection]   executeUpdate:sql,
			author,
			[NSNumber numberWithUnsignedInt:rowId]];
}

- (BOOL) setRevisionDirty: (NSString *)table forRowId:(NSUInteger)rowId dirty:(BOOL)isDirty
{
    NSString *sql = [NSString stringWithFormat:@"UPDATE %@ SET is_rev_dirty = ? WHERE id = ?", table];
    return [[DBUtil sharedDBConnection]   executeUpdate:sql,
            [NSNumber numberWithBool:isDirty],
            [NSNumber numberWithUnsignedInt:rowId]];
}

- (Metadata *) tableMetadata: (NSString *)table forRowId:(NSUInteger)rowId
{
    NSString *query = [NSString stringWithFormat:@"SELECT uuid, rev, author, seq, is_rev_dirty FROM %@ WHERE id = %u", table, rowId];
    FMResultSet *rs = [[DBUtil sharedDBConnection]   executeQuery:query];
    Metadata *md = [[[Metadata alloc] init] autorelease];
    if ([rs next]) {
        md.uuid = [rs stringForColumn:@"uuid"];
        md.rev = [rs stringForColumn:@"rev"];
        md.author = [rs stringForColumn:@"author"]; 
        md.seq = [rs intForColumn:@"seq"];
        md.isRevisionDirty = [rs boolForColumn:@"is_rev_dirty"];
    }
    [rs close];
    return md;
}

- (BOOL) updateTableSeq: (NSString *)table forRowId:(NSUInteger)rowId withSeq:(NSUInteger)seq
{
    NSString *sql = [NSString stringWithFormat:@"UPDATE %@ SET seq = ? WHERE id = ?", table];
    return [[DBUtil sharedDBConnection]   executeUpdate:sql, [NSNumber numberWithUnsignedInteger:seq], [NSNumber numberWithUnsignedInt:rowId]];
}

@end

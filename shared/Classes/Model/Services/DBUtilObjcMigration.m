//
//  DBUtilObjcMigration.m
//  qliq
//
//  Created by Aleksey Garbarev on 12.12.12.
//
//

#import "DBUtil.h"
#import "DBUtilObjcMigration.h"
#import "UserSessionService.h"

@implementation DBUtilObjcMigration

+ (BOOL) migration_to_23:(FMDatabase *)database
{
    
    BOOL success = YES;
 
    /* Move qliq_id from conversation_leg to recipients_qliq_id and link to conversation */
    
    NSString * converation_leg_queue = @"SELECT qliq_id, conversation_id FROM conversation_leg LEFT JOIN conversation ON (conversation_leg.conversation_id = conversation.id) WHERE conversation.recipients_id IS NULL;";
    
    FMResultSet * qliqid_to_migrate = [database executeQuery:converation_leg_queue];
    
    while ([qliqid_to_migrate next]){
        
        NSString * qliq_id = [qliqid_to_migrate objectForColumnName:@"qliq_id"];
        NSString * conversation_id = [qliqid_to_migrate objectForColumnName:@"conversation_id"];
        
        /* Insert into recepients */
        NSString * insert_recipients_query = @"INSERT INTO recipients (name) VALUES ('NULL')";
        success &= [database executeUpdate:insert_recipients_query];
        
        NSNumber * recipients_id = [NSNumber numberWithLongLong:[database lastInsertRowId]];
        
        /* Insert into recipients_qliq_id */
        NSString * recipients_qliq_id_query = @"INSERT INTO recipients_qliq_id(recipients_id, recipient_id, recipient_class) VALUES (?,?,?)";
        success &= [database executeUpdate:recipients_qliq_id_query,recipients_id,qliq_id, @"QliqUser"];
        
        /* Update conversation */
        NSString * conversation_update_query = @"UPDATE conversation SET recipients_id = ? WHERE id = ?";
        success &= [database executeUpdate:conversation_update_query,recipients_id, conversation_id];
    }
    
    return success;
}

/* Migration mediafiles */
+ (BOOL) migration_to_24:(FMDatabase *)database
{
    BOOL success = YES;
   
    NSString * mediafiles_queue = @"SELECT * FROM mediafiles;";
    
    FMResultSet * mediafiles_results = [database executeQuery:mediafiles_queue];
    
    while ([mediafiles_results next]){
        
        NSNumber * mediafile_id = [mediafiles_results objectForColumnName:@"id"];
        NSString * file_path = [mediafiles_results objectForColumnName:@"file_path"];

        /* Modify file_path */
        NSString * new_file_path = file_path;
        NSRange range = [file_path rangeOfString:@"Documents"];
        
        if (range.location != NSNotFound){
            
            NSRange rangeToDelete = { .location = 0, .length = range.location };
            
            new_file_path = [file_path stringByReplacingCharactersInRange:rangeToDelete withString:@""];
        }
        
        
        /* Update mediafile */
        NSString * mediafile_update_query = @"UPDATE mediafiles SET file_path = ? WHERE id = ?";
        success &= [database executeUpdate:mediafile_update_query,new_file_path, mediafile_id];
    }
    
    return success;
}

// Try to fix corrupted db with contact rows removed for related qliq_user rows
+ (BOOL) migration_to_32:(FMDatabase *)database
{
    // This update is empty just to increase the db number
    return YES;
}

+ (BOOL) insertCurrentUserInRecipientsThatAreMultiparty:(FMDatabase *)database
{
    NSString *sql = @"INSERT INTO recipients_qliq_id SELECT DISTINCT(recipients_id), ?, 'QliqUser' FROM recipients_qliq_id WHERE recipients_id NOT IN (SELECT recipients_id FROM recipients_qliq_id WHERE recipient_id = ?) AND recipients_id IN (select recipients_id from (select recipients_id, count(recipients_id) as rcount from recipients_qliq_id group by recipients_id) where rcount > 1);";
    NSString *myQliqId = [UserSessionService currentUserSession].user.qliqId;
    BOOL ret = [database executeUpdate:sql, myQliqId, myQliqId];
    int rowsInserted = [database changes];
    DDLogSupport(@"Inserting current user to recipients for all MPs, resulted in %d inserts", rowsInserted);
    return ret;
}

@end

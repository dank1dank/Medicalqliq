//
//  ContactListConversationsDBService.m
//  qliq
//
//  Created by Valerii Lider on 18/09/15.
//
//

#import "ContactListConversationsDBService.h"

#import "DBUtil.h"
#import "ContactListConversations.h"

@implementation ContactListConversationsDBService

- (BOOL)addListConversationsWithContactListId:(NSInteger)contactListId
                           withConversationId:(NSInteger)conversationId
                         withMultipartyQliqId:(NSString *)mpQliqId
{
    __block BOOL ret = NO;
    
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString * insertQuery = @""
        "INSERT INTO contact_list_conversations "
        "(contact_list_id, conversation_id, multiparty_id) "
        "VALUES (?,?,?)";

        ret = [db executeUpdate:insertQuery, [NSNumber numberWithInteger:contactListId],[NSNumber numberWithInteger:conversationId ], mpQliqId];
    }];
    return ret;
}

@end

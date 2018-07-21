//
//  ContactListConversations.m
//  qliq
//
//  Created by Valerii Lider on 18/09/15.
//
//

#import "ContactListConversations.h"

#import "FMResultSet.h"
#import "ContactListConversationsDBService.h"

@implementation ContactListConversations

+ (ContactListConversations *)listConversationsWithResultSet:(FMResultSet *)resultSet
{
    ContactListConversations *listConversations = [[ContactListConversations alloc] init];

    listConversations.contactListId = [resultSet intForColumn:@"contact_list_id"];
    listConversations.conversationId = [resultSet intForColumn:@"conversation_id"];
    listConversations.multiPartyQliqId = [resultSet stringForColumn:@"multiparty_id"];
    
    return  listConversations;
}

@end

//
//  ContactListConversationsDBService.h
//  qliq
//
//  Created by Valerii Lider on 18/09/15.
//
//

#import <Foundation/Foundation.h>

@interface ContactListConversationsDBService : NSObject

- (BOOL)addListConversationsWithContactListId:(NSInteger)contactListId
                           withConversationId:(NSInteger)conversationId
                         withMultipartyQliqId:(NSString *)mpQliqId;

@end

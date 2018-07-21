//
//  QliqListService.h
//  qliq
//
//  Created by Vita on 7/18/12.
//  Copyright (c) 2012 Al Digit. All rights reserved.
//


#import "ContactList.h"

@interface QliqListService : NSObject

+ (QliqListService *) sharedService;

-(ContactList*)getContactListWithConversationId:(NSInteger)conversationId;
-(NSArray*) getLists;
-(NSArray*) getOnlyUsersOfList:(ContactList*)list;
-(NSArray*) getContactsAndUsersOfList:(ContactList*)list;
-(NSArray*) getContactsAndUsersOfList:(ContactList*)list withLimit:(NSUInteger)limit;
-(NSArray*) getUsersOfList:(ContactList*)list;
-(NSArray*) getListsOfUser:(NSInteger)contactId;

-(BOOL) addListWithName:(NSString*)name;
-(BOOL) addListWithName:(NSString*)name andConversationId:(NSInteger)conversationId;
-(BOOL) addUserWithContactId:(NSInteger)contactId toList:(ContactList*)list;

-(BOOL) updateQliqId:(NSString *)qliqId forList:(ContactList *)list;

-(BOOL) removeList:(ContactList*)list;
-(BOOL) removeUserWithContactId:(NSInteger)contactId fromList:(ContactList*)list;
-(BOOL) removeAllUsersFromList:(ContactList*)list;

-(BOOL) isListExistWithName:(NSString *) name;

@end

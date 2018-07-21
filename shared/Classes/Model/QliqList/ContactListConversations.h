//
//  ContactListConversations.h
//  qliq
//
//  Created by Valerii Lider on 18/09/15.
//
//

#import <Foundation/Foundation.h>

@class FMResultSet;

@interface ContactListConversations : NSObject

@property (nonatomic, assign) NSInteger contactListId;
@property (nonatomic, assign) NSInteger conversationId;
@property (nonatomic, strong) NSString *multiPartyQliqId;

+ (ContactListConversations *)listConversationsWithResultSet:(FMResultSet*)resultSet;


@end
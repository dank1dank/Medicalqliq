//
//  CreateMultiParty.h
//  qliq
//
//  Created by Ravi Ada on 11/22/12.
//  Copyright (c) 2012 qliqSoft Inc. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "QliqAPIService.h"

@class Recipients;
@interface CreateMultiPartyService : QliqAPIService

- (id) initWithName:(NSString *) name andParticipants:(NSArray *) participants UNAVAILABLE_ATTRIBUTE;
- (id) initWithRecipients:(Recipients *) recipients andConversationId:(NSInteger)conversationId;
- (void) handleError:(NSError*) error;

+ (BOOL) hasOutstandingRequestForConversationId:(NSInteger)conversationId;

@end

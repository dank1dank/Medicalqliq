//
//  CreateMultiParty.h
//  qliq
//
//  Created by Ravi Ada on 11/22/12.
//  Copyright (c) 2012 qliqSoft Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CreateMultiParty : NSOperation
+ (CreateMultiParty *) sharedService;
-(void) createMultiParty:(NSString*) name andParticipantList:(NSArray*)participants;
-(void) createMultiPartyCompletitionBlock:(NSString*) name andParticipantList:(NSArray*)participants completionBlock:(CompletitionBlock) completition;
@end

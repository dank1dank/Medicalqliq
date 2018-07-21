//
//  UpdateMultiParty.h
//  qliq
//
//  Created by Ravi Ada on 10/19/12.
//  Copyright (c) 2012 qliqSoft Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UpdateMultiParty : NSOperation
+ (UpdateMultiParty *) sharedService;
-(void) updateMultiParty:(NSString*) groupQliqId;
-(void) updateMultiPartyCompletitionBlock:(NSString*) groupQliqId completionBlock:(CompletitionBlock) completition;
@end

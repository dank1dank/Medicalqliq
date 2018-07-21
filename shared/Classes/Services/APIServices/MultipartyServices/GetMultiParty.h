//
//  GetMultiParty.h
//  qliq
//
//  Created by Ravi Ada on 10/19/12.
//  Copyright (c) 2012 qliqSoft Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GetMultiParty : NSOperation
+ (GetMultiParty *) sharedService;
-(void) getMultiPartyInfo:(NSString*) multiPartyQliqId;
-(void) getMultiPartyInfoCompletitionBlock:(NSString*) multiPartyQliqId completionBlock:(CompletitionBlock) completition;
@end

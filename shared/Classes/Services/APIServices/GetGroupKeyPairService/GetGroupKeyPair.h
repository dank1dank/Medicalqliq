//
//  GetGroupKeyPair.h
//  qliq
//
//  Created by Ravi Ada on 10/19/12.
//  Copyright (c) 2012 qliqSoft Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface GetGroupKeyPair : NSOperation
+ (GetGroupKeyPair *) sharedService;
-(void) getGroupKeyPair:(NSString*) groupQliqId;
-(void) getGroupKeyPairCompletitionBlock:(NSString*) groupQliqId completionBlock:(CompletionBlock) completition;
@end

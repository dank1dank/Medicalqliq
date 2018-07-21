//
//  GetKeyPair.h
//  qliq
//
//  Created by Ravi Ada on 10/19/12.
//  Copyright (c) 2012 qliqSoft Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface GetKeyPair : NSOperation
+ (GetKeyPair *) sharedService;
-(BOOL) isKeyPairInKeychain;
-(void) getKeyPair;
-(void) getKeyPairCompletitionBlock:(CompletionBlock) completition;

@end

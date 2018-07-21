//
//  SetPublicKeyService.h
//  qliq
//
//  Created by Ravi Ada on 05/29/12.
//  Copyright (c) 2012 qliqSoft Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol SetPublicKeyServiceDelegate <NSObject>


@end

@interface SetPublicKeyService : NSOperation
{
}
+ (SetPublicKeyService *) sharedService;
-(void) setPublicKey:(NSString*) publicKey;

@property (nonatomic, assign) id<SetPublicKeyServiceDelegate> delegate;

@end

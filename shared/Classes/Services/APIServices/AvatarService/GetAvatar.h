//
//  GetAvatar.h
//  qliq
//
//  Created by Ravi Ada on 05/29/12.
//  Copyright (c) 2012 qliqSoft Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol GetAvatarDelegate <NSObject>


@end

@interface GetAvatar : NSOperation
{
}
+ (GetAvatar *) sharedService;

-(void) getAvatar:(NSString*) qliqId;

@property (nonatomic, assign) id<GetAvatarDelegate> delegate;

@end

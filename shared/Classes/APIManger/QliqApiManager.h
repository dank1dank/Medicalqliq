//
//  QliqApiManager.h
//  qliq
//
//  Created by Paul Bar on 2/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ADDelegateList;

@protocol QliqApiManagerDelegate;

@interface QliqApiManager : NSObject
{
    ADDelegateList *delegates;
}

+ (QliqApiManager *)instance;

- (void)addDelegate:(id<QliqApiManagerDelegate>)object;
- (void)removeDelegate:(id<QliqApiManagerDelegate>)object;


@end

//
//  QliqApiManager.m
//  qliq
//
//  Created by Paul Bar on 2/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QliqApiManagerDelegate.h"

#import "QliqApiManager.h"
#import "ADDelegateList.h"

static QliqApiManager *instance = nil;

@implementation QliqApiManager

#pragma mark - Singleton methods

+ (QliqApiManager *)instance
{
    @synchronized(self) {
        if(!instance) {
            instance = [[QliqApiManager alloc] init];
        }
        return instance;
    }
}

#pragma mark - Object lifecycle

- (id)init
{
    self = [super init];
    if(self)
    {
        delegates = [[ADDelegateList alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [delegates release];
    [super dealloc];
}

#pragma mark - Delegates Management

- (void)addDelegate:(id<QliqApiManagerDelegate>)object
{
    [delegates addDelegate:object];
}

- (void)removeDelegate:(id<QliqApiManagerDelegate>)object
{
    [delegates removeDelegate:object];
}

@end

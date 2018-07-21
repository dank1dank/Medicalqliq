//
//  ApiServiceBase.m
//  qliq
//
//  Created by Paul Bar on 2/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ApiServiceBase.h"
#import "QliqApiManager.h"

@implementation ApiServiceBase

- (id)init {
    self = [super init];
    if(self) {
        [[QliqApiManager instance] addDelegate:self];
    }
    return self;
}

- (void)dealloc
{
    [[QliqApiManager instance] removeDelegate:self];
    [super dealloc];
}

@end

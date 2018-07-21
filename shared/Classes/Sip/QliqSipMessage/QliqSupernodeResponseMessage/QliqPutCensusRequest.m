//
//  QliqPutCensusRequest.m
//  qliq
//
//  Created by Paul Bar on 1/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QliqPutCensusRequest.h"

@implementation QliqPutCensusRequest

@synthesize dataDict;

-(id) initWithDictionary:(NSDictionary *)dict
{
    self = [super initWithDictionary:dict];
    if(self)
    {
        self.dataDict = [dict objectForKey:@"Data"];
    }
    return self;
}

-(void) dealloc
{
    [dataDict release];
    [super dealloc];
}
@end

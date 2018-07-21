//
//  DBServiceBase.m
//  qliq
//
//  Created by Paul Bar on 2/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//


#import "DBUtil.h"
#import "DBServiceBase.h"
@interface DBServiceBase()

@end

@implementation DBServiceBase
@synthesize db = db;
@synthesize queue = queue;

-(id) init
{
    self = [super init];
    if(self)
    {
        //self.db_ = [DBUtil sharedDBConnection];
        [[DBUtil sharedInstance] addDelegate:self];
        [self updateDbConnection];
    }
    return self;
}



/*
- (FMDatabase *) db{
    
    @synchronized(self){
      return db;  
    }
}*/


-(void) dealloc
{
    [[DBUtil sharedInstance] removeDelegate:self];
    [db release];
    [super dealloc];
}

-(void) updateDbConnection
{
    self.queue = [DBUtil sharedQueue];
    self.db = [DBUtil sharedDBConnection];
}

@end

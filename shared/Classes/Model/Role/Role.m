//
//  Role.m
//  qliq
//
//  Created by Paul Bar on 2/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Role.h"
#import "FMResultSet.h"
#import "NSObject+AutoDescription.h"

@implementation Role

@synthesize name;

+(Role*) roleWithResultSet:(FMResultSet *)rs
{
    Role *rez = [[Role alloc] init];
    
    rez.name = [rs stringForColumn:@"role"];
    
    return [rez autorelease];
}

-(void) dealloc
{
    [self.name release];
    [super dealloc];
}

-(NSString *)description
{
    return [self autoDescription];
}

@end

//
//  Taxonomy.m
//  CCiPhoneApp
//
//  Created by Ravi Ada on 12/4/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import "Taxonomy.h"
#import "FMResultSet.h"

@implementation Taxonomy
@synthesize code,type,classification,specialization;


+(Taxonomy*) initTaxonomyWithResultSet:(FMResultSet *)resultSet
{
    Taxonomy *taxonomy = [[Taxonomy alloc] init];
    
    taxonomy.code = [resultSet stringForColumn:@"code"];
    taxonomy.type = [resultSet stringForColumn:@"type"];
    taxonomy.classification = [resultSet stringForColumn:@"classification"];
    taxonomy.specialization = [resultSet stringForColumn:@"specialization"];
   
    return [taxonomy autorelease];
}

-(void) dealloc
{
    [code release];
    [type release];
    [classification release];
    [specialization release];
    [super dealloc];
}

@end

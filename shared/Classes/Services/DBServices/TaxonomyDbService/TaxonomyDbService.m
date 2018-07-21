//
//  TaxonomyService.m
//  qliq
//
//  Created by Paul Bar on 2/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TaxonomyDbService.h"
#import "DBUtil.h"

@interface TaxonomyDbService()

-(BOOL) taxonomyExists:(Taxonomy*)taxonomy;

@end

@implementation TaxonomyDbService

-(Taxonomy*) getTaxonomy:(NSString *)code
{
    __block Taxonomy *rez = nil;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString *selectQuery = @""
        " SELECT * FROM taxonomy WHERE code = ?";
        
        FMResultSet *rs = [db executeQuery:selectQuery,code];
        
        if([rs next])
        {
            rez = [Taxonomy initTaxonomyWithResultSet:rs];
        }
        [rs close];
    }];
    return rez;
}

-(NSString*) getSpeacilityForTaxonomyCode:(NSString *) code
{
	NSString *specialty = nil;
	if([code length] >0){
		Taxonomy *taxonomy = [[self getTaxonomy:code] retain];
		if([taxonomy.specialization length]>0)
			specialty = taxonomy.specialization;
		else
			specialty = taxonomy.classification;
		[taxonomy release];
	}else{
		specialty = @"";
	}
	return specialty;
}

#pragma mark -
#pragma mark Private

-(BOOL)taxonomyExists:(Taxonomy *)taxonomy
{
    __block BOOL ret = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString *selectQuery = @""
        "SELECT * FROM taxonomy WHERE code = ?";
        NSLog(@"taxonomy_code: %@",taxonomy.code);
        
        FMResultSet *rs = [db executeQuery:selectQuery,taxonomy.code];
        
        if([rs next])
        {
            ret = YES;
        }
        [rs close];
    }];
    return ret;
}

@end

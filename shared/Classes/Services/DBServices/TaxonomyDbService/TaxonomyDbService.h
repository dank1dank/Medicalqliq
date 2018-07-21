//
//  TaxonomyService.h
//  qliq
//
//  Created by Paul Bar on 2/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//


#import "Taxonomy.h"

@interface TaxonomyDbService : NSObject 

-(Taxonomy*) getTaxonomy:(NSString*)code;
-(NSString*) getSpeacilityForTaxonomyCode:(NSString *) code;

@end

//
//  Taxonomy.h
//  CCiPhoneApp
//
//  Created by Ravi Ada on 12/4/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
@class FMResultSet;

@interface Taxonomy : NSObject{
	NSString *code;
	NSString *type;
	NSString *classification;
	NSString *specialization;
}
@property (nonatomic, retain) NSString *code;
@property (nonatomic, retain) NSString *type;
@property (nonatomic, retain) NSString *classification;
@property (nonatomic, retain) NSString *specialization;

+(Taxonomy*) initTaxonomyWithResultSet:(FMResultSet*)resultSet;

@end

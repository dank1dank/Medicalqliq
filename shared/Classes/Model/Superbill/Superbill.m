//
//  Superbill.m
//  CCiPhoneApp
//
//  Created by Ravi Ada on 4/18/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import "Superbill.h"
#import "FMResultSet.h"

@implementation Superbill
@synthesize taxonomyCode,name,data,cptGroups;

+ (id) initSuperbillWithResultSet:(FMResultSet*)resultSet
{

	Superbill *superbill = [[Superbill alloc] init];
	superbill.taxonomyCode = [resultSet stringForColumn:@"taxonomy_code"];
	superbill.name = [resultSet stringForColumn:@"name"];
	superbill.data = [resultSet stringForColumn:@"data"];
	
	return [superbill autorelease];
}

- (void) dealloc {
	[taxonomyCode release];
	[name release];
	[data release];
	[cptGroups release];
	[super dealloc];
}

@end

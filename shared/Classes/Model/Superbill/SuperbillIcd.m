//
//  Superbill.m
//  CCiPhoneApp
//
//  Created by Ravi Ada on 4/18/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import "SuperbillIcd.h"
#import "DBHelperSuperbill.h"

//Superbill ICD interfaces
@implementation SuperbillIcd
@synthesize superbillIcdId,superbillCptId,icdCode;
@synthesize isDetailViewHydrated;
+ (NSInteger) addSuperbillIcd:(SuperbillIcd *)superbillIcd
{
    return [DBHelperSuperbill addSuperbillIcd:superbillIcd];
}


- (id) initWithPrimaryKey:(NSInteger) pk {
    
    [super init];
    superbillIcdId = pk;
    isDetailViewHydrated = NO;
    
    return self;
}

- (void) dealloc {
	[icdCode release];
	[super dealloc];
}
@end

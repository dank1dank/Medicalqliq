//
//  Superbill.m
//  CCiPhoneApp
//
//  Created by Ravi Ada on 4/18/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import "SuperbillModifier.h"
#import "DBHelperSuperbill.h"

//Superbill CPT modifiers interfaces

@implementation SuperbillCptModifier
@synthesize superbillCptModifierId,superbillId,modifier,modifierDescription,isAnnexData,annexValue;
@synthesize isDetailViewHydrated;

+ (NSMutableArray *) getSuperbillCptModifiers:(NSInteger)superbillCptId
{
    return [DBHelperSuperbill getSuperbillCptModifiers:superbillCptId];
}
+ (NSMutableArray *) getAllCptModifiers
{
    return [DBHelperSuperbill getAllCptModifiers];
}
+ (NSInteger) addSuperbillCptModifier:(SuperbillCptModifier *) superbillCptModifier
{
    return [DBHelperSuperbill addSuperbillCptModifier:superbillCptModifier];
}


- (id) initWithPrimaryKey:(NSInteger) pk {
    
    [super init];
    superbillCptModifierId = pk;
    isDetailViewHydrated = NO;
    
    return self;
}

- (void) dealloc {
	[modifier release];
    [modifierDescription release];
	[super dealloc];
}

@end

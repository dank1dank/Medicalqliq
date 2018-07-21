//
//  Superbill.m
//  CCiPhoneApp
//
//  Created by Ravi Ada on 4/18/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import "SuperbillCpt.h"
#import "DBHelperSuperbill.h"

//Superbill CPT interfaces
@implementation SuperbillCpt

@synthesize superbillCptId,
            superbillId,
            cptCode,
            cptAbbr,
            cptGroupId,
            cptDisplayOrder,
            modifiers,
            modifierRequired;

@synthesize cptShortDescription,
            cptLongDescription,
            masterCptPft,
            physicianCptPft,
            isAnnexData,
            isRequired,
            annexValue,
            annexValueAbbr,
            textToDisplay,
            annexDescription;
@synthesize isDetailViewHydrated;

+ (NSInteger) getSuperbillId:(double) physicianNpi
{
    return [DBHelperSuperbill getSuperbillId:physicianNpi];
}
+ (NSMutableArray *) getSuperbillCptCodes:(NSInteger)superbillId:(NSInteger)superbillCptGroupId:(double) physicianNpi
{
    return [DBHelperSuperbill getSuperbillCptCodes:superbillId :superbillCptGroupId:physicianNpi];
}
+ (BOOL) updatePhysicianCptPft:(NSString *)cptCode:(NSString *)cptPft
{
	return [DBHelperSuperbill updatePhysicianCptPft:cptCode :cptPft];
}

+ (NSInteger) addSuperbillCpt:(SuperbillCpt *) superbillCpt
{
    return [DBHelperSuperbill addSuperbillCpt:superbillCpt];
}
+ (NSMutableArray *) getSuperbillAnnexData:(NSInteger)superbillId:(NSInteger)superbillCptGroupId:(NSInteger) valueLocation
{
    return [DBHelperSuperbill getSuperbillAnnexData:superbillId :superbillCptGroupId:valueLocation];
}

- (id) initWithPrimaryKey:(NSInteger) pk {
    
    [super init];
    superbillCptId = pk;
    isDetailViewHydrated = NO;
    
    return self;
}
- (void) dealloc {
	[cptCode release];
	[cptAbbr release];
	[cptShortDescription release];
	[cptLongDescription release];
	[masterCptPft release];
	[physicianCptPft release];
	[annexValue release];
	[annexValueAbbr release];
	[annexDescription release];
	[modifiers release];
	[textToDisplay release];
	[super dealloc];
}
@end

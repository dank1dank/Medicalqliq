//
//  Cpt.m
//  CCiPhoneApp
//
//  Created by Ravi Ada on 5/6/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import "Cpt.h"

#import "Cpt.h"
#import "DBPersist.h"

static NSMutableArray* recentCPTEntries = nil;

@implementation Cpt
@synthesize code,
            shortDescription,
            versionYear,
            longDescription,
            masterCptPft,
            physicianCptPft;
@synthesize isDirty,
            isDetailViewHydrated;

@synthesize inFavorites = _inFavorites;



+ (NSMutableArray *) getMasterCptsToDisplay
{
    return [[DBPersist instance] getMasterCptsToDisplay];
}

+ (NSMutableArray *) getFavoriteCptsToDisplay:(NSInteger) superbillId
{
    return [[DBPersist instance] getFavoriteCptsToDisplay:superbillId];
}

+ (BOOL) updatePhysicianCptPft:(NSString *)cptCode:(NSString *)cptPft
{
	return [[DBPersist instance] updatePhysicianCptPft:cptCode:cptPft];
}

+ (NSInteger) addCptToFavorites:(NSInteger)superBillId :(NSString *)cptCode:(double) physicianNpi
{
    return [[DBPersist instance] addCptToFavorites:superBillId:cptCode:physicianNpi];
}

+ (BOOL) deleteCptFromFavorites:(NSInteger)superBillId :(NSString *)cptCode:(double) physicianNpi
{
    return [[DBPersist instance] deleteCptFromFavorites:superBillId:cptCode:physicianNpi];
}

+ (BOOL) deleteAllCpts 
{
    return [[DBPersist instance] deleteAllCpts];
}

+ (BOOL) updateCptsFromFile: (NSFileHandle*) dataFile
{
    return [[DBPersist instance] updateCptsFromFile: dataFile];
}

+ (Cpt *) getCptObjectForCptCode:(NSString *) cptCode 
{
    return [[DBPersist instance] getCptObjectForCptCode:cptCode];
}

+ (FMResultSet *)ftsWithQuery:(NSString *)query {
    return [[DBPersist instance] cptFTSWithQuery:query];
}

+ (BOOL) checkAddNewCpt:(Cpt *)cptObj{
    return [[DBPersist instance] checkAddNewCpt:cptObj];
}

- (id) initWithPrimaryKey:(NSString *) pk {
    
    [super init];
    code = pk;
    isDetailViewHydrated = NO;
    _inFavorites = NO;
    
    return self;
}

- (BOOL)isFavoriteFor:(double) physicianNpi:(NSInteger) superbillId {
    return [[DBPersist instance] isCptFavorite:self.code :superbillId];
}

- (NSString *)allText
{
    return [NSString stringWithFormat:@"%@ %@ %@ %@ %@", self.code, self.shortDescription, self.longDescription, self.masterCptPft, self.physicianCptPft];
}

- (BOOL)savePft {
    return [[self class] updatePhysicianCptPft:self.code :self.physicianCptPft];
}

- (void) dealloc {
 	[code release];
    [shortDescription release];
    [longDescription release];
	[masterCptPft release];
	[physicianCptPft release];
 	[super dealloc];
}


+ (void)eraseRecentCpts
{
    [recentCPTEntries removeAllObjects];
}

+ (NSMutableArray*)recentCpts
{
    return recentCPTEntries;
}

+ (void) deleteRecentCptAtIndex:(NSInteger)index
{
    return [recentCPTEntries removeObjectAtIndex:index];
}

+(BOOL) recentCptsContainsGroupWithId:(NSInteger)groupId
{
   /*
	for(SuperbillCpt *cpt in [self recentCpts])
    {
        if(cpt.cptGroupId == groupId)
        {
            return YES;
        }
    }*/
    return NO;
}
/*
+(SuperbillCpt*) getRecentCptWithGroupId:(NSInteger)groupId
{
    for(SuperbillCpt *cpt in [self recentCpts])
    {
        if(cpt.cptGroupId == groupId)
        {
            return cpt;
        }
    }
    return nil;
}

+ (void) addRecentCpt: (SuperbillCpt*) aCpt
{
	//if(aCpt.cptCode != 0){
		if (recentCPTEntries == nil)
		{
			recentCPTEntries = [[NSMutableArray alloc] init];
								//]WithCapacity: 1];
		}
		//else {
		//	[recentCPTEntries removeAllObjects];
		//}
		
		
		BOOL shouldBeAdded = YES;
		for (SuperbillCpt* cpt in recentCPTEntries)
		{
			if ([cpt.cptCode isEqualToString: aCpt.cptCode])
			{
				shouldBeAdded = NO;
			}
		}
		
		if (shouldBeAdded)
		{
			//aCpt.modifiers = [[NSMutableArray alloc] init];
			[recentCPTEntries addObject: aCpt];
		}
	//}else {
	//	[recentCPTEntries removeAllObjects];
	//}
}
*/

+ (NSString *) getShortDescription: (Cpt*) cptObj
{
	if(cptObj.physicianCptPft != nil)
    {
		return cptObj.physicianCptPft;
    }
	else if(cptObj.masterCptPft != nil)
    {
		return cptObj.masterCptPft;
    }
	else
    {
        //if([cptObj respondsToSelector:@selector(cptShortDescription)])
        //{
		return cptObj.shortDescription;
        //}
    }
    return @"";
}
@end

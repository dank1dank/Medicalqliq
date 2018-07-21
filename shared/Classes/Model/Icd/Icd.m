//
//  Icd.m
//  CCiPhoneApp
//
//  Created by Ravi Ada on 4/12/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import "Icd.h"
#import "DBPersist.h"

@implementation Icd
@synthesize code,shortDescription,versionYear,longDescription,masterIcdPft,physicianIcdPft;
@synthesize isDirty,isDetailViewHydrated;

@synthesize inCrosswalk = _inCrosswalk;
@synthesize inFavorites = _inFavorites;

+ (NSMutableArray *) getMasterIcdsToDisplay
{
    return [[DBPersist instance] getMasterIcdsToDisplay];
}

+ (NSMutableArray *) getCrosswalkIcdsToDisplay:(NSInteger)superbillCptId
{
    return [[DBPersist instance] getCrosswalkIcdsToDisplay:superbillCptId];
}

+ (NSMutableArray *) getFavoriteIcdsToDisplay:(double) physicianNpi
{
    return [[DBPersist instance] getFavoriteIcdsToDisplay:physicianNpi];
}

+ (BOOL) updatePhysicianIcdPft:(NSString *)icdCode:(NSString *)icdPft
{
	return [[DBPersist instance] updatePhysicianIcdPft:icdCode:icdPft];
}

+ (NSInteger) addToFavorites:(NSString *)icdCode:(double) physicianNpi
{
    return [[DBPersist instance] addToFavorites:icdCode:physicianNpi];
}

+ (BOOL) deleteFromFavorites:(NSString *)icdCode:(double) physicianNpi {
    return [[DBPersist instance] deleteFromFavorites:icdCode :physicianNpi];
}

+ (BOOL) deleteAllIcds {
    return [[DBPersist instance] deleteAllIcds];
}

+ (BOOL) updateIcdsFromFile: (NSFileHandle*) dataFile {
    return [[DBPersist instance] updateIcdsFromFile: dataFile];
}

+ (Icd *) getIcdObjectForIcdcode:(NSString *) icdCode {
	return [[DBPersist instance] getIcdObjectForIcdcode:icdCode];
}

+ (FMResultSet *)ftsWithQuery:(NSString *)query {
    return [[DBPersist instance] icdFTSWithQuery:query];
}

- (id) initWithPrimaryKey:(NSString *) pk {
    
    [super init];
    code= pk;
    isDetailViewHydrated = NO;
    _inCrosswalk = NO;
    _inFavorites = NO;
    
    return self;
}

- (BOOL)isFavoriteFor:(double) physicianNpi:(NSInteger) superbillId {
    return [[DBPersist instance] isIcdFavorite:self.code :physicianNpi];
}

- (NSString *)allText {
    return [NSString stringWithFormat:@"%@ %@ %@ %@ %@", self.code, self.shortDescription, self.longDescription, self.masterIcdPft, self.physicianIcdPft];
}

- (BOOL)savePft {
    return [[self class] updatePhysicianIcdPft:self.code :self.physicianIcdPft];
}

+ (NSString *) getShortDescription: (Icd*) icdObj
{
	if(icdObj.physicianIcdPft != nil)
		return icdObj.physicianIcdPft;
	else if(icdObj.masterIcdPft != nil)
		return icdObj.masterIcdPft;
	else 
		return icdObj.shortDescription;
}

- (void) dealloc {
 	[code release];
    [shortDescription release];
    [longDescription release];
	[masterIcdPft release];
	[physicianIcdPft release];
 	[super dealloc];
}

@end

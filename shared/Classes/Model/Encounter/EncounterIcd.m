//
//  EncounterIcd.m
//  CCiPhoneApp
//
//  Created by Ravi Ada on 4/12/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import "EncounterIcd.h"
#import "DBPersist.h"

@implementation EncounterIcd
@synthesize encounterIcdId,encounterCptId,isPrimary,icdCode,shortDescription,masterIcdPft,physicianIcdPft;
@synthesize isDirty,isDetailViewHydrated;
@synthesize dateOfService;
@synthesize status;
@synthesize lastUpdated, lastUpdatedUser;
+ (NSMutableArray *) getEncounterIcdsForCpt:(NSInteger)encounterCptId
{
    return [[DBPersist instance] getEncounterIcdsForCpt:encounterCptId];
}

+ (NSMutableArray *) getPreviousEncounterIcds:(NSInteger)censusId:(NSTimeInterval)dateOfService
{
	return [[DBPersist instance] getPreviousEncounterIcds:censusId:dateOfService];
}
+ (NSInteger) addEncounterIcd:(EncounterIcd *)encounterIcd
{
    return [[DBPersist instance] addEncounterIcd:encounterIcd];
}
+ (BOOL) deleteEncounterIcd:(EncounterIcd *)encounterIcd
{
    return [[DBPersist instance] deleteEncounterIcd:encounterIcd];
}
+ (BOOL) setPrimary:(EncounterIcd *)encounterIcd
{
    return [[DBPersist instance] setPrimary:encounterIcd];
}
+ (BOOL) resetPrimary:(EncounterIcd *)encounterIcd
{
    return [[DBPersist instance] resetPrimary:encounterIcd];
}

- (id) initWithPrimaryKey:(NSInteger) pk {
    
    [super init];
    encounterIcdId = pk;
    isDetailViewHydrated = NO;
    
    return self;
}

- (void) dealloc {
 	[icdCode release];
    [shortDescription release];
    [physicianIcdPft release];
	[masterIcdPft release];
	[super dealloc];
}

- (NSString *)description {
    if (self.isPrimary) {
        return [NSString stringWithFormat:@"<Primary: %@ - %@>", self.icdCode, self.shortDescription];
    }

    return [NSString stringWithFormat:@"<%@ - %@>", self.icdCode, self.shortDescription];
}
@end

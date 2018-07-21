//
//  EncounterCptModifier.m
//  CCiPhoneApp
//
//  Created by Ravi Ada on 4/12/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import "EncounterCptModifier.h"
#import "DBPersist.h"

@implementation EncounterCptModifier
@synthesize encounterCptModifierId,encounterCptId,modifier;
@synthesize isDirty,isDetailViewHydrated;
@synthesize dateOfService;
@synthesize status;
@synthesize lastUpdated, lastUpdatedUser;

+ (NSMutableArray *) getModifiersForCpt:(NSInteger)encounterCptId
{
    return [[DBPersist instance] getModifiersForCpt:encounterCptId];
}

+ (NSString *) getModifierListAsStringForCpt:(NSInteger)encounterCptId
{
    return [[DBPersist instance] getModifierListAsStringForCpt:encounterCptId];
}

+ (NSInteger) addEncounterCptModifier:(EncounterCptModifier *)encounterCptModifier
{
    return [[DBPersist instance] addEncounterCptModifier:encounterCptModifier];
}

+ (BOOL) deleteEncounterCptModifier:(EncounterCptModifier *)encounterCptModifier;
{
    return [[DBPersist instance] deleteEncounterCptModifier:encounterCptModifier];
}

- (id) initWithPrimaryKey:(NSInteger) pk {
    
    [super init];
    encounterCptModifierId = pk;
    isDetailViewHydrated = NO;
    
    return self;
}

- (void)dealloc {
    [modifier release];
    [super dealloc];
}

@end

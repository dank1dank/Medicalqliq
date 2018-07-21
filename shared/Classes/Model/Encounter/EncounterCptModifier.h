//
//  EncounterCptModifier.h
//  CCiPhoneApp
//
//  Created by Ravi Ada on 4/12/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Encounter_old.h"

@interface EncounterCptModifier : NSObject {
    /*
     CREATE TABLE encounter_cpt_modifier (
     id integer PRIMARY KEY AUTOINCREMENT,
     encounter_cpt_id  integer,
     modifier VARCHAR(25),
    FOREIGN KEY (encounter_cpt_id)
    REFERENCES encounter_cpt(id)
    );
     */
    
    NSInteger encounterCptModifierId;
    NSInteger encounterCptId;
    NSString *modifier;
    EncounterStatus status;
    NSTimeInterval lastUpdated;
    NSString *lastUpdatedUser;
	
	BOOL isDirty;
	BOOL isDetailViewHydrated;
    
}
@property (nonatomic, readonly) NSInteger encounterCptModifierId;
@property (nonatomic, readwrite) NSInteger encounterCptId;
@property (nonatomic, retain) NSString *modifier;

@property (nonatomic, assign) NSTimeInterval dateOfService;

@property (nonatomic, readwrite) BOOL isDirty;
@property (nonatomic, readwrite) BOOL isDetailViewHydrated;
@property (nonatomic, readwrite) EncounterStatus status;
@property (nonatomic, readwrite) NSTimeInterval lastUpdated;
@property (nonatomic, retain) NSString *lastUpdatedUser;

//Static methods.
+ (NSMutableArray *) getModifiersForCpt:(NSInteger)encounterCptId;
+ (NSString *) getModifierListAsStringForCpt:(NSInteger)encounterCptId;
+ (NSInteger) addEncounterCptModifier:(EncounterCptModifier *)encounterCptModifier;
+ (BOOL) deleteEncounterCptModifier:(EncounterCptModifier *)encounterCptModifier;
//Instance methods.
- (id) initWithPrimaryKey:(NSInteger)pk;

@end

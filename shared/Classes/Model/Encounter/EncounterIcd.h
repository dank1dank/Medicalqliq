//
//  EncounterIcd.h
//  CCiPhoneApp
//
//  Created by Ravi Ada on 4/12/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Encounter_old.h"

@interface EncounterIcd : NSObject {
     
    NSInteger encounterIcdId;
    NSInteger encounterCptId;
    BOOL isPrimary;
    NSString *icdCode;
    NSString *shortDescription;
    NSString *masterIcdPft;
	NSString *physicianIcdPft;
 	EncounterStatus status;
    NSTimeInterval lastUpdated;
    NSString *lastUpdatedUser;    
	
	BOOL isDirty;
	BOOL isDetailViewHydrated;
    
}
@property (nonatomic, readonly) NSInteger encounterIcdId;
@property (nonatomic, readwrite) NSInteger encounterCptId;
@property (nonatomic, readwrite) BOOL isPrimary;
@property (nonatomic, retain) NSString *icdCode;
@property (nonatomic, retain) NSString *shortDescription;
@property (nonatomic, retain) NSString *masterIcdPft;
@property (nonatomic, retain) NSString *physicianIcdPft;

@property (nonatomic, assign) NSTimeInterval dateOfService;
@property (nonatomic, readwrite) NSTimeInterval lastUpdated;
@property (nonatomic, retain) NSString *lastUpdatedUser;

@property (nonatomic, readwrite) BOOL isDirty;
@property (nonatomic, readwrite) BOOL isDetailViewHydrated;
@property (nonatomic, readwrite) EncounterStatus status;

//Static methods.
+ (NSMutableArray *) getEncounterIcdsForCpt:(NSInteger)encounterCptId;
+ (NSMutableArray *) getPreviousEncounterIcds:(NSInteger)censusId:(NSTimeInterval)dateOfService;
+ (NSInteger) addEncounterIcd:(EncounterIcd *)encounterIcd;
+ (BOOL) deleteEncounterIcd:(EncounterIcd *)encounterIcd;
+ (BOOL) setPrimary:(EncounterIcd *)encounterIcd;
+ (BOOL) resetPrimary:(EncounterIcd *)encounterIcd;


//Instance methods.
- (id) initWithPrimaryKey:(NSInteger)pk;

@end

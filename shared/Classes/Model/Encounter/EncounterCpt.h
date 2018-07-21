//
//  EncounterCpt.h
//  CCiPhoneApp
//
//  Created by Ravi Ada on 4/12/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Encounter_old.h"

@interface EncounterCpt : NSObject {
	
    NSInteger encounterCptId;
    NSInteger encounterId;
	NSString *cptCode;
    NSString *codeWithModifiers;
    NSString *shortDescription;
    NSString *masterCptPft;
	NSString *physicianCptPft;
	NSTimeInterval createdAt;
	NSString *createdUser;
    NSTimeInterval lastUpdated;
    NSString *lastUpdatedUser;    
	EncounterStatus status;
    
	BOOL isDirty;
	BOOL isDetailViewHydrated;
    
}
@property (nonatomic, readonly) NSInteger encounterCptId;
@property (nonatomic, readwrite) NSInteger encounterId;
@property (nonatomic, retain) NSString *cptCode;
@property (nonatomic, retain) NSString *codeWithModifiers;
@property (nonatomic, retain) NSString *shortDescription;
@property (nonatomic, retain) NSString *masterCptPft;
@property (nonatomic, retain) NSString *physicianCptPft;
@property (nonatomic, readwrite) NSTimeInterval createdAt;
@property (nonatomic, retain) NSString *createdUser;
@property (nonatomic, readwrite) NSTimeInterval lastUpdated;
@property (nonatomic, retain) NSString *lastUpdatedUser;
@property (nonatomic, readwrite) EncounterStatus status;


@property (nonatomic, assign) NSTimeInterval dateOfService;

@property (nonatomic, readwrite) BOOL isDirty;
@property (nonatomic, readwrite) BOOL isDetailViewHydrated;

//Static methods.
+ (NSMutableArray *) getChargesToDisplayForCensus:(Census_old*)censusObj andDos:(NSTimeInterval)dateOfService;
+ (NSMutableArray *) getChargesToDisplayForAppointment:(NSInteger)appointmentId :(NSTimeInterval)dateOfService;
+ (NSInteger) addEncounterCpt:(EncounterCpt *)encounterCpt;
+ (BOOL) deleteEncounterCpt:(NSInteger)encounterCptId;

//Instance methods.
- (id) initWithPrimaryKey:(NSInteger)pk;

@end

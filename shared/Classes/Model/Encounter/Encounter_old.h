//
//  Encounter.h
//  CCiPhoneApp
//
//  Created by Ravi Ada on 4/12/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@class Census_old;

//charge transaction
@interface ChargesPullRequest : NSObject {

    NSString *transactionId;
    NSTimeInterval lastUpdated;
    NSTimeInterval syncRequested;
    NSString *syncRequestUser;
	NSInteger pageNum;
    NSString *syncData;
    NSTimeInterval sentTime;
    NSString *sentStatus;
}
@property (nonatomic, retain) NSString *transactionId;
@property (nonatomic, readwrite) NSTimeInterval lastUpdated;
@property (nonatomic, readwrite) NSTimeInterval syncRequested;
@property (nonatomic, retain) NSString *syncRequestUser;
@property (nonatomic, readwrite) NSInteger pageNum;
@property (nonatomic, retain) NSString *syncData;
@property (nonatomic, readwrite) NSTimeInterval sentTime;
@property (nonatomic, retain) NSString *sentStatus;

//Static methods.
//+ (BOOL) addTxnCharges:(TxnCharges *) txnCharges;
//+ (BOOL) updateSentStatus:(TxnCharges *) txnCharges;
//+ (BOOL) updateReplyStatus:(TxnCharges *) txnCharges;

//Instance methods.
- (id) initWithPrimaryKey:(NSString *) transId :(NSInteger) pn;

@end


typedef enum {
    EncounterStatusVisit = 0,
    EncounterStatusNoVisit = 4,
    EncounterStatusWIP = 1,
    EncounterStatusComplete = 2,
    EncounterStatusDeleted = 3
} EncounterStatus;

@interface Encounter_old : NSObject {
   
    NSInteger encounterId;
    NSInteger censusId;
    NSInteger apptId;
    NSTimeInterval dateOfService;
    double attendingPhysicianNpi;
	EncounterStatus status;
    NSTimeInterval lastUpdated;
    NSString *lastUpdatedUser;    
    
	BOOL isDirty;
    
}
@property (nonatomic, readwrite) NSInteger encounterId;
@property (nonatomic, readwrite) NSInteger censusId;
@property (nonatomic, readwrite) NSInteger apptId;
@property (nonatomic, readwrite) NSTimeInterval dateOfService;
@property (nonatomic, readwrite) double attendingPhysicianNpi;
@property (nonatomic, readwrite) EncounterStatus status;
@property (nonatomic, readwrite) NSTimeInterval lastUpdated;
@property (nonatomic, retain) NSString *lastUpdatedUser;
@property (nonatomic, readwrite) BOOL isDirty;

//Static methods.
+ (NSInteger) addEncounter:(Encounter_old *)encounter;
+ (BOOL) deleteEncounter:(NSInteger)encounterId;
+ (NSInteger) getNoteCount:(NSInteger)encounterId;
+ (NSInteger) getEncounterForCensus:(NSInteger) censusId:(double) attendingPhysicianNpi :(NSTimeInterval) dateOfService;
+ (Encounter_old *) getEncounterObjForCensus:(NSInteger) censusId:(double) attendingPhysicianNpi :(NSTimeInterval) dateOfService;
+ (NSInteger) getEncounterForAppt:(NSInteger) apptId:(double) attendingPhysicianNpi :(NSTimeInterval) dateOfService;

+ (BOOL) updateEncounter:(NSInteger)encounterId withStatus:(EncounterStatus)newStatus;
+ (NSMutableDictionary *) getChargesForDesktopSync:(ChargesPullRequest*)chargesPullRequest;
+ (NSInteger) getEncounterId:(NSInteger)encounterCptId;
+ (BOOL) updateEncounterLastUpdated:(NSInteger)encounterId;
+ (BOOL) copyCharge:(NSDictionary *)chargeDictObj andCensusObj:(Census_old*)censusObj andCurrentDos:(NSTimeInterval)currentDos;


- (id) initWithPrimaryKey:(NSInteger) pk;

@end

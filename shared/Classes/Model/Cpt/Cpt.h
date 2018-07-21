//
//  Cpt.h
//  CCiPhoneApp
//
//  Created by Ravi Ada on 5/6/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import "SuperbillCpt.h"

@class FMResultSet;

@interface Cpt : NSObject {
    NSString *code;
    NSString *shortDescription;
    NSInteger versionYear;
    NSString *longDescription;
    NSString *masterCptPft;
	NSString *physicianCptPft;
    
	BOOL isDirty;
	BOOL isDetailViewHydrated;
    
}
@property (nonatomic, retain) NSString *code;
@property (nonatomic, retain) NSString *shortDescription;
@property (nonatomic, readwrite) NSInteger versionYear;
@property (nonatomic, retain) NSString *longDescription;
@property (nonatomic, retain) NSString *masterCptPft;
@property (nonatomic, retain) NSString *physicianCptPft;

@property (nonatomic, readonly) NSString *allText;

@property (nonatomic, assign, getter = isInFavorites) BOOL inFavorites;

@property (nonatomic, readwrite) BOOL isDirty;
@property (nonatomic, readwrite) BOOL isDetailViewHydrated;

//Static methods.
+ (NSMutableArray *) getMasterCptsToDisplay;
+ (NSMutableArray *) getFavoriteCptsToDisplay:(NSInteger) superbillId;
+ (BOOL) updatePhysicianCptPft:(NSString *)cptCode:(NSString *)cptPft;
+ (NSInteger) addCptToFavorites:(NSInteger)superBillId :(NSString *)cptCode:(double) physicianNpi;
+ (BOOL) deleteCptFromFavorites:(NSInteger)superBillId :(NSString *)cptCode:(double) physicianNpi;
+ (BOOL) deleteAllCpts;
+ (BOOL) updateCptsFromFile: (NSFileHandle*) dataFile;
+ (Cpt *) getCptObjectForCptCode:(NSString *) cptCode;
+ (FMResultSet *)ftsWithQuery:(NSString *)query;
+ (NSMutableArray*)recentCpts;
//+ (void)addRecentCpt: (SuperbillCpt *) aCpt;
+ (void)eraseRecentCpts;
+ (void)deleteRecentCptAtIndex:(NSInteger)index;
+ (BOOL)recentCptsContainsGroupWithId:(NSInteger)groupId;
//+ (SuperbillCpt*) getRecentCptWithGroupId:(NSInteger)groupId;
+ (NSString *)getShortDescription:(Cpt*) cptObj;
+ (BOOL) checkAddNewCpt:(Cpt *)cptObj;


//Instance methods.
- (id) initWithPrimaryKey:(NSString *)pk;
- (BOOL)isFavoriteFor:(double) physicianNpi:(NSInteger) superbillId;
- (BOOL)savePft;

@end

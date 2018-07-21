//
//  Icd.h
//  CCiPhoneApp
//
//  Created by Ravi Ada on 4/12/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FMResultSet;

@interface Icd : NSObject {
    
    NSString *code;
    NSString *shortDescription;
    NSInteger versionYear;
    NSString *longDescription;
    NSString *masterIcdPft;
	NSString *physicianIcdPft;
    
	BOOL isDirty;
	BOOL isDetailViewHydrated;
    
}
@property (nonatomic, retain) NSString *code;
@property (nonatomic, retain) NSString *shortDescription;
@property (nonatomic, readwrite) NSInteger versionYear;
@property (nonatomic, retain) NSString *longDescription;
@property (nonatomic, retain) NSString *masterIcdPft;
@property (nonatomic, retain) NSString *physicianIcdPft;

// MZ: trick to search all field without logic operators
@property (nonatomic, readonly) NSString *allText;

@property (nonatomic, assign, getter = isInFavorites) BOOL inFavorites;
@property (nonatomic, assign, getter = isInCrosswalk) BOOL inCrosswalk;

@property (nonatomic, readwrite) BOOL isDirty;
@property (nonatomic, readwrite) BOOL isDetailViewHydrated;

//Static methods.
+ (NSMutableArray *) getMasterIcdsToDisplay;
+ (NSMutableArray *) getCrosswalkIcdsToDisplay:(NSInteger)superbillCptId;
+ (NSMutableArray *) getFavoriteIcdsToDisplay:(double) physicianNpi;
+ (BOOL) updatePhysicianIcdPft:(NSString *)icdCode:(NSString *)icdPft;
+ (NSInteger) addToFavorites:(NSString *)icdCode:(double) physicianNpi;
+ (BOOL) deleteFromFavorites:(NSString *)icdCode:(double) physicianNpi;
+ (BOOL) deleteAllIcds;
+ (BOOL) updateIcdsFromFile: (NSFileHandle*) dataFile;
+ (Icd *) getIcdObjectForIcdcode:(NSString *) icdCode;
+ (FMResultSet *)ftsWithQuery:(NSString *)query;
+ (NSString *)getShortDescription:(Icd *) icdObj;

//Instance methods.
- (id) initWithPrimaryKey:(NSString *)pk;
- (BOOL)isFavoriteFor:(double) physicianNpi:(NSInteger) superbillId;
- (BOOL)savePft;

@end

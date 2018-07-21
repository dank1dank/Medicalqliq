//
//  SuperbillCpt.h
//
//  Created by Ravi Ada on 4/18/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SuperbillCpt : NSObject {
    NSInteger superbillCptId;
    NSInteger superbillId;
    NSString *cptCode;
    NSString *cptAbbr;
    NSInteger cptGroupId;
	NSInteger cptDisplayOrder;
    NSString *cptShortDescription;
    NSString *cptLongDescription;
    NSString *masterCptPft;
	NSString *physicianCptPft;
	BOOL isAnnexData;
	BOOL isRequired;
    NSString *annexValue;
    NSString *annexValueAbbr;
	NSString *annexDescription;
	NSMutableArray *modifiers;
	NSInteger modifierRequired;
	NSString *textToDisplay;
    
	//Intrnal variables to keep track of the state of the object.
	BOOL isDetailViewHydrated;
}
@property (nonatomic, readonly) NSInteger superbillCptId;
@property (nonatomic, readwrite) NSInteger superbillId;
@property (nonatomic, retain) NSString  *cptCode;
@property (nonatomic, retain) NSString  *cptAbbr;
@property (nonatomic, readwrite) NSInteger cptGroupId;
@property (nonatomic, readwrite) NSInteger cptDisplayOrder;
@property (nonatomic, retain) NSString  *cptShortDescription;
@property (nonatomic, retain) NSString  *cptLongDescription;
@property (nonatomic, retain) NSString  *masterCptPft;
@property (nonatomic, retain) NSString  *physicianCptPft;
@property (nonatomic, readwrite) BOOL isAnnexData;
@property (nonatomic, readwrite) BOOL isRequired;
@property (nonatomic, retain) NSString  *annexValue;
@property (nonatomic, retain) NSString  *annexValueAbbr;
@property (nonatomic, retain) NSString  *annexDescription;
@property (nonatomic, retain) NSMutableArray  *modifiers;
@property (nonatomic, readwrite) NSInteger modifierRequired;
@property (nonatomic, retain) NSString  *textToDisplay;


@property (nonatomic, readwrite) BOOL isDetailViewHydrated;

//Static methods.
+ (NSInteger) getSuperbillId:(double) physicianNpi;
+ (NSMutableArray *) getSuperbillCptCodes:(NSInteger)superbillId:(NSInteger)superbillCptGroupId:(double) physicianNpi;
+ (BOOL) updatePhysicianCptPft:(NSString *)cptCode:(NSString *)cptPft;
+ (NSInteger) addSuperbillCpt:(SuperbillCpt *) superbillCpt;
+ (NSMutableArray *) getSuperbillAnnexData:(NSInteger)superbillId:(NSInteger)superbillCptGroupId:(NSInteger) valueLocation;
//Instance methods.
- (id) initWithPrimaryKey:(NSInteger)pk;
@end



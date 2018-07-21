//
//  DBHelperSuperbill.h
//  CCiPhoneApp
//
//  Created by Ravi Ada on 11/17/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Superbill.h"
#import "SuperbillCpt.h"
#import "SuperbillIcd.h"
#import "SuperbillModifier.h"
#import "SuperbillCptGroup.h"

@interface DBHelperSuperbill : NSObject

//Superbill queries
+ (NSInteger) getSuperbillId: (double) physicianNpi;
+ (NSMutableArray *) getSuperbillCptGroups:(NSInteger)superbillId;
+ (NSMutableArray *) getSuperbillCptCodes:(NSInteger)superbillId:(NSInteger)superbillCptGroupId:(double) physicianNpi;
+ (NSMutableArray *) getSuperbillAnnexData:(NSInteger)superbillId:(NSInteger)superbillCptGroupId:(NSInteger) valueLocation;
+ (NSMutableArray *) getAllCptModifiers;
+ (NSMutableArray *) getSuperbillCptModifiers:(NSInteger)superbillId;
+ (NSMutableArray *) getSuperbillsToDisplay;
+ (NSInteger) addSuperbill:(Superbill *) superbill;
+ (NSInteger) addSuperbillCpt:(SuperbillCpt *) superbillCpt;
+ (NSInteger) addSuperbillIcd:(SuperbillIcd *)superbillIcd;
+ (NSInteger) addSuperbillCptModifier:(SuperbillCptModifier *) superbillCptModifier;
+ (BOOL) updatePhysicianCptPft:(NSString *)cptCode:(NSString *)cptPft;
+ (NSInteger) getSuperbillForSpecialty:(NSString *) specialty;
+ (NSString *) getTaxonomyCodeForSpeciality:(NSString*)specialty;
+ (SuperbillCptGroup*) getCptGroup:(NSInteger) cptGroupId;

@end

//
//  Superbill.h
//  CCiPhoneApp
//
//  Created by Ravi Ada on 4/18/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SuperbillCptModifier : NSObject {
    NSInteger superbillCptModifierId;
    NSInteger superbillId;
    NSString *modifier;
    NSString *modifierDescription;
	BOOL isAnnexData;
	NSString *annexValue;
    
	//Intrnal variables to keep track of the state of the object.
	BOOL isDetailViewHydrated;    
}
@property (nonatomic, readonly) NSInteger superbillCptModifierId;
@property (nonatomic, readwrite) NSInteger superbillId;
@property (nonatomic, retain) NSString  *modifier;
@property (nonatomic, retain) NSString  *modifierDescription;
@property (nonatomic, readwrite) BOOL isAnnexData;
@property (nonatomic, retain) NSString  *annexValue;

@property (nonatomic, readwrite) BOOL isDetailViewHydrated;
//Static methods.
+ (NSMutableArray *) getSuperbillCptModifiers:(NSInteger)superbillCptId;
+ (NSMutableArray *) getAllCptModifiers;
+ (NSInteger) addSuperbillCptModifier:(SuperbillCptModifier *) superbillCptModifier;
//Instance methods.
- (id) initWithPrimaryKey:(NSInteger)pk;

@end


//
//  Superbill.h
//  CCiPhoneApp
//
//  Created by Ravi Ada on 4/18/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SuperbillIcd : NSObject {
    NSInteger superbillIcdId;
    NSInteger superbillCptId;
    NSString *icdCode;
    
	//Intrnal variables to keep track of the state of the object.
	BOOL isDetailViewHydrated;    
}
@property (nonatomic, readonly) NSInteger superbillIcdId;
@property (nonatomic, readwrite) NSInteger superbillCptId;
@property (nonatomic, retain) NSString *icdCode;

@property (nonatomic, readwrite) BOOL isDetailViewHydrated;
//Static methods.
+ (NSInteger) addSuperbillIcd:(SuperbillIcd *)superbillIcd;

//Instance methods.
- (id) initWithPrimaryKey:(NSInteger)pk;

@end



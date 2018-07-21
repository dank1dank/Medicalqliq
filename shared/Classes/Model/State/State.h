//
//  State.h
//  CCiPhoneApp
//
//  Created by Ravi Ada on 5/23/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface State : NSObject {

    NSString *stateCode;
    NSString *stateName;
    
	//Intrnal variables to keep track of the state of the object.
	BOOL isDirty;
	BOOL isDetailViewHydrated;
    
}
@property (nonatomic, retain) NSString *stateCode;
@property (nonatomic, retain) NSString *stateName;

@property (nonatomic, readwrite) BOOL isDirty;
@property (nonatomic, readwrite) BOOL isDetailViewHydrated;

//Static methods.
+ (NSMutableArray *) getAllStatesToDisplay;

@end
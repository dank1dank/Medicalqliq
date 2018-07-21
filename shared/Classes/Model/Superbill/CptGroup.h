//
//  Superbill.h
//  CCiPhoneApp
//
//  Created by Ravi Ada on 4/18/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CptGroup : NSObject {
    NSString *Name;
	NSArray *cptCodes;
	NSArray *modifiers;
}
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSArray *cptCodes;
@property (nonatomic, retain) NSArray *modifiers;

@end

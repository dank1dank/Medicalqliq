//
//  Superbill.m
//  CCiPhoneApp
//
//  Created by Ravi Ada on 4/18/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import "CptGroup.h"

@implementation CptGroup
@synthesize name,cptCodes,modifiers;

- (void) dealloc {
	[name release];
	[cptCodes release];
	[modifiers release];
	[super dealloc];
}
@end

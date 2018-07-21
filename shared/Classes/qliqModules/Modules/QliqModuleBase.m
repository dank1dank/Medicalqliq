//
//  QliqModuleBase.m
//  qliq
//
//  Created by Paul Bar on 1/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QliqModuleBase.h"
#import "QliqSipMessage.h"
#import "QliqModuleBase+Protected.h"

@implementation QliqModuleBase

@synthesize name;
@synthesize presented;
@synthesize active;

//------------------------------------------------

- (void)dealloc {
    
    [name release];
    [super  dealloc];
}

//------------------------------------------------

- (BOOL)processSipMessage:(QliqSipMessage *)message {
    return [self handleSipMessage:message];
}

//------------------------------------------------

- (UIImage *)moduleLogo {
    return nil;
}

//------------------------------------------------

#pragma mark - Protected

//------------------------------------------------

- (BOOL)handleSipMessage:(QliqSipMessage *)message
{
    return NO;
}

//------------------------------------------------

-(void) onSipRegistrationStatusChanged:(BOOL)registered status:(NSInteger)status isReRegistration:(BOOL)reregistration
{
    
}

//------------------------------------------------

@end

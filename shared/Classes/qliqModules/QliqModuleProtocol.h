//
//  QliqModuleProtocol.h
//  qliq
//
//  Created by Paul Bar on 1/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class QliqSipMessage;

@protocol QliqModuleProtocol <NSObject>

@property (nonatomic, assign) BOOL active;
@property (nonatomic, assign) BOOL presented;

@property (nonatomic, retain) NSString *name;

// Returns true if the message shouldn't by passed to other modules.
- (BOOL)processSipMessage:(QliqSipMessage *)message;

- (void)onSipRegistrationStatusChanged:(BOOL)registered status:(NSInteger)status isReRegistration:(BOOL)reregistration;

- (UIImage *)moduleLogo;

@end

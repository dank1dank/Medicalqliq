//
//  QliqModulesController.h
//  qliq
//
//  Created by Paul Bar on 1/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ApplicationsSubscription;
@protocol QliqModuleProtocol;

@interface QliqModulesController : NSObject

+ (QliqModulesController *)sharedInstance;

- (void)activateModulesFromSubscriprions:(ApplicationsSubscription *)subscription;

- (id<QliqModuleProtocol>)getModuleWithName:(NSString *)moduleName;
- (id<QliqModuleProtocol>)getPresentedModule;

- (void)setPresentedModuleWithName:(NSString *)moduleName;

@end

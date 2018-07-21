//
//  QliqModulesController.m
//  qliq
//
//  Created by Paul Bar on 1/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QliqModulesController.h"

#import "ApplicationsSubscription.h"
#import "UserSessionService.h"
#import "QliqConnectModule.h"
#import "QliqSip.h"
#import "QliqSipMessage.h"

@interface QliqModulesController()

@property (nonatomic, strong) NSMutableArray *modules;

@end

static QliqModulesController *instance = nil;

@implementation QliqModulesController

#pragma mark - Life Cycle

- (void)dealloc {

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.modules = nil;
}

+ (QliqModulesController *)sharedInstance
{
    static QliqModulesController *instance = nil;
    if (instance == nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            instance = [[QliqModulesController alloc] init];
        });
    }
    return instance;
}

- (id)init
{
    self = [super init];
    if(self)
    {
        [[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(onSipMessageReceived:)
													 name: SIPMessageNotification 
												   object: nil];
        
        [[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(onSipRegistrationStatusChanged:)
													 name: SIPRegistrationStatusNotification 
												   object: nil];
        
        
        self.modules = [[NSMutableArray alloc] init];
    }
    return self;
}

#pragma mark - Public

- (void)activateModulesFromSubscriprions:(ApplicationsSubscription *)subscription {
    
    [self deactivateAllModules];
        
    //qliqConnect is always active
    QliqConnectModule *connectModule = [[QliqConnectModule alloc] init];
    
    int period = [[[UserSessionService currentUserSession] userSettings] securitySettings].keepMessageFor;
    
    [connectModule setMessageRetentionPeriod:period];
   
    [connectModule deleteOldMessages];
    
    [self.modules addObject:connectModule];

    [connectModule setActive: YES];
}

- (id<QliqModuleProtocol>) getModuleWithName:(NSString *)moduleName
{
    @synchronized(self) {
        for (id<QliqModuleProtocol> module in self.modules)
        {
            if([[module name] isEqualToString:moduleName])
                return module;
        }
    }
    
    return nil;
}

- (id<QliqModuleProtocol>)getPresentedModule
{
    @synchronized(self) {
        
        for (id<QliqModuleProtocol> module in self.modules)
        {
            if([module presented])
                return module;
        }
    }
    
    return nil;
}

- (void)setPresentedModuleWithName:(NSString *)moduleName
{
    @synchronized(self) {
        for(id<QliqModuleProtocol> module in self.modules)
        {
            [module setPresented:[[module name] isEqualToString:moduleName]];
        }
    }
}

#pragma mark - Private

- (void)deactivateAllModules
{
    @synchronized(self) {
        for(id<QliqModuleProtocol> module in self.modules)
        {
            [module setActive:NO];
        }
        [self.modules removeAllObjects];
    }
}

- (void)onSipMessageReceived:(NSNotification *)notification
{
    QliqSipMessage *message = [QliqSipMessage messageWithNotification:notification];
    if (message) {
        @synchronized(self) {
            for (id<QliqModuleProtocol> module in self.modules)
            {
                if ([module processSipMessage:message]) {
                    break;
                }
            }
        }
    }
}

- (void)onSipRegistrationStatusChanged:(NSNotification *)notification
{
    BOOL registered = [[[notification userInfo] objectForKey:@"isRegistered"] boolValue];
    BOOL isReRegistration = [[[notification userInfo] objectForKey:@"isReRegistration"] boolValue];
    int status = [[[notification userInfo] objectForKey:@"isRegistered"] intValue];
  
    @synchronized(self) {
        for(id<QliqModuleProtocol> module in self.modules)
        {
            [module onSipRegistrationStatusChanged:registered status:status isReRegistration:isReRegistration];
        }
    }
}

@end

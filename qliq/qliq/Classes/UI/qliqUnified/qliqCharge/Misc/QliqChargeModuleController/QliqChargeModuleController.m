//
//  QliqChargeModuleController.m
//  qliq
//
//  Created by Paul Bar on 3/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QliqChargeModuleController.h"
#import "QliqBaseViewController.h"
#import "QliqConnectTabView.h"
#import "ConversationListViewController.h"
#import "QliqControllerWithTable.h"
#import "QliqChargeTabView.h"
#import "EncountersForDateViewController.h"
#import "FacilitiesViewController.h"
#import "ProvidersViewController.h"
#import "CommunicationsModuleController.h"
#import "AppDelegate.h"
@interface QliqChargeModuleController()

-(UIViewController*) controllerForTabAtIndex:(NSInteger)index;
-(void) popToThisController;

@property (nonatomic, retain) CommunicationsModuleController *qliqConnectModuleController;

@end

@implementation QliqChargeModuleController

@synthesize navigationController;
@synthesize backButtonTitle;
@synthesize tabView;
@synthesize qliqConnectModuleController;


-(id) init
{
    self = [super init];
    if(self)
    {
        self.tabView = [[[QliqChargeTabView alloc] init]autorelease];
        self.tabView.frame = CGRectMake(0.0,0.0, 0.0, 56.0);
        self.qliqConnectModuleController = //[[CommunicationsModuleController alloc] init];
        ((AppDelegate *)[[UIApplication sharedApplication] delegate]).qliqConnectController;
    }
    return self;
}


- (void)dealloc
{
    [self.qliqConnectModuleController release];
    [self.tabView release];
    [self.backButtonTitle release];
    [self.navigationController release];
    [super dealloc];
}

-(void) startChargeModuleWithTab:(NSInteger)tabIndex
{
    rootViewController = self.navigationController.topViewController;
    id<QliqTabViewProtocol> _tabView = (id<QliqTabViewProtocol>)self.tabView;
    _tabView.delegate = nil;
    [_tabView setSelectedButtonIndex:tabIndex];
    UIViewController *ctrl = [self controllerForTabAtIndex:tabIndex];
    BOOL animated = YES;
    [self.navigationController pushViewController:ctrl animated:animated];
    _tabView.delegate = self;
}

#pragma mark -
#pragma mark Private


-(void) popToThisController
{
    if (self.navigationController == nil)
    {
        return;
    }
    while(self.navigationController.topViewController != rootViewController)
    {
        [self.navigationController popViewControllerAnimated:NO];
    }
}

-(UIViewController*) controllerForTabAtIndex:(NSInteger)index
{
    switch (index)
    {
        case 0:
        {
            EncountersForDateViewController *rez = [[EncountersForDateViewController alloc] init];
            rez.tabView = self.tabView;
            return [rez autorelease];
        }
        case 1:
        {
            FacilitiesViewController *rez = [[FacilitiesViewController alloc] init];
            rez.tabView = self.tabView;
            return [rez autorelease];
        }
        case 2:
        {
            ProvidersViewController *rez = [[ProvidersViewController alloc] init];
            rez.tabView = self.tabView;
            return [rez autorelease];
        }
        default:
        {
            QliqControllerWithTable *vc = [[QliqControllerWithTable alloc] init];
            vc.tabView = self.tabView;
            vc.previousControllerTitle = self.backButtonTitle;
            return [vc autorelease];
        }
    }
}

#pragma mark -
#pragma mark QliqTabViewDelegate

-(void) qliqTabView:(id<QliqTabViewProtocol>)tabView didSelectItemAtIndex:(NSInteger)itemIndex
{
    if(itemIndex < 3)
    {
        UIViewController *newController = [self controllerForTabAtIndex:itemIndex];
        [self popToThisController];
        [self.navigationController pushViewController:newController animated:NO];
    }
    else if(itemIndex == 4)
    {
        self.qliqConnectModuleController.navigationController = self.navigationController;
        self.qliqConnectModuleController.backButtonTitle = @"Close chat";
        [self.qliqConnectModuleController startCommunicationModuleWithTab:1];
    }
}

@end

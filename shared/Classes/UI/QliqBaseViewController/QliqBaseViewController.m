//
//  QliqBaseViewController.m
//  CCiPhoneApp
//
//  Created by Marcin Zbijowski on 16/05/2011.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

//TODO: Cleanup headers
#import "QliqBaseViewController.h"


#import "QliqSip.h"
#import "Helper.h"
#import "AppDelegateProtocol.h"
#import "QliqTabBarController.h"
#import <QuartzCore/QuartzCore.h>
#import "ChatMessage.h"
#import "AppDelegate.h"
#import "QliqConnectModule.h"
#import "CustomBackButtonView.h"
#import "QliqModulesController.h"
//#import "SettingsTableViewController.h"
#import "ResetPasswordController.h"

@interface QliqBaseViewController()

@property (nonatomic, retain) CustomBackButtonView *backButtonView;

- (void) onSipRegistrationNotification:(NSNotification *)notification;
- (void) updateNetworkIndicator;
- (void) reacabilityChanged:(NSNotification*)notification;

@end

@implementation QliqBaseViewController

@synthesize shouldHidesToolbar;
@synthesize tabbarItems;
@synthesize controllerName;

@synthesize previousControllerTitle;
@synthesize backButtonView;


- (BOOL)hidesBottomBarWhenPushed{
    
    BOOL hides = self.shouldHidesToolbar;
    
    if (self.navigationController.visibleViewController != self) {
        hides = NO;
    }
    
    return hides;
}
- (NSArray *)toolbarItems{
    if (self.tabbarItems)
        return [QliqTabbarController tabbarItemsWithSeparatorsFromItems:self.tabbarItems];
    else {
        return [super toolbarItems];
    }
}


- (QliqNavigationController *)navigationController{
    return (QliqNavigationController *)[super navigationController];
}


- (id)init
{
    self = [super init];
    if (self != nil) {
        self.navigationItem.hidesBackButton = YES;
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.shouldHidesToolbar = YES;
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - View lifecycle


- (void)viewDidLoad
{
    [super viewDidLoad];
    if (self.previousControllerTitle != nil)
    {
        [self setCustomBackItemWithTitle:self.previousControllerTitle];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(reacabilityChanged:) name: QliqReachabilityChangedNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onSipRegistrationNotification:) name: SIPRegistrationStatusNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onPresenceChangeNotification:) name: PresenceChangeStatusNotification object: nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    
    [super viewWillAppear:animated];
    [self setNavigationBarBackgroundImage];
    
    [self setCustomBackItemWithTitle:self.previousControllerTitle];

    
    [self updateNetworkIndicator];
    [self updatePresence];
}

- (void)removeNotificationObserver
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self setNavigationBarBackgroundImage];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
    
}
- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)presentSettings:(id)sender
{
    /*
    SettingsTableViewController *tempController = [[SettingsTableViewController alloc] init];
    tempController.previousControllerTitle = NSLocalizedString(@"Back", @"Back");
    [self.navigationController pushViewController:tempController animated:YES];
     */
}

AUTOROTATE_METHOD

- (void) setBackItemWithTitle:(NSString *)title
{
    CGRect buttonFrame = CGRectMake(0, 5, 40, 40);
    QliqButton *backButton = [[QliqButton alloc] initWithFrame:buttonFrame style:QliqButtonStyleNavigationBack];
    [backButton setTitle:title forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    [backButton sizeToFit];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
}

- (void)setCustomBackItemWithTitle:(NSString *)title
{    
    CustomBackButtonView *backView = [[CustomBackButtonView alloc] initWithFrame:CGRectMake(0, 0, 320 / 2.0, 40)];
	backView.accessibilityLabel = @"CustomBackNavButton";
   
    if([title length] > 0){
        [backView addTarget:self withAction:@selector(goBack)];
        [backView setTitle:title];
    }
    else{
        UIImage *logoImage = [[[QliqModulesController sharedInstance] getPresentedModule] moduleLogo];
        if(!logoImage) logoImage = [UIImage imageNamed:@"qliq_logo"];
        [backView setImage:logoImage];
        [backView addTarget:self withAction:@selector(presentSettings:)];
    }

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backView];
	self.navigationItem.leftBarButtonItem.accessibilityLabel= @"CustomBackButton";
    self.navigationItem.leftBarButtonItem.width = 170;
	
    self.backButtonView = backView;
    
    [self updateNetworkIndicator];
}

- (void)goBack
{
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - Notiifcations

- (void) onPresenceChangeNotification:(NSNotification *)notification
{
    if ([notification.userInfo[@"isForMyself"] boolValue] == YES) {
        [self updatePresence];
    }
}

- (void) onSipRegistrationNotification:(NSNotification *)notification
{
    [self updateNetworkIndicator];
}


- (void) reacabilityChanged:(NSNotification *)notification
{
    [self updateNetworkIndicator];
}

#pragma mark - Updating back button item

- (void) updateNetworkIndicator
{
    BOOL userOnlineAndRegistered = [appDelegate isReachable];// & ([QliqSip sharedQliqSip].lastRegistrationResponseCode == 200);    //was commented because
    if(userOnlineAndRegistered)
    {
        self.backButtonView.networkIndicatorState = NetworkIndicatorStateNone;
    }
    else
    {
        self.backButtonView.networkIndicatorState = NetworkIndicatorStateUserOffline;
    }
    //[self checkInternetConnectionInBackground];
}

#pragma mark Reachability Methods
// Continuous Check For Internet Connetion In Background
- (void)checkInternetConnectionInBackground
{
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(reachabilityChanged:) name: kReachabilityChangedNotification object: nil];
    
    internetReach = [Reachability reachabilityForInternetConnection] ;
	[internetReach startNotifier];
	[self updateInterfaceWithReachability: internetReach];
}

//Called by Reachability whenever status changes.
- (void)reachabilityChanged: (NSNotification* )note
{
	Reachability* curReach = [note object];
	NSParameterAssert([curReach isKindOfClass: [Reachability class]]);
	[self updateInterfaceWithReachability: curReach];
}

- (void)updateInterfaceWithReachability: (Reachability*) curReach
{
    if(curReach == hostReach)
    {
		[self configureInternetConnection:curReach];
    }
	if(curReach == internetReach)
    {
		[self configureInternetConnection:curReach];
	}
    if(curReach == wifiReach)
    {
		[self configureInternetConnection:curReach];
	}
}

- (void)configureInternetConnection:(Reachability*) curReach
{
    
    NetworkStatus netStatus = [curReach currentReachabilityStatus];
    switch (netStatus)
    {
        case NotReachable:
        {
            self.backButtonView.networkIndicatorState = NetworkIndicatorStateUserOffline;
            break;
        }
            
        case ReachableViaWWAN:
        {
            self.backButtonView.networkIndicatorState = NetworkIndicatorStateNone;
            break;
        }
            
        case ReachableViaWiFi:
        {
            self.backButtonView.networkIndicatorState = NetworkIndicatorStateNone;
            break;
        }
    }
}

- (void) updatePresence
{
    [self.backButtonView updatePresence];
}



@end

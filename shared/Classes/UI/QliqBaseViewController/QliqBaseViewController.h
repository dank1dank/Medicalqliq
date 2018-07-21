//
//  QliqBaseViewController.h
//  CCiPhoneApp
//
//  Created by Marcin Zbijowski on 16/05/2011.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "QliqNavigationController.h"
#import "QliqTabbarController.h"

#import "UIViewController+Additions.h"


#import "Reachability.h"

@class Reachability;
@interface QliqBaseViewController : UIViewController{
    Reachability* hostReach;
    Reachability* internetReach;
    Reachability* wifiReach;
    
}
@property (nonatomic, retain) NSString *previousControllerTitle;

@property (nonatomic) BOOL shouldHidesToolbar;

@property (nonatomic, strong) NSArray * tabbarItems;

@property (nonatomic, strong, readonly) QliqNavigationController * navigationController;

@property (nonatomic, strong) NSString * controllerName; /* Used by QliqNavigationController to identify controllers in switching */

- (void) setBackItemWithTitle:(NSString *)title;
- (void) setCustomBackItemWithTitle:(NSString *)title;
- (void) updatePresence;

@end

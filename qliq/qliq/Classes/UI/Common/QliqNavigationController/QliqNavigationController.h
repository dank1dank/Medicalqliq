//
//  QliqNavigationController.h
//  qliq
//
//  Created by Aleksey Garbarev on 20.06.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QliqTabbarController.h"

#define AUTOROTATE_METHOD \
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{ \
    return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown; \
}


@interface QliqNavigationController : UINavigationController


- (id) initWithRootViewController:(UIViewController *)_rootViewController andToolbarHidden:(BOOL) toolbarHidden;

- (void) setTabbarController: (id <QliqTabbarProtocol>) tabbar;

- (void) switchToViewControllerByClass:(Class) _class animated:(BOOL) _animated;
- (void) switchToViewControllerByClass:(Class) _class animated:(BOOL) _animated initializationBlock:(UIViewController *(^)(void))initBlock;
- (void) switchToViewControllerByClass:(Class) _class animated:(BOOL) _animated initializationBlock:(UIViewController *(^)(void))initBlock additionSetups:(void(^)(UIViewController * viewController))setupsBlock;
- (void) switchToViewControllerByClass:(Class) _class andTitle:(NSString *) title animated:(BOOL) _animated initializationBlock:(UIViewController *(^)(void))initBlock additionSetups:(void(^)(UIViewController *))setupsBlock;

@end

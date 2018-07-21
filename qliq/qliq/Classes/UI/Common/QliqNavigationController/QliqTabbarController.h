//
//  QliqTabbarItems.h
//  qliq
//
//  Created by Aleksey Garbarev on 20.06.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QliqBarButtonItem.h"

//Button Identifiers
extern NSString *QliqBarButtonIdRecentChat;
extern NSString *QliqBarButtonIdFavorites;
extern NSString *QliqBarButtonIdContacts;
extern NSString *QliqBarButtonIdMedia;
extern NSString *QliqBarButtonIdSettings;


@class QliqNavigationController, QliqTabbarController;
@protocol QliqTabbarProtocol <NSObject>

- (void)    qliqNavigationController:(QliqNavigationController *) _navController didChangeVisibleController:(UIViewController *) viewController;
- (CGFloat) heightForTabbarInNavigationController:(QliqNavigationController *) _navController;

@end

@interface QliqTabbarController : NSObject <QliqTabbarProtocol>

- (void) setNavigationController:(QliqNavigationController *) _navController;

+ (QliqTabbarController *) currentController;

- (NSArray *) communicationModuleButtons;

+ (NSArray *) tabbarItemsWithSeparatorsFromItems:(NSArray *) toolbar_items;

+ (UIBarButtonItem *) separator;

- (Class) classForIdentifier:(NSString *) identifier;
@end

//
//  QliqChargeModuleController.h
//  qliq
//
//  Created by Paul Bar on 3/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QliqTabBarProtocols.h"

@interface QliqChargeModuleController : NSObject <QliqTabViewDelegate>
{
    UIViewController *rootViewController;
}

-(void) startChargeModuleWithTab:(NSInteger)tabIndex;

@property (nonatomic, retain) UIView *tabView;
@property (nonatomic, retain) UINavigationController *navigationController;
@property (nonatomic, retain) NSString *backButtonTitle;

@end
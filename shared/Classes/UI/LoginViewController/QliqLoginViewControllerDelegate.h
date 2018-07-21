//
//  QliqLoginViewControllerDelegate.h
//  qliqConnect
//
//  Created by Paul Bar on 11/26/11.
//  Copyright (c) 2011 Al Digit. All rights reserved.
//

@protocol QliqLoginViewControllerDelegate <NSObject>

- (BOOL) shouldAppearStartView;
-(void) userDidLogin;

@end

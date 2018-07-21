//
//  LoginView.h
//  qliq
//
//  Created by Paul Bar on 2/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginView : UIView
{
    UIView *headerView;
    UIView *contentView;
}

@property (nonatomic, retain) UIView *headerView;
@property (nonatomic, readonly) UIView *contentView;

@end

//
//  LoginViewController.h
//  qliq
//
//  Created by Valerii Lider on 5/27/14.
//
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, StartLoginWithPassword) {
    StartLoginWithPasswordNone,
    StartLoginWithPasswordWithCreateAccount,
    StartLoginWithPasswordWithForgotPassword
};

@interface LoginWithPasswordViewController : UIViewController

@property (nonatomic, assign) StartLoginWithPassword startType;

@end

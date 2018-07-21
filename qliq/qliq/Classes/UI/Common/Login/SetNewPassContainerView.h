//
//  SetNewPassContainerView.h
//  qliq
//
//  Created by Valerii Lider on 7/23/14.
//
//

#import <UIKit/UIKit.h>

@interface SetNewPassContainerView : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passTextField;

@property (weak, nonatomic) IBOutlet UIButton *signInButton;
@property (weak, nonatomic) IBOutlet UIButton *createAccountButton;
@property (weak, nonatomic) IBOutlet UIButton *forgotPasswordButton;

@end

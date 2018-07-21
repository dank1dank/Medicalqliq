//
//  SetNewPinContainerView.h
//  qliq
//
//  Created by Valerii Lider on 7/22/14.
//
//

#import <UIKit/UIKit.h>

@interface SetNewPinContainerView : UIViewController

@property (nonatomic, strong) NSString *pin;

@property (weak, nonatomic) IBOutlet UILabel *enterPinLabel;
@property (weak, nonatomic) IBOutlet UIButton *switchButton;
@property (weak, nonatomic) IBOutlet UIView *backButtonView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;

@property (weak, nonatomic) IBOutlet UIImageView *qliqLogoImageView;
- (void)resetPinView;

@end

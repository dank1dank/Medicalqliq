//
//  WipedContainerView.m
//  qliq
//
//  Created by Valerii Lider on 5/27/14.
//
//

#import "WipedContainerView.h"

@interface WipedContainerView ()

@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;

@property (weak, nonatomic) IBOutlet UILabel *qliqSoftLabel;


@end

@implementation WipedContainerView

- (void)configureDefaultText {
    
    self.descriptionLabel.text = QliqLocalizedString(@"2301-TitleWipedDescription");
    
    [self.continueToLogInButton setTitle:QliqLocalizedString(@"61-ButtonContinueLogIn") forState:UIControlStateNormal];
    
    [self.visitWebsiteButton setTitle:QliqLocalizedString(@"60-ButtonVisitWebsite") forState:UIControlStateNormal];
    
    self.qliqSoftLabel.text = QliqLocalizedString(@"2300-TitleQliqSoftReserved");
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureDefaultText];
}

@end

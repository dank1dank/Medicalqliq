//
//  AttemptsLockContainerView.m
//  qliq
//
//  Created by Valerii Lider on 5/27/14.
//
//

#import "AttemptsLockContainerView.h"

@interface AttemptsLockContainerView ()


@property (weak, nonatomic) IBOutlet UILabel *qliqSoftLabel;

@end

@implementation AttemptsLockContainerView

- (void)configureDefaultText {
    
    self.attemptsLockMessageLabel.text = QliqLocalizedString(@"");
    self.attemptsLockMessageLabel.minimumScaleFactor = 10.f / self.attemptsLockMessageLabel.font.pointSize;
    self.attemptsLockMessageLabel.adjustsFontSizeToFitWidth = YES;

    [self.unlockButton setTitle:QliqLocalizedString(@"59-ButtonUnlock") forState:UIControlStateNormal];
    
    [self.visitWebsiteButton setTitle:QliqLocalizedString(@"60-ButtonVisitWebsite") forState:UIControlStateNormal];
    
    self.qliqSoftLabel.text = QliqLocalizedString(@"2300-TitleQliqSoftReserved");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureDefaultText];
}

@end
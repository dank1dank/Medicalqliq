//
//  LockContainerView.m
//  qliq
//
//  Created by Valerii Lider on 5/27/14.
//
//

#import "LockContainerView.h"

@interface LockContainerView  ()

@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;

@property (weak, nonatomic) IBOutlet UILabel *qliqSoftLabel;

@end

@implementation LockContainerView

- (void)configureDefaultText {
    
    self.descriptionLabel.text = QliqLocalizedString(@"2199-TitleLockDescription");
    
    [self.unlockButton setTitle:QliqLocalizedString(@"59-ButtonUnlock") forState:UIControlStateNormal];
    
    [self.visitWebsiteButton setTitle:QliqLocalizedString(@"60-ButtonVisitWebsite") forState:UIControlStateNormal];
    
    self.qliqSoftLabel.text = QliqLocalizedString(@"2300-TitleQliqSoftReserved");
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureDefaultText];
}


@end


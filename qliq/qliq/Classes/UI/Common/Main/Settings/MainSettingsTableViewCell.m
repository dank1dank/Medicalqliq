//
//  MainSettingsTableViewCell.m
//  qliq
//
//  Created by Valeriy Lider on 17.11.14.
//
//

#import "MainSettingsTableViewCell.h"

@interface MainSettingsTableViewCell ()

@property (weak, nonatomic) IBOutlet UIButton *syncButton;

@property (weak, nonatomic) IBOutlet UIButton *logoutButton;

@end

@implementation MainSettingsTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    [self prepareForReuse];
}

- (void)prepareForReuse {
    [super prepareForReuse];
   
    if (self.syncButton) {
        [self.syncButton setTitle:QliqLocalizedString(@"101-ButtonSyncContacts") forState:UIControlStateNormal];
    }
    if (self.logoutButton) {
        [self.logoutButton setTitle:QliqLocalizedString(@"102-ButtonLogout") forState:UIControlStateNormal];
    }
    
    
    self.nameOptionLabel.textColor = RGBa(3, 120, 173, 1);
    self.nameOptionLabel.text = @"";
    
    self.switchOptionMode.hidden = YES;
    self.arrowImageView.hidden = YES;
    self.textField.hidden = YES;
}

#pragma mark - IBActions

- (IBAction)onSwitchMode:(id)sender {

}

- (IBAction)onSyncContacts:(id)sender {
    
    if ([self.delegate respondsToSelector:@selector(syncContactsWasPressed)]) {
        [self.delegate syncContactsWasPressed];
    }
}

- (IBAction)onLogOut:(id)sender {
    
    if ([self.delegate respondsToSelector:@selector(logOutWasPressed)]) {
        [self.delegate logOutWasPressed];
    }
}

@end

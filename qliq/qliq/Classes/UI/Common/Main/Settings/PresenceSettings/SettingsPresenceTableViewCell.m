//
//  SettingsPresenceTableViewCell.m
//  qliq
//
//  Created by Valeriy Lider on 18.12.14.
//
//

#import "SettingsPresenceTableViewCell.h"

@implementation SettingsPresenceTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)onJoinGroup:(id)sender {
    
    if ([self.delegate respondsToSelector:@selector(joinGroupWasPressed)]) {
        [self.delegate joinGroupWasPressed];
    }
}

- (IBAction)onLeaveGroup:(id)sender {
    
    if ([self.delegate respondsToSelector:@selector(leaveGroupWasPressed)]) {
        [self.delegate leaveGroupWasPressed];
    }
}

- (void)dealloc {
    
    self.presenceEditView = nil;
    self.titleLabel = nil;
    self.checkBoxButton = nil;
    self.leftButton = nil;
    self.rightButton = nil;
}

@end

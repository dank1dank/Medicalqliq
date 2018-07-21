//
//  SettingsSecurityTableViewCell.m
//  qliq
//
//  Created by Valeriy Lider on 20.11.14.
//
//

#import "SettingsSecurityTableViewCell.h"

@implementation SettingsSecurityTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    [self prepareForReuse];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.nameOptionLabel.text = @"";
    self.descriptionLabel.text = @"";
    self.switchOption.hidden = YES;
    self.arrowImageView.hidden = YES;
    
    if (self.switchOption) {
        for (id target in [self.switchOption allTargets]) {
            [self.switchOption removeTarget:target action:nil forControlEvents:UIControlEventValueChanged];
        }
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end

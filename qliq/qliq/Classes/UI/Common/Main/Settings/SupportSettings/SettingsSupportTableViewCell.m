//
//  SettingsSupportTableViewCell.m
//  qliq
//
//  Created by Valeriy Lider on 24.11.14.
//
//

#import "SettingsSupportTableViewCell.h"

@implementation SettingsSupportTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self prepareForReuse];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.titleLabel.text = @"";
    
    self.descriptionLabel.text = @"";
    
    self.switchOption.hidden = YES;
    
    self.arrowImage.hidden = YES;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - Public

- (void)configureCellWithItem:(SettingsItem *)item
{
    self.titleLabel.text = item.title;
    self.descriptionLabel.text = item.info;
}

#pragma mark - Actions

- (IBAction)onConnection:(id)sender {
    
    if ([self.delegate respondsToSelector:@selector(closeConnectionWasPressed)]) {
        [self.delegate closeConnectionWasPressed];
    }
}

@end

//
//  SettingsTableViewCell.m
//  qliq
//
//  Created by Valerii Lider on 29/09/15.
//
//

#import "DefaultSettingsTableViewCell.h"

@implementation DefaultSettingsTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self prepareForReuse];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.titleLabel.text = @"";
    self.titleLabel.hidden = YES;
    
    self.descriptionLabel.text = @"";
    self.descriptionLabel.hidden = YES;
    
    self.arrowImageView.hidden = YES;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - Public

- (void)configureCellWithTitle:(NSString *)title
               withDescription:(NSString *)description
                     withArrow:(BOOL)showArrow
{
    if (title.length) {
        self.titleLabel.hidden = NO;
        self.titleLabel.text = title;
    }
    
    if (description.length) {
        self.descriptionLabel.hidden = NO;
        self.descriptionLabel.text = description;
    }
    
    self.arrowImageView.hidden = !showArrow;
}


@end

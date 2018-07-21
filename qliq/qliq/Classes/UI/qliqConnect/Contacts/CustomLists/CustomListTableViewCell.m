//
//  CustomListTableViewCell.m
//  qliq
//
//  Created by Vita on 7/18/12.
//  Copyright (c) 2012 Al Digit. All rights reserved.
//

#import "CustomListTableViewCell.h"

@implementation CustomListTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)setChecked:(BOOL)checked
{
    _checked = checked;
    
    UIImage * image = [UIImage imageNamed:checked ? @"ConversationChecked" : @"ConversationUnChecked"];
    [self.checkmarkButton setImage:image forState:UIControlStateNormal];
}

- (void)setListTitle:(NSString*)listTitle {
    self.titleLabel.text = listTitle;
}

- (void)checkButtonTapped:(id)sender 
{
    if ([self.delegate respondsToSelector:@selector(checkedButtonPressed:)]) {
        [self.delegate checkedButtonPressed:self];
    }
}

@end

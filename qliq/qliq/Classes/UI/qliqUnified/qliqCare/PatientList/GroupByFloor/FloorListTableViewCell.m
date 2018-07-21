//
//  FloorListTableViewCell.m
//  CCiPhoneApp
//
//  Created by Paul Bar on 11/16/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import "FloorListTableViewCell.h"

@implementation FloorListTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) 
    {
        // Initialization code
        self.backgroundView = [[[UIView alloc] init] autorelease];
        self.backgroundView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"header-row-pattern.png"]];
        self.textLabel.backgroundColor = [UIColor clearColor];
        self.textLabel.textColor = [UIColor whiteColor];
    }
    return self;
}

-(void) layoutSubviews
{
    [super layoutSubviews];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end

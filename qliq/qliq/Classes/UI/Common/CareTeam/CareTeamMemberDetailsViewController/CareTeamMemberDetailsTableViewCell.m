//
//  CareTeamMemberDetailsTableViewCell.m
//  CCiPhoneApp
//
//  Created by Paul Bar on 11/18/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import "CareTeamMemberDetailsTableViewCell.h"

#define TEXT_LABEL_WIDTH 75.0
#define SPACES_BETWEEN_LABELS 10.0

@implementation CareTeamMemberDetailsTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        // Initialization code
        self.backgroundView = [[[UIView alloc] init] autorelease];
        self.backgroundView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"CareTeamMemberDetailsTableViewCell_bg.png"]];
        
        self.textLabel.backgroundColor = [UIColor clearColor];
        self.textLabel.textColor = [UIColor grayColor];
        self.textLabel.textAlignment = UITextAlignmentRight;
        self.textLabel.font = [UIFont boldSystemFontOfSize:14.0];
        
        self.detailTextLabel.backgroundColor = [UIColor clearColor];
        self.detailTextLabel.textColor = [UIColor blackColor];
        self.detailTextLabel.textAlignment = UITextAlignmentLeft;
        self.detailTextLabel.font = [UIFont boldSystemFontOfSize:14.0];
    }
    return self;
}

-(void) dealloc
{
    [super dealloc];
}

-(void) layoutSubviews
{
    [super layoutSubviews];
    
    CGSize labelSize = [self.textLabel.text sizeWithFont:self.textLabel.font];
    
    self.textLabel.frame = CGRectMake(0.0,
                                      roundf(self.frame.size.height / 2.0 - labelSize.height / 2.0),
                                      TEXT_LABEL_WIDTH,
                                      labelSize.height);
    
    labelSize = [self.detailTextLabel.text sizeWithFont:self.detailTextLabel.font];
    
    self.detailTextLabel.frame = CGRectMake(self.textLabel.frame.origin.x + self.textLabel.frame.size.width + SPACES_BETWEEN_LABELS,
                                      self.textLabel.frame.origin.y,
                                      self.frame.size.width - SPACES_BETWEEN_LABELS - self.textLabel.frame.size.width - 30.0,
                                      labelSize.height);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end

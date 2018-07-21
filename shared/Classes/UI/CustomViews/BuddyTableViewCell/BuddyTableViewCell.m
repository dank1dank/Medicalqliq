//
//  BuddyTableViewCell.m
//  CCiPhoneApp
//
//  Created by Marcin Zbijowski on 17/05/2011.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import "BuddyTableViewCell.h"
#import "LightGreyGradientView.h"

#define TEXT_X_POS_NOIND    10

@implementation BuddyTableViewCell




- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundView = [[[UIView alloc] init] autorelease];
        self.backgroundView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg-cell"]];
        
        self.textLabel.textColor = [UIColor colorWithWhite:0.3019 alpha:1.0f];
        self.textLabel.backgroundColor = [UIColor clearColor];
        self.textLabel.font = [UIFont boldSystemFontOfSize:13.0f];
        
    }
    return self;
}

//- (void)layoutSubviews {
//    [super layoutSubviews];
//    CGRect frame = self.textLabel.frame;
//    frame.origin = CGPointMake(TEXT_X_POS_NOIND, 3.0f);
//    frame.size.width = self.contentView.bounds.size.width - self.detailTextLabel.frame.origin.x - self.detailTextLabel.frame.size.width - 10;
//    
//    CGSize textSize = [self.textLabel.text sizeWithFont:self.textLabel.font
//                                      constrainedToSize:CGSizeMake(frame.size.width, self.contentView.bounds.size.height)
//                                          lineBreakMode:UILineBreakModeWordWrap];
//    int lines = (int)floor(textSize.height / self.textLabel.font.pointSize);
//    if (lines > 2) lines = 2;
//    self.textLabel.numberOfLines = lines;
//    frame.size.height = MIN(self.contentView.bounds.size.height - 10, textSize.height);
//    frame.origin.y = (int)((self.contentView.bounds.size.height - frame.size.height) / 2);
//    self.textLabel.frame = frame;
//    
//}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)dealloc
{
    [super dealloc];
}

@end

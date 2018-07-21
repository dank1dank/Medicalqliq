//
//  CPTTableViewCell.m
//  CCiPhoneApp
//
//  Created by Marcin Zbijowski on 04/05/2011.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import "CPTTableViewCell.h"

#define INDICATOR_X_POS     6
#define DETAIL_X_POS_IND    27
#define DETAIL_X_POS_NOIND  6
#define TEXT_X_POS_IND      75
#define TEXT_X_POS_NOIND    54

@implementation CPTTableViewCell

@synthesize opened = _opened;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundView = [[[UIView alloc] init] autorelease];
        self.backgroundView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"header-row-pattern.png"]];

        self.textLabel.textColor = [UIColor colorWithWhite:1.0 alpha:1.0f];
        self.textLabel.backgroundColor = [UIColor clearColor];
        self.textLabel.font = [UIFont boldSystemFontOfSize:14.0f];
        self.textLabel.numberOfLines = 1;
        self.detailTextLabel.textColor = [UIColor colorWithWhite:1.0 alpha:1.0f];
        self.detailTextLabel.backgroundColor = [UIColor clearColor];
        self.detailTextLabel.font = [UIFont boldSystemFontOfSize:14.0f];
        
        _openedImage = [UIImage imageNamed:@"indicator-opened"];
        _closedImage = [UIImage imageNamed:@"indicator-closed"];
        self.imageView.image = _closedImage;
        
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (self.opened) {
        self.imageView.image = _openedImage;
    }
    else {
        self.imageView.image = _closedImage;
    }
}
/*
- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect frame = self.detailTextLabel.frame;
    frame.origin = CGPointMake(DETAIL_X_POS_IND, 3.0f);
    frame.size.width = 44.0f;
    self.detailTextLabel.frame = frame;
    frame = self.textLabel.frame;
    frame.origin = CGPointMake(TEXT_X_POS_IND, 3.0f);
    frame.size.width = self.contentView.bounds.size.width - self.detailTextLabel.frame.origin.x - self.detailTextLabel.frame.size.width - 10;
    
    CGSize textSize = [self.textLabel.text sizeWithFont:self.textLabel.font
                                      constrainedToSize:CGSizeMake(frame.size.width, self.contentView.bounds.size.height)
                                          lineBreakMode:UILineBreakModeWordWrap];
    int lines = (int)floor(textSize.height / self.textLabel.font.pointSize);
    if (lines > 2) lines = 2;
    self.textLabel.numberOfLines = lines;
    frame.size.height = MIN(self.contentView.bounds.size.height - 10, textSize.height);
    self.textLabel.frame = frame;
}*/

- (void)dealloc
{
    [super dealloc];
}

- (void)setOpened:(BOOL)opened {
    if (_opened != opened) {
        _opened = opened;
        if (_opened) {
            self.imageView.image = _openedImage;
        }
        else {
            self.imageView.image = _closedImage;
        }

    }
}

@end

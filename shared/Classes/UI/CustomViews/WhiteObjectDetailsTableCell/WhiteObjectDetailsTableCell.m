//
//  WhiteObjectDetailsTableCell.m
//  CCiPhoneApp
//
//  Created by Marcin Zbijowski on 11/05/2011.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import "WhiteObjectDetailsTableCell.h"


@implementation WhiteObjectDetailsTableCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundView = [[[UIView alloc] init] autorelease];
        UIImage *bgImage = [[UIImage imageNamed:@"bg-cpt-white-sm"] stretchableImageWithLeftCapWidth:10 topCapHeight:10];
        UIImageView *bgImageView = [[UIImageView alloc] initWithImage:bgImage];
        [self.backgroundView addSubview:bgImageView];
        [bgImageView release];
        self.textLabel.textColor = [UIColor colorWithWhite:0.3019 alpha:1.0f];
        self.textLabel.backgroundColor = [UIColor clearColor];
        self.textLabel.font = [UIFont boldSystemFontOfSize:13.0f];
		self.textLabel.numberOfLines=3;
        self.detailTextLabel.textColor = [UIColor colorWithWhite:0.3019 alpha:1.0f];
        self.detailTextLabel.backgroundColor = [UIColor clearColor];
        self.detailTextLabel.font = [UIFont systemFontOfSize:13.0f];
        self.detailTextLabel.numberOfLines = 3;
//        self.backgroundView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg-cell-dark"]];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)dealloc
{
    [super dealloc];
}


-(void) layoutSubviews
{
    [super layoutSubviews];
    
    self.textLabel.frame = CGRectMake(5.0,
                                      5.0,
                                      self.frame.size.width - 10.0,
                                      self.frame.size.height - 10.0);
}

@end

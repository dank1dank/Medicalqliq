//
//  ForwardListTableViewCell.m
//  qliq
//
//  Created by Paul Bar on 1/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ForwardListTableViewCell.h"

@implementation ForwardListTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        // Initialization code
        self.backgroundView = [[[UIView alloc] init] autorelease];
        self.backgroundView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg-cell"]];
        self.contentView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg-cell"]];
        
        self.textLabel.textColor = [UIColor colorWithRed:0.0039f green:0.2549f blue:0.4353 alpha:1.0f];;
        self.textLabel.backgroundColor = [UIColor clearColor];
        
        self.detailTextLabel.textColor = [UIColor darkGrayColor];
        self.detailTextLabel.font = [UIFont systemFontOfSize:12];
        self.detailTextLabel.textAlignment = NSTextAlignmentLeft;
        self.detailTextLabel.backgroundColor = [UIColor clearColor];
        
        forwardButton = [[UIButton alloc] init];
        [forwardButton setImage:[UIImage imageNamed:@"Forward-Call-Button.png"] forState:UIControlStateNormal];
        [forwardButton setImage:[UIImage imageNamed:@"Forward-Call-Button-OnTap.png"] forState:UIControlStateHighlighted];
        [self addSubview:forwardButton];
    }
    return self;
}

-(void) dealloc
{
    [forwardButton release];
    [super dealloc];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

-(void) layoutSubviews
{
    [super layoutSubviews];
    
    forwardButton.frame = CGRectMake(self.frame.size.width - 5.0 - 75.0,
                                     0.0,
                                     75.0,
                                     50.0);
    
    CGSize size = [self.textLabel.text sizeWithAttributes:@{NSFontAttributeName : self.textLabel.font}];
    CGSize labelSize = CGSizeMake(ceilf(size.width), ceilf(size.height));
    
    self.textLabel.frame = CGRectMake(10.0,
                                      5.0,
                                      self.frame.size.width - (5.0 + 75.0 + 5.0),
                                      labelSize.height);
    
    size = [self.detailTextLabel.text sizeWithAttributes:@{NSFontAttributeName : self.detailTextLabel.font}];
    labelSize = CGSizeMake(ceilf(size.width), ceilf(size.height));
    
    self.detailTextLabel.frame = CGRectMake(10.0,
                                            5.0 + self.textLabel.frame.size.height,
                                            self.frame.size.width - (5.0 + 75.0 + 5.0),
                                            labelSize.height);
}

@end

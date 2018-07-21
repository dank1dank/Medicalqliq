//
//  DeclineMessageTableViewCell.m
//  qliq
//
//  Created by Paul Bar on 1/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DeclineMessageTableViewCell.h"

@interface DeclineMessageTableViewCell()

-(void) sendButtonPressed;

@end

@implementation DeclineMessageTableViewCell

@synthesize delegate;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        // Initialization code
        self.backgroundView = [[[UIView alloc] init] autorelease];
        self.backgroundView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg-cell"]];
        self.contentView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg-cell"]];
        
        self.textLabel.textColor = [UIColor darkGrayColor];
        self.textLabel.backgroundColor = [UIColor clearColor];
        
        sendButton = [[UIButton alloc] init];
        [sendButton setImage:[UIImage imageNamed:@"Send-Button.png"] forState:UIControlStateNormal];
        [sendButton setImage:[UIImage imageNamed:@"Send-Button-OnTap.png"] forState:UIControlStateHighlighted];
        [sendButton addTarget:self action:@selector(sendButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:sendButton];
    }
    return self;
}

-(void) dealloc
{
    [sendButton release];
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
    
    sendButton.frame = CGRectMake(self.frame.size.width - 5.0 - 55.0,
                                  5.0,
                                  55.0,
                                  40.0);
}

#pragma mark -
#pragma mark Private

-(void) sendButtonPressed
{
    [self.delegate sendButtonPressedOnCell:self];
}

@end

//
//  DeclineOptionsTableFooterView.m
//  qliq
//
//  Created by Paul Bar on 1/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DeclineOptionsTableFooterView.h"

@implementation DeclineOptionsTableFooterView

@synthesize label;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code
        label = [[UILabel alloc] init];
        label.textColor = [UIColor darkGrayColor];
        label.font = [UIFont systemFontOfSize: 12];
        label.backgroundColor = [UIColor clearColor];
        [self addSubview:label];
        
        button = [[UIButton alloc] init];
        [button setImage:[UIImage imageNamed:@"Add-Button.png"] forState:UIControlStateNormal];
        [button setImage:[UIImage imageNamed:@"Add-Button-OnTap.png"] forState:UIControlStateHighlighted];
        [self addSubview:button];
        
        self.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg-cell"]];
        
    }
    return self;
}

-(void) dealloc
{
    [button release];
    [label release];
    [super dealloc];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

-(void) layoutSubviews
{
    [super layoutSubviews];
    
    button.frame = CGRectMake(self.frame.size.width - 26.0 - 5.0,
                              (self.frame.size.height / 2.0) - 25.0,
                              26.0,
                              50.0);
    
    CGSize sizeOriginal = [label.text sizeWithAttributes:@{NSFontAttributeName : label.font}];
    CGSize size = CGSizeMake(ceilf(sizeOriginal.width), ceilf(sizeOriginal.height));
    
    label.frame = CGRectMake(10.0,
                             (self.frame.size.height / 2.0) - (size.height / 2.0),
                             self.frame.size.width - (10.0 + 5.0 + 5.0 + 26.0),
                             size.height);
    
}

@end

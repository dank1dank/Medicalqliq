//
//  LoginView.m
//  qliq
//
//  Created by Paul Bar on 2/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LoginView.h"

#define HEADER_HEIGHT 57.0

@implementation LoginView
@synthesize contentView;
@synthesize headerView = headerView_;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code
        self.backgroundColor = [UIColor colorWithRed:0.0 green:(65.0/255.0) blue:(106.0/255.0) alpha:1.0];

        contentView = [[UIView alloc] initWithFrame:frame];
        contentView.backgroundColor = [UIColor clearColor];
        contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:contentView];
        
        self.headerView = nil;
    }
    return self;
}


- (void)setHeaderView:(UIView *)_headerView
{
    [headerView_ removeFromSuperview];
    [self addSubview:_headerView];
    headerView_ = _headerView;
    
    headerView_.frame = CGRectMake(0.0, 0.0, self.frame.size.width, HEADER_HEIGHT);
}

@end

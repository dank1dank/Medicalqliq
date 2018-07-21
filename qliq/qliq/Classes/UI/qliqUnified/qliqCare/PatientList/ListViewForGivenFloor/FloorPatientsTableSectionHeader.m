//
//  FloorPatientsTableSectionHeader.m
//  CCiPhoneApp
//
//  Created by Paul Bar on 11/17/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import "FloorPatientsTableSectionHeader.h"

@implementation FloorPatientsTableSectionHeader

@synthesize sectionIndex = sectionIndex_;
@synthesize titleLabel = titleLabel_;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code
        self.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"room_title_bg.png"]];
        titleLabel_ = [[UILabel alloc] init];
        titleLabel_.textColor = [UIColor whiteColor];
        titleLabel_.font = [UIFont boldSystemFontOfSize:16.0];
        titleLabel_.backgroundColor = [UIColor clearColor];
        [self addSubview:titleLabel_];
        
    }
    return self;
}

-(void) dealloc
{
    [titleLabel_ release];
    [super dealloc];
}

-(void) layoutSubviews
{
    [super layoutSubviews];
    
    CGSize tempSize = [titleLabel_.text sizeWithFont:titleLabel_.font];
    
    titleLabel_.frame = CGRectMake(10.0,
                                   roundf((self.frame.size.height / 2.0) - (tempSize.height / 2.0)),
                                   self.frame.size.width - 10.0 * 2.0,
                                   tempSize.height);
}

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect
 {
 // Drawing code
 }
 */

@end

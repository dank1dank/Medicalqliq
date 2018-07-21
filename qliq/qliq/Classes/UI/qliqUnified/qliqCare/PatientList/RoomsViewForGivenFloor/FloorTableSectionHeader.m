//
//  FloorTableSectionHeader.m
//  CCiPhoneApp
//
//  Created by Paul Bar on 11/16/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import "FloorTableSectionHeader.h"

@interface FloorTableSectionHeader()

-(void) tapEvent:(UITapGestureRecognizer*)sender;

@end

@implementation FloorTableSectionHeader

@synthesize sectionIndex = sectionIndex_;
@synthesize titleLabel = titleLabel_;
@synthesize delegate = delegate_;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code
        //self.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"room_title_bg.png"]];
        self.backgroundColor = [UIColor colorWithRed:(52.0 / 255.0) green:(52.0 / 255.0) blue:(52.0 / 255.0) alpha:1.0];
        titleLabel_ = [[UILabel alloc] init];
        titleLabel_.textColor = [UIColor whiteColor];
        titleLabel_.font = [UIFont boldSystemFontOfSize:16.0];
        titleLabel_.backgroundColor = [UIColor clearColor];
        [self addSubview:titleLabel_];
        
        accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"white-chevron"]];
        [self addSubview:accessoryView];
        
        tapGestureRecognizer = [[UITapGestureRecognizer alloc] init];
        [tapGestureRecognizer addTarget:self action:@selector(tapEvent:)];
        [self addGestureRecognizer:tapGestureRecognizer];
    }
    return self;
}

-(void) dealloc
{
    [tapGestureRecognizer release];
    [accessoryView release];
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
    
    tempSize = accessoryView.image.size;
    accessoryView.frame = CGRectMake(self.frame.size.width - 10.0 - tempSize.width,
                                     roundf((self.frame.size.height / 2.0) - (tempSize.height / 2.0)),
                                     tempSize.width,
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

-(void) tapEvent:(UITapGestureRecognizer *)sender
{
    [self.delegate selectedSectionHeader:self];
}

@end

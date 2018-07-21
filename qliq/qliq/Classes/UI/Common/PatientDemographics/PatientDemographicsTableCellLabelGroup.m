//
//  PatientDemographicsTableCellLabelGroup.m
//  CCiPhoneApp
//
//  Created by Paul Bar on 11/18/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import "PatientDemographicsTableCellLabelGroup.h"

#define SPACE_BETWEEN_LABELS 10.0
#define KEY_WIDTH 75.0

@implementation PatientDemographicsTableCellLabelGroup

@synthesize key = key_;
@synthesize value = value_;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) 
    {
        // Initialization code
        key_ = [[UILabel alloc] init];
        key_.backgroundColor = [UIColor clearColor];
        key_.textAlignment = UITextAlignmentRight;
        key_.textColor = [UIColor grayColor];
        key_.font = [UIFont boldSystemFontOfSize:14.0];
        [self addSubview:key_];
        
        value_ = [[UILabel alloc] init];
        value_.backgroundColor = [UIColor clearColor];
        value_.textAlignment = UITextAlignmentLeft;
        value_.textColor = [UIColor blackColor];
        value_.font = [UIFont boldSystemFontOfSize:14.0];
        [self addSubview:value_];        
    }
    return self;
}

-(void) dealloc
{
    [value_ release];
    [key_ release];
    [super dealloc];
}

-(void) layoutSubviews
{
    [super layoutSubviews];
    
    CGSize labelSize = [value_.text sizeWithFont:value_.font];
    if(labelSize.height > self.frame.size.height)
    {
        labelSize.height = self.frame.size.height;
    }
    
    key_.frame = CGRectMake(0.0,
                            0.0,
                            KEY_WIDTH,
                            labelSize.height);
    
    value_.frame = CGRectMake(key_.frame.size.width + SPACE_BETWEEN_LABELS,
                              0.0,
                              self.frame.size.width - key_.frame.size.width - SPACE_BETWEEN_LABELS,
                              labelSize.height);
    
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

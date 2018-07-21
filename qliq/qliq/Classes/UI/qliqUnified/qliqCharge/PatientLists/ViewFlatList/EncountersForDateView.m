//
//  EncountersForDateView.m
//  qliq
//
//  Created by Paul Bar on 3/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EncountersForDateView.h"
#import "HorizontalPickerView.h"

#define HORISONTAL_PICKER_HEIGHT 55.0

@implementation EncountersForDateView

@synthesize horizontalPickerView = horizontalPickerView_;
@synthesize tableView = tableView_;

-(id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self)
    {        
        tableView_ = [[UITableView alloc] init];
        [self addSubview:tableView_];
    }
    return self;
}

-(void) dealloc
{
    
    [super dealloc];
}

-(void) layoutSubviews
{
    [super layoutSubviews];
    
    tableView_.frame = CGRectMake(0.0,
                                  HORISONTAL_PICKER_HEIGHT,
                                  self.frame.size.width,
                                  self.frame.size.height - HORISONTAL_PICKER_HEIGHT - self.tabView.frame.size.height);
}

#pragma mark -
#pragma mark Properties

-(void) setHorizontalPickerView:(HorizontalPickerView *)horizontalPickerView
{
    [horizontalPickerView retain];
    [horizontalPickerView_ removeFromSuperview];
    [horizontalPickerView_ release];
    horizontalPickerView_ = horizontalPickerView;
    horizontalPickerView_.backgroundColor = [UIColor clearColor];
    [self addSubview:horizontalPickerView_];
}

@end

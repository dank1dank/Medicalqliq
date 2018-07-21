//
//  FloorView.m
//  CCiPhoneApp
//
//  Created by Paul Bar on 11/16/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import "FloorView.h"

#define TAB_VIEW_HEIGHT 55.0
#define HEADER_HEIGHT 25.0

@implementation FloorView
@synthesize floorTable = floorTable_;
@synthesize tabView = tabView_;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        headerBackgroundView = [[UIView alloc] init];
        headerBackgroundView.backgroundColor = [UIColor darkGrayColor];
        [self addSubview:headerBackgroundView];
        
        floorNameLabel = [[UILabel alloc] init];
        floorNameLabel.backgroundColor = [UIColor clearColor];
        floorNameLabel.font = [UIFont boldSystemFontOfSize:12.0];
        floorNameLabel.textColor = [UIColor whiteColor];
        [self addSubview:floorNameLabel];
        
        tabView_ = [[NurseTabView alloc] initWithSelectedItem:1];
        [self addSubview:tabView_];
        
        floorTable_ = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        floorTable_.showsHorizontalScrollIndicator = NO;
        floorTable_.showsVerticalScrollIndicator = NO;
        floorTable_.backgroundColor = [UIColor colorWithWhite:0.2039f alpha:1.0f];
        floorTable_.separatorColor = [UIColor colorWithWhite:0.2039f alpha:1.0f];
        [self addSubview:floorTable_];
    }
    return self;
}

-(void) dealloc
{
    [floorNameLabel release];
    [headerBackgroundView release];
    [floorTable_ release];
    [tabView_ release];
    [super dealloc];
}

-(void) layoutSubviews
{
    [super layoutSubviews];
    headerBackgroundView.frame = CGRectMake(0.0,
                                            0.0,
                                            self.frame.size.width,
                                            HEADER_HEIGHT);
    floorNameLabel.frame = CGRectMake(headerBackgroundView.frame.origin.x + 10.0,
                                         headerBackgroundView.frame.origin.y + 5.0,
                                         headerBackgroundView.frame.size.width - 10.0 * 2.0,
                                         headerBackgroundView.frame.size.height - 5.0 * 2.0);
    
    floorTable_.frame = CGRectMake(0.0,
                                   headerBackgroundView.frame.origin.x + headerBackgroundView.frame.size.height,
                                   self.frame.size.width,
                                   self.frame.size.height - TAB_VIEW_HEIGHT - headerBackgroundView.frame.size.height);
    
    tabView_.frame = CGRectMake(0.0,
                                self.frame.size.height - TAB_VIEW_HEIGHT,
                                self.frame.size.width,
                                TAB_VIEW_HEIGHT);
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

#pragma mark -
#pragma mark Properties

-(void) setFloorName:(NSString *)floorName
{
    floorNameLabel.text = floorName;
}

-(NSString*) floorName
{
    return floorNameLabel.text;
}

@end

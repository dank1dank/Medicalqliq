//
//  FloorPatientsView.m
//  CCiPhoneApp
//
//  Created by Paul Bar on 11/17/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import "FloorPatientsView.h"
#define TAB_VIEW_HEIGHT 55.0
#define HEADER_HEIGHT 25.0

@implementation FloorPatientsView
@synthesize patientsTable = patientsTable_;
@synthesize tabView = tabView_;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) 
    {
        // Initialization code
        headerBackgroundView = [[UIView alloc] init];
        headerBackgroundView.backgroundColor = [UIColor darkGrayColor];
        [self addSubview:headerBackgroundView];
        
        hospitalNameLabel = [[UILabel alloc] init];
        hospitalNameLabel.backgroundColor = [UIColor clearColor];
        hospitalNameLabel.font = [UIFont boldSystemFontOfSize:12.0];
        hospitalNameLabel.textColor = [UIColor whiteColor];
        [self addSubview:hospitalNameLabel];
        
        tabView_ = [[NurseTabView alloc] initWithSelectedItem:0];
        [self addSubview:tabView_];
        
        patientsTable_ = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        patientsTable_.showsHorizontalScrollIndicator = NO;
        patientsTable_.showsVerticalScrollIndicator = NO;
        patientsTable_.backgroundColor = [UIColor colorWithWhite:0.2039f alpha:1.0f];
        patientsTable_.separatorColor = [UIColor colorWithWhite:0.2039f alpha:1.0f];
        [self addSubview:patientsTable_];
    }
    return self;
}

-(void) dealloc
{
    [hospitalNameLabel release];
    [headerBackgroundView release];
    [patientsTable_ release];
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
    hospitalNameLabel.frame = CGRectMake(headerBackgroundView.frame.origin.x + 10.0,
                                         headerBackgroundView.frame.origin.y + 5.0,
                                         headerBackgroundView.frame.size.width - 10.0 * 2.0,
                                         headerBackgroundView.frame.size.height - 5.0 * 2.0);
    
    patientsTable_.frame = CGRectMake(0.0,
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

-(void) setHospitalName:(NSString *)hospitalName
{
    hospitalNameLabel.text = hospitalName;
}

-(NSString*) hospitalName
{
    return hospitalNameLabel.text;
}

@end

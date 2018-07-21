//
//  CodesView.m
//  qliq
//
//  Created by Paul Bar on 3/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CodesView.h"
#import "PatientHeaderView.h"

#define HORIZONTAL_PICKER_VIEW_HEIGHT 55.0

@implementation CodesView
@synthesize tableView;
@synthesize patientHeaderView;

-(id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self)
    {
        tableView = [[UITableView alloc] init];
        [self addSubview:tableView];
        
        patientHeaderView = [[PatientHeaderView alloc] init];
        patientHeaderView.textLabel.text = @"HERE IS TEST TEXT FOR PATIENT HEADER VIEW TEXT LABEL NUMBER ONE";
        [self addSubview:patientHeaderView];
    }
    return self;
}

-(void) dealloc
{
    [patientHeaderView release];
    [tableView release];
    [super dealloc];
}

-(void) layoutSubviews
{
    [super layoutSubviews];
    
    patientHeaderView.frame = CGRectMake(0.0,
                                         0.0,
                                         self.frame.size.width,
                                         40.0);    
    tableView.frame = CGRectMake(0.0,
                                 HORIZONTAL_PICKER_VIEW_HEIGHT + patientHeaderView.frame.size.height,
                                 self.frame.size.width,
                                 self.frame.size.height);

}

@end

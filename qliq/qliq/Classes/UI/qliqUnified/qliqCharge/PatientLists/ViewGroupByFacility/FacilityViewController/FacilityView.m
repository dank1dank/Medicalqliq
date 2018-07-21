//
//  FacilityView.m
//  qliq
//
//  Created by Paul Bar on 3/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FacilityView.h"

@implementation FacilityView
@synthesize  tableView;

-(id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self)
    {
        tableView = [[UITableView alloc] init];
    }
    return self;
}

-(void) dealloc
{
    [tableView release];
    [super dealloc];
}

-(void) layoutSubviews
{
    [super layoutSubviews];
    tableView.frame = CGRectMake(0.0,
                                 0.0,
                                 self.frame.size.width,
                                 self.frame.size.height - self.tabView.frame.size.height);
}
@end

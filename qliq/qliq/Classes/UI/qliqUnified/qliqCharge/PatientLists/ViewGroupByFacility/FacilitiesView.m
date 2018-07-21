//
//  FacilitiesView.m
//  qliq
//
//  Created by Paul Bar on 3/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FacilitiesView.h"

@implementation FacilitiesView
@synthesize tableView = tableView_;

-(id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self)
    {
        self.backgroundColor = [UIColor blackColor];
        
        tableView_ = [[UITableView alloc] init];
        [self addSubview:tableView_];
    }
    return self;
}

-(void) dealloc
{
    [tableView_ release];
    [super dealloc];
}

-(void) layoutSubviews
{
    [super layoutSubviews];
    self.tableView.frame = CGRectMake(0.0,
                                      0.0,
                                      self.frame.size.width,
                                      self.frame.size.height - self.tabView.frame.size.height);
}
@end

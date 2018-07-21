//
//  BuddyListView.m
//  qliqConnect
//
//  Created by Paul Bar on 11/28/11.
//  Copyright (c) 2011 Al Digit. All rights reserved.
//

#import "BuddyListView.h"

@implementation BuddyListView

@synthesize tableView = _tblBuddyList;
@synthesize searchBar = _searchBar;

-(id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self)
    {
        //CGFloat yOffset = 0;
        /*if (self.censusObj) {
            PatientHeaderView *patientView = [self patientHeader:self.censusObj
                                                   dateOfService:_dateOfService
                                                        delegate:nil];
            [patientView setState:UIControlStateDisabled];
            yOffset = patientView.bounds.size.height;
            [self.view addSubview:patientView];
        }*/
        
        
        
        _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0.0, self.bounds.size.width, 44)];
        [_searchBar sizeToFit];
        _searchBar.barStyle = UIBarStyleDefault;
        _searchBar.tintColor = [UIColor lightGrayColor];
        [_searchBar addSubview:_toLabel];
        [self addSubview:_searchBar];
        _tblBuddyList = [[UITableView alloc] initWithFrame:CGRectMake(0,0.0, 320, self.bounds.size.height) style:UITableViewStylePlain];
        _tblBuddyList.separatorColor=[UIColor lightGrayColor];
        _tblBuddyList.separatorStyle=UITableViewCellSeparatorStyleSingleLine;
        _tblBuddyList.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        [self addSubview:_tblBuddyList];
    }
    return self;
}

-(void) dealloc
{
    [_searchBar release];
    [_tblBuddyList release];
    [super dealloc];
}

-(void) layoutSubviews
{
    [super layoutSubviews];
    
    CGSize frameSize = CGSizeMake(self.frame.size.width,
                                  self.frame.size.height - self.tabView.frame.size.height);
    
    _searchBar.frame = CGRectMake(0.0,
                                  0.0,
                                  frameSize.width,
                                  44.0);
    
    _tblBuddyList.frame = CGRectMake(0.0,
                                     _searchBar.frame.size.height,
                                     frameSize.width,
                                     frameSize.height - _searchBar.frame.size.height);
}

@end

//
//  BuddyListView.h
//  qliqConnect
//
//  Created by Paul Bar on 11/28/11.
//  Copyright (c) 2011 Al Digit. All rights reserved.
//

#import "QliqViewWithTabView.h"

@interface BuddyListView : QliqViewWithTabView
{
    UISearchBar *_searchBar;
    UILabel *_toLabel;
    UITableView *_tblBuddyList;
}

@property (nonatomic, readonly) UITableView *tableView;
@property (nonatomic, readonly) UISearchBar *searchBar;

@end

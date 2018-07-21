// Created by Developer Toy
//FacilityListView.h

#import <UIKit/UIKit.h>
#import "QliqBaseViewController.h"

@interface FacilityListView : QliqBaseViewController<UITextFieldDelegate,UITableViewDelegate,UITableViewDataSource>
{
	NSMutableArray *facilitiesArray;
	NSMutableArray *searchArray;
    UITableView *_tableView;
    UISearchBar *_searchBar;
    BOOL _isContentInset;
    BOOL _isSearching;
	
}
@end
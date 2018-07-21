// Created by Developer Toy
//ReferralListView.h

#import <UIKit/UIKit.h>
#import "QliqBaseViewController.h"

@interface ReferralListView : QliqBaseViewController<UITextFieldDelegate,UITableViewDelegate,UITableViewDataSource>
{
	NSMutableArray *rphArray;
	NSMutableArray *searchArray;
    UITableView *_tableView;
    UISearchBar *_searchBar;
    BOOL _isContentInset;
    BOOL _isSearching;
}
@end
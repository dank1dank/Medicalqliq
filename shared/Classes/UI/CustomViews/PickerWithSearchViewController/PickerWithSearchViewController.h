#import <UIKit/UIKit.h>
#import "QliqBaseViewController.h"


@protocol PickerWithSearchViewControllerDelegate

- (void) pickerWithSearchViewControllerdidPickItem: (id) anItem
                                       forItemName: (NSString*) anItemName;

@end



@interface PickerWithSearchViewController : QliqBaseViewController <UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource>
{
    NSArray* dataArray;
	NSMutableArray *searchArray;
    UITableView *tableView;
    UISearchBar *searchBar;
    
    id delegate;
}

@property (nonatomic, assign) id delegate;

@end

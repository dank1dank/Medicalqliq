#import "PickerWithSearchViewController.h"
#import "GenericTableViewCell.h"


@implementation PickerWithSearchViewController

@synthesize delegate;

- (void) viewDidLoad
{	
	self.view.backgroundColor=[UIColor whiteColor];
	
	tableView = [[UITableView alloc] initWithFrame: CGRectMake(0, 44, 320, 372) style: UITableViewStylePlain];
	tableView.editing = NO;
	tableView.delegate = self;
	tableView.dataSource = self;
	tableView.separatorColor = [UIColor lightGrayColor];
	tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	tableView.rowHeight = 40;
	tableView.tag = 1;
	tableView.backgroundColor = [UIColor whiteColor];
	tableView.clipsToBounds = YES;
	[self.view addSubview: tableView];
	
	searchBar = [[UISearchBar alloc] initWithFrame: CGRectMake(0, 0, 320, 44)];
	searchBar.barStyle = UIBarStyleDefault;
	searchBar.translucent = NO;
	searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
	searchBar.showsScopeBar = NO;
	searchBar.tag = 2;
	searchBar.backgroundColor = [UIColor whiteColor];
    searchBar.delegate = self;
	[self.view addSubview: searchBar];
	
    dataArray = [self fillDataArray];
    searchArray = [[NSMutableArray alloc] initWithCapacity: [dataArray count]];
    [self doSearch: @""];
    
    self.navigationItem.rightBarButtonItem = [self rightItemWithTitle: [self selfTitle]
                                                          buttonImage: nil
                                                         buttonAction: nil];	
    
}


#pragma mark -
#pragma mark Override

-(void) clickDone: (NSInteger) selectedItem 
{
    [self.navigationController popViewControllerAnimated: YES];
}


- (NSArray*) fillDataArray
{
    return [[NSArray alloc] init];
}

- (NSString*) selfTitle
{
    return @"";
}

- (NSString*) textForObjectAtIndex: (NSUInteger) anIndex
{
    return @"";
}

- (NSString*) codeForObjectAtIndex: (NSUInteger) anIndex
{
    return @"";
}

- (NSString*) searchPredicate
{
    return @"";
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView: (UITableView*) tableView
{
    return 1;
}

- (NSInteger) tableView: (UITableView*) tableView 
  numberOfRowsInSection: (NSInteger) section
{
    int count = [searchArray count];
    if (count == 0) 
        count = 1;
    return count;
}

- (UITableViewCell*) tableView: (UITableView*) tableView
         cellForRowAtIndexPath: (NSIndexPath*) indexPath
{
	NSString *CellIdentifier = @"PickerWithSearchCell";
	GenericTableViewCell *cell = (GenericTableViewCell*)[tableView dequeueReusableCellWithIdentifier: CellIdentifier];
    if (cell == nil)
    {
        cell = [[[GenericTableViewCell alloc] initWithStyle: UITableViewCellStyleSubtitle
                                            reuseIdentifier: CellIdentifier] autorelease];
    }

    
    if ([dataArray count] != 0)
    {
        cell.textLabel.text = [self textForObjectAtIndex: indexPath.row];
        cell.detailTextLabel.text = [self codeForObjectAtIndex: indexPath.row];
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.editingAccessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
    else 
    {
        cell.textLabel.text = NSLocalizedString(@"No matches. Add new facility.", @"");
    }
	
	return cell;
}

- (void)        tableView: (UITableView*) tableView
  didSelectRowAtIndexPath: (NSIndexPath *)indexPath
{
    [self clickDone: indexPath.row];
}

- (CGFloat)     tableView: (UITableView*) tableView
  heightForRowAtIndexPath: (NSIndexPath*) indexPath
{
	return 50;
}

- (void) dealloc
{
    [dataArray release];
    [searchArray release];
	[super dealloc];
}

#pragma mark -
#pragma mark UISearchBarField

- (void) doSearch: (NSString*) searchText 
{
    [searchArray removeAllObjects];
    
    if ([searchText isEqualToString: @""])
        searchText = @"*";
    else
        searchText = [NSString stringWithFormat: @"*%@*", searchText];
    
    NSPredicate* predicate = [NSPredicate predicateWithFormat: [self searchPredicate], searchText, searchText];
    
    [searchArray addObjectsFromArray: dataArray];
    [searchArray filterUsingPredicate: predicate];
    [tableView reloadData];
}

- (void) searchBar: (UISearchBar*) searchBar 
     textDidChange: (NSString*) searchText 
{
    [self doSearch: searchText];
}

- (void) searchBarSearchButtonClicked: (UISearchBar*) searchBar
{
    [self doSearch: searchBar.text];
    [searchBar resignFirstResponder];
}


@end

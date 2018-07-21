//
//  SelectPDFViewController.m
//  qliq
//
//  Created by Valerii Lider on 11/18/16.
//
//

#import "SelectPDFViewController.h"
#import "SelectPDFTableViewCell.h"

#import "MediaFileService.h"
#import "MediaFileDBService.h"

#import "QliqSignViewController.h"

@interface SelectPDFViewController () <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate>

//IBOutlets
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UIView *createNewPDFView;
@property (weak, nonatomic) IBOutlet UIButton *createNewPDFButton;

@property (nonatomic, strong) NSArray *pdfFiles;
@property (atomic, strong) NSMutableArray *searchPdfFiles;
@property (nonatomic, assign) BOOL isSearching;

//Constraints
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomTableViewConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *searchBarHeightConstraint;

@end

@implementation SelectPDFViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.showNewPDFButton) {
        self.createNewPDFButton.hidden = NO;
    }
    
    //SearchBar
    {
        self.searchBar.placeholder = QliqLocalizedString(@"2107-TitleSearch");
        self.searchBar.delegate = self;
        self.searchBar.autocorrectionType = UITextAutocorrectionTypeYes;
        self.searchBar.spellCheckingType = UITextSpellCheckingTypeYes;
        self.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.searchBar.keyboardType = UIKeyboardTypeAlphabet;
        self.isSearching = NO;
        [self changeFrameHeaderView];
    }
    if (self.searchPdfFiles == nil)
    {
        self.searchPdfFiles = [[NSMutableArray alloc] init];
    }
    
    //TableView
    {
        self.tableView.delegate = self;
        [self getExistingDocumentFromMediaFileDBService];
    }
    
    self.navigationItem.title = @"Select PDF";
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Private Methods -
#pragma mark * HeaderView

- (void)changeFrameHeaderView
{
    CGRect frame = self.headerView.frame;
    frame.size.height =  self.showNewPDFButton ? self.searchBarHeightConstraint.constant + self.createNewPDFView.frame.size.height : self.searchBarHeightConstraint.constant;
    self.headerView.frame = frame;
    [self.tableView setTableHeaderView:self.headerView];
}

#pragma mark - Actions -

- (IBAction)onBackAction:(id)sender
{
    DDLogSupport(@"Back from SelectPDFViewController");
    if (self.navigationController.presentingViewController && [[self.navigationController viewControllers].firstObject isEqual:self]) {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (IBAction)createNewPDFButton:(id)sender {
    
    QliqSignViewController *qliqSignViewController = [kMainStoryboard instantiateViewControllerWithIdentifier:@"QliqSignViewController"];
    qliqSignViewController.returnToFaxView = YES;
    [self.navigationController pushViewController:qliqSignViewController animated:YES];
    qliqSignViewController = nil;
    
}

#pragma mark * Data

- (void)getExistingDocumentFromMediaFileDBService
{
    __weak __block typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        MediaFileService *service = [MediaFileService getInstance];
        MediaFileDBService *dbService = [MediaFileDBService sharedService];
        weakSelf.pdfFiles = [dbService mediafilesWithMimeTypes:[service pdfMimeTypes] archived:NO];
        [weakSelf sortPdfFiles];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.tableView reloadData];
        });
    });
}

- (void)sortPdfFiles
{
    if (self.pdfFiles.count != 0)
        //Sort PDF files with key 'mediafileId', because 'timestamp' does not related to last update date of file content.
        // Qliq media files can't be updated by content, but only created once, so we can use 'mediafileId' for sorting, as value, that increasing each time, when creates new media file.
        self.pdfFiles = [NSMutableArray arrayWithArray:[self.pdfFiles sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"mediafileId" ascending:NO]]] ];
}

#pragma mark - Delegates -
#pragma mark * TableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = self.pdfFiles.count;
    
    if (self.isSearching)
    {
        count = self.searchPdfFiles.count;
    }
    else
    {
        count = self.pdfFiles.count;
    }
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"SelectPDFTableViewCell_ID";
    
    MediaFile *pdfFile = nil;
    
    if (self.isSearching) {
        if (indexPath.row >= self.searchPdfFiles.count)
            return nil;
        pdfFile = [self.searchPdfFiles objectAtIndex:indexPath.row];
    }
    else
        pdfFile = [self.pdfFiles objectAtIndex:indexPath.row];
    
    SelectPDFTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    [cell setCell:pdfFile withIndexPath:indexPath];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MediaFile *pdfFile = nil;
    if (self.isSearching)
        pdfFile = [self.searchPdfFiles objectAtIndex:indexPath.row];
    else
        pdfFile = [self.pdfFiles objectAtIndex:indexPath.row];
    
    [self.navigationController popViewControllerAnimated:YES];
    
    if (self.selectPDFCallBack)
        self.selectPDFCallBack(pdfFile);
}

#pragma mark * UISearchBarField

- (void)doSearch:(NSString *)searchText
{
    NSMutableArray *tmpArr = [self.pdfFiles mutableCopy];
    SearchOperation * operation = [[SearchOperation alloc] initWithArray:tmpArr andSearchString:searchText withPrioritizedAlphabetically:NO];
    self.searchPdfFiles = [[operation search] mutableCopy];
    
    self.isSearching = (operation != nil);
    
    __weak __block typeof(self) weakSelf = self;
    dispatch_async_main(^{
        [weakSelf.tableView reloadData];
    });
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    
    [self doSearch:searchText];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    
    [self doSearch:searchBar.text];
    [searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    searchBar.text = nil;
    [searchBar resignFirstResponder];
}


@end

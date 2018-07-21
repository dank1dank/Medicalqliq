//
//  CollectionFavoritesViewController.m
//  qliq
//
//  Created by Valerii Lider on 10/21/14.
//
//

#import "CollectionFavoritesViewController.h"
#import "CollectionFavoritesCell.h"
#import "DetailContactInfoViewController.h"
#import "SelectContactsViewController.h"
#import "QliqFavoritesContactGroup.h"
#import "StatusView.h"

@interface CollectionFavoritesViewController ()
<
UICollectionViewDataSource,
UICollectionViewDelegate,
UISearchBarDelegate,
SearchOperationDelegate
>

@property (nonatomic, strong) NSMutableArray *searchContacts;
@property (nonatomic, strong) NSMutableArray *sortContacts;

@property (nonatomic, strong) NSOperationQueue *searchOperationsQueue;

@end

@implementation CollectionFavoritesViewController

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.searchOperationsQueue cancelAllOperations];
    [self.searchOperationsQueue waitUntilAllOperationsAreFinished];
    self.searchOperationsQueue = nil;
    
    self.searchContacts = nil;
    self.sortContacts = nil;
    self.contactsArray = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.navigationController setNavigationBarHidden:NO];
    self.searchBar.delegate = self;
    
    self.searchOperationsQueue = [[NSOperationQueue alloc] init];
    self.searchOperationsQueue.maxConcurrentOperationCount = 1;
    self.searchOperationsQueue.name = @"com.qliq.collectionFavoritesViewController.searchQueue";
    
    self.sortContacts = [NSMutableArray new];
    
    self.collectionView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    
    //Notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onPresenceChangeNotification:)
                                                 name:@"PresenceChangeStatusNotification"
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Notifications -

- (void)onPresenceChangeNotification:(NSNotification *)notification
{
    @synchronized(self) {
        
        if ([notification.userInfo[@"isForMyself"] boolValue] == NO)
        {
            __block __weak typeof(self) weakSelf = self;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                __strong typeof(self) strongSelf = weakSelf;
                NSString *qliqId = notification.userInfo[@"qliqId"];
                    for (NSUInteger index = 0; index < strongSelf.sortContacts.count; index++)
                    {
                        if (strongSelf.sortContacts.count == 0) {
                            break;
                        }
                        Contact *contact = [strongSelf.sortContacts objectAtIndex:index];
                        if ([contact.qliqId isEqualToString:qliqId]) {
                            id item = [[QliqAvatar sharedInstance] contactIsQliqUser:contact];
                            if ([item isKindOfClass:[QliqUser class]]) {
                                QliqUser *user = item;
                                user.presenceStatus = [notification.userInfo[@"presenceStatus"] integerValue];
                                [strongSelf.sortContacts replaceObjectAtIndex:index withObject:user];
                                break;
                            }
                        }
                    }
                    
                    if (strongSelf.isSearch) {
                        for (NSUInteger index = 0; index < strongSelf.searchContacts.count; index++)
                        {
                            if (strongSelf.searchContacts.count == 0)
                            {
                                break;
                            }
                            Contact *contact = [strongSelf.searchContacts objectAtIndex:index];
                            if ([contact.qliqId isEqualToString:qliqId]) {
                                id item = [[QliqAvatar sharedInstance] contactIsQliqUser:contact];
                                if ([item isKindOfClass:[QliqUser class]])
                                {
                                    QliqUser *user = item;
                                    user.presenceStatus = [notification.userInfo[@"presenceStatus"] integerValue];
                                    [strongSelf.searchContacts replaceObjectAtIndex:index withObject:user];
                                    break;
                                }
                            }
                        }
                    }
                
                performBlockInMainThread(^{
                    [strongSelf.collectionView reloadData];
                });
            });
        }
    }
}

#pragma mark - Private Methods -

- (void)downSwipe:(UISwipeGestureRecognizer *)sender
{
    if ([self.searchBar isFirstResponder])
        [self.searchBar resignFirstResponder];
}

- (void)getContactsFromSearch:(NSArray*)results
{
    performBlockInMainThread(^{
        if (self.searchContacts.count > 0)
        {
            for (id object in results)
            {
                if (![self.searchContacts containsObject:object])
                    [self.searchContacts addObject:object];
            }
        }
        else
        {
            [self.searchContacts addObjectsFromArray:results];
        }
        
        [self.collectionView reloadData];
    });
}

- (NSArray*)getSortContacts:(NSArray*)contactsArray
{
    NSArray *contacts = contactsArray;
    
    NSString *filter = self.searchBar.text;
    
    NSMutableArray *nameArray           = [NSMutableArray new];
    NSMutableArray *surnameArray        = [NSMutableArray new];
    NSMutableArray *nameAndSurnameArray = [NSMutableArray new];
    NSMutableArray *otherArray          = [NSMutableArray new];
    
    [contacts enumerateObjectsUsingBlock:^(Contact *contact, NSUInteger idx, BOOL *stop) {
        
        NSString *firstName     = contact.firstName     ? contact.firstName     : @"";
        NSString *lastName      = contact.lastName      ? contact.lastName      : @"";
        
        if ([firstName rangeOfString:filter options:NSCaseInsensitiveSearch].location == 0 && [lastName rangeOfString:filter options:NSCaseInsensitiveSearch].location == 0)
        {
            [nameAndSurnameArray addObject:contact];
        }
        else if ([firstName rangeOfString:filter options:NSCaseInsensitiveSearch].location == 0)
        {
            [nameArray addObject:contact];
        }
        else if ([lastName rangeOfString:filter options:NSCaseInsensitiveSearch].location == 0)
        {
            [surnameArray addObject:contact];
        }
        else
        {
            [otherArray addObject:contact];
        }
    }];
    
    nameArray = [[nameArray sortedArrayUsingDescriptors:
  @[[NSSortDescriptor sortDescriptorWithKey:@"firstName" ascending:YES]]] mutableCopy];
    
    surnameArray = [[surnameArray sortedArrayUsingDescriptors:
  @[[NSSortDescriptor sortDescriptorWithKey:@"lastName" ascending:YES]]] mutableCopy];
    
    nameAndSurnameArray = [[nameAndSurnameArray sortedArrayUsingDescriptors:
  @[[NSSortDescriptor sortDescriptorWithKey:@"lastName" ascending:YES],
    [NSSortDescriptor sortDescriptorWithKey:@"firstName" ascending:YES]]] mutableCopy];
    
    otherArray = [[otherArray sortedArrayUsingDescriptors:
  @[[NSSortDescriptor sortDescriptorWithKey:@"lastName" ascending:YES],
    [NSSortDescriptor sortDescriptorWithKey:@"firstName" ascending:YES]]] mutableCopy];
    
    contacts = nil;
    contacts = [NSArray new];
    
    contacts = [contacts arrayByAddingObjectsFromArray:nameArray];
    contacts = [contacts arrayByAddingObjectsFromArray:surnameArray];
    contacts = [contacts arrayByAddingObjectsFromArray:nameAndSurnameArray];
    contacts = [contacts arrayByAddingObjectsFromArray:otherArray];
    
    return contacts;
}


#pragma mark - Settes -

- (void)setContactsArray:(NSMutableArray *)contactsArray
{
    performBlockInMainThreadSync(^{
        /* Update table */
        @try {
            
            id item = nil;
            if (contactsArray.count > 0)
                item = [contactsArray firstObject];

            [_contactsArray removeAllObjects];
            if ([item isKindOfClass:[QliqUser class]] || [item isKindOfClass:[Contact class]])
            {
                NSMutableArray *sortArray = [[contactsArray sortedArrayUsingDescriptors:
                                              @[[NSSortDescriptor sortDescriptorWithKey:@"lastName" ascending:YES],
                                                [NSSortDescriptor sortDescriptorWithKey:@"firstName" ascending:YES]]] mutableCopy];
                _contactsArray = sortArray;
            }
            
            [self doSearchWithText:self.searchBar.text];
        }
        @catch (NSException *exception) {
            [self doSearchWithText:self.searchBar.text];
        }
    });
}

#pragma mark - Public Methods -

- (void)addFaforites
{
    SelectContactsViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([SelectContactsViewController class])];
    controller.typeController   = STForFavorites;
    controller.participants     = self.contactsArray;
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)showSearchBar:(BOOL)show withAnimation:(BOOL)animated
{
    float constant = show ? 44.f : 0.f;
    
    self.isSearch = show;
    if (show)
    {
        [self.searchBar becomeFirstResponder];
        [self doSearchWithText:self.searchBar.text];
    }
        
    [self.collectionView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
    
    if (constant != self.searchBarHeightConstraint.constant)
    {
        if (animated)
        {
            [UIView animateWithDuration:0.3 delay:0.0 options:nil animations:^{
                
                self.searchBarHeightConstraint.constant = constant;
                [self.collectionView reloadData];
                [self.view layoutIfNeeded];
                
            } completion:nil];
        }
        else
        {
            self.searchBarHeightConstraint.constant = constant;
            [self.collectionView reloadData];
        }
    }
}

#pragma mark - Delegates -

#pragma mark - - CollectionView Delegate

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView *reusableview = nil;
    
    if (kind == UICollectionElementKindSectionHeader) {
        reusableview = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderViewF" forIndexPath:indexPath];
    }
    
    if (kind == UICollectionElementKindSectionFooter) {
        UICollectionReusableView *footerview = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"FooterView" forIndexPath:indexPath];
        
        reusableview = footerview;
    }
    
    return reusableview;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    NSInteger count = 1;
    
    self.sortContacts = nil;
    
    if (self.isSearch)
        self.sortContacts = [NSMutableArray arrayWithArray:[self getSortContacts:self.searchContacts] ];
    else
        self.sortContacts = [NSMutableArray arrayWithArray:self.contactsArray];
    
    return count;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSUInteger count = 0;
    NSInteger addToFavorite = 1;
    
    count = self.sortContacts.count;
        
//    count = self.isSearch ? self.searchContacts.count : array.count;
    
    count = count + addToFavorite;
    
    return count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"Collection_cell";
    CollectionFavoritesCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    if (indexPath.row == 0)
    {
        cell.avatarImageView.image  = [UIImage imageNamed:@"AddToFavorite"];
        cell.statusView.hidden = YES;
        cell.titleLabel.text   = QliqLocalizedString(@"2127-TitleEditFavorites");
    }
    else
    {
        Contact *contact = nil;
        contact = [self.sortContacts objectAtIndex:indexPath.row - 1];
        contact = [[QliqAvatar sharedInstance] contactIsQliqUser:contact];
        
        if ([contact isKindOfClass:[QliqUser class]])
            [cell setCellWithContact:contact];
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0)
    {
        [self addFaforites];
    }
    else
    {
        Contact *contact = nil;
        contact = [self.sortContacts objectAtIndex:indexPath.row - 1];
        contact = [[QliqAvatar sharedInstance] contactIsQliqUser:contact];
        
        // As it is leaking about 256 bytes per call.
        /*
         DetailContactInfoViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([DetailContactInfoViewController class])];
         controller.contact = contact;
         [self.navigationController pushViewController:controller animated:YES];
         */
        
        NSArray *controllers = [self.navigationController viewControllers];
        if (![controllers.lastObject isKindOfClass:[DetailContactInfoViewController class]]) {
            DetailContactInfoViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([DetailContactInfoViewController class])];
            controller.contact = contact;
            [self.navigationController pushViewController:controller animated:YES];
        }
    }
}

#pragma mark - - UIScrollView Delegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if ([self.searchBar isFirstResponder])
        [self.searchBar resignFirstResponder];
}

/*
#pragma mark - - UISearchBar Delegate

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    return YES;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self doSearchWithSearchText:searchText];
}

//- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
//{
//    if ([self.searchBar isFirstResponder])
//        [self.searchBar resignFirstResponder];
//}

- (void)doSearchWithSearchText:(NSString*)searchText
{
    self.searchContacts = [[ QliqAvatar sharedInstance ] reloadContactswithContacts:self.contactsArray andWithSearchString:searchText];
    [self.collectionView reloadData];
    [self.collectionView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
}
*/

#pragma mark * UISearchBarDelegate

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self.collectionView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
    [self doSearchWithText:searchText];
}

- (void)doSearchWithText:(NSString*)searchText
{
    [self.searchOperationsQueue cancelAllOperations];
    
    NSArray *tempSearchArray = [self.contactsArray copy];
    
    if (self.searchContacts == nil)
        self.searchContacts = [NSMutableArray new];
    
    [self.searchContacts removeAllObjects];
    
    SearchOperation *searchContactsOperation = [[SearchOperation alloc] initWithArray:tempSearchArray andSearchString:searchText withPrioritizedAlphabetically:NO];
    searchContactsOperation.delegate    = self;
    searchContactsOperation.batchSize   = 0;
    
    self.isSearch = searchContactsOperation.isPredicateCorrect;
    
    if (!self.isSearch)
        [self.collectionView reloadData];
    
    if (searchContactsOperation.isPredicateCorrect)
        [self.searchOperationsQueue addOperation:searchContactsOperation];
}



#pragma mark * SearchContactsOperationDelegate

- (void)searchOperation:(SearchOperation *)operation didFoundResults:(NSArray *)array
{
    [self getContactsFromSearch:array];
}

- (void)foundResultsPart:(NSArray *)results
{
    [self getContactsFromSearch:results];
}

@end

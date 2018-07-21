//
//  FavoriteContactsViewController.m
//  qliq
//
//  Created by Valerii Lider on 5/28/15.
//
//

#import "FavoriteContactsViewController.h"
#import "CollectionFavoritesViewController.h"

#import "QliqFavoritesContactGroup.h"


@interface FavoriteContactsViewController ()

/**
 IBOutlet
 */
@property (weak, nonatomic) IBOutlet UILabel *navigationLeftTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *navigationRightTitleLabel;

@property (weak, nonatomic) IBOutlet UIView *favoriteCollectionView;

/**
 UI
 */
@property (strong, nonatomic) CollectionFavoritesViewController *collectionViewFavorites;

@end

@implementation FavoriteContactsViewController

- (void)configureDefaultText {
    self.navigationLeftTitleLabel.text = QliqLocalizedString(@"49-ButtonBack");
    self.navigationRightTitleLabel.text = QliqLocalizedString(@"2126-TitleFavoriteContacts");
}

- (void)viewDidLoad {
    [super viewDidLoad];

    
    
    //CollectionView Container
    {
        for (UIViewController *controller in self.childViewControllers)
        {
            if ([controller isKindOfClass:[CollectionFavoritesViewController class]])
                self.collectionViewFavorites = (id)controller;
        }
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO];
    [self.navigationController.navigationBar setTranslucent:NO];
    
    [self updateFavoriteContacts];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Private -

- (void)updateFavoriteContacts
{
    QliqFavoritesContactGroup *favoritesGroup = [[QliqFavoritesContactGroup alloc] init];
    NSArray *favoriteContacts = [favoritesGroup getOnlyContacts];
    
    self.collectionViewFavorites.contactsArray = [favoriteContacts mutableCopy];
    [self.collectionViewFavorites.collectionView reloadData];
}

#pragma mark - Actions -

- (IBAction)onBack:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

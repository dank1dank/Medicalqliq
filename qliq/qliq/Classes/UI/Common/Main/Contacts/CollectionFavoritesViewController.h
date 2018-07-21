//
//  CollectionFavoritesViewController.h
//  qliq
//
//  Created by Valerii Lider on 10/21/14.
//
//

#import <UIKit/UIKit.h>

@interface CollectionFavoritesViewController : UIViewController

/**
 IBOutlet
 */
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

/* Constraints */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *searchBarHeightConstraint;

/**
 Data
 */
@property (nonatomic, assign) BOOL isSearch;
@property (nonatomic, strong) NSMutableArray *contactsArray;

/**
 Methods
 */
- (void)showSearchBar:(BOOL)show withAnimation:(BOOL)animated;
- (void)addFaforites;

@end

//
//  CollectionFavoritesCell.h
//  qliq
//
//  Created by Valerii Lider on 10/22/14.
//
//

#import <UIKit/UIKit.h>

@class Contact, StatusView;

@interface CollectionFavoritesCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet StatusView *statusView;

- (void)setCellWithContact:(Contact*)contact;

@end

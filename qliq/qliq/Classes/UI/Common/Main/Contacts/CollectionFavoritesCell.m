//
//  CollectionFavoritesCell.m
//  qliq
//
//  Created by Valerii Lider on 10/22/14.
//
//

#import "CollectionFavoritesCell.h"
#import "StatusView.h"

@implementation CollectionFavoritesCell

- (void)awakeFromNib {
    // Initialization code
    [super awakeFromNib];
}

#pragma mark - Public Methods -

- (void)setCellWithContact:(Contact *)contact
{
    self.statusView.hidden = NO;
    self.titleLabel.text = [contact nameDescription];
    self.statusView.statusColorView.backgroundColor = [[QliqAvatar sharedInstance] colorForPresenceStatus:((QliqUser *)contact).presenceStatus];
    
    self.avatarImageView.image = [[QliqAvatar sharedInstance] getAvatarForItem:contact withTitle:nil];
}


@end

//
//  SettingsTableViewCell.h
//  qliq
//
//  Created by Valerii Lider on 29/09/15.
//
//

#import <UIKit/UIKit.h>

#define kSettingsTableViewCell_ID @"SettingsTableViewCell_ID"

@interface DefaultSettingsTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIImageView *arrowImageView;

- (void)configureCellWithTitle:(NSString *)title
               withDescription:(NSString *)description
                     withArrow:(BOOL)showArrow;

@end

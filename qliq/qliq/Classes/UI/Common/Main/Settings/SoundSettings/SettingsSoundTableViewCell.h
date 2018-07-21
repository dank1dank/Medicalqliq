//
//  SettingsSoundTableViewCell.h
//  qliq
//
//  Created by Valeriy Lider on 25.11.14.
//
//

#import <UIKit/UIKit.h>

@interface SettingsSoundTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UISwitch *switchOption;
@property (weak, nonatomic) IBOutlet UIImageView *arrowImage;

@end

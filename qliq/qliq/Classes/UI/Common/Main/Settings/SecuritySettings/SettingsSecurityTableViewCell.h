//
//  SettingsSecurityTableViewCell.h
//  qliq
//
//  Created by Valeriy Lider on 20.11.14.
//
//

#import <UIKit/UIKit.h>

@interface SettingsSecurityTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *nameOptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UISwitch *switchOption;
@property (weak, nonatomic) IBOutlet UIImageView *arrowImageView;

@end

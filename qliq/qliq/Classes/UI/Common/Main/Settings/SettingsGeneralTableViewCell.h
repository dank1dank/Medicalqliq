//
//  SettingsGeneralTableViewCell.h
//  qliq
//
//  Created by Valerii Lider on 05/23/2017.
//
//

#import <UIKit/UIKit.h>

@interface SettingsGeneralTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *arrowImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameOptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UISwitch *switchOption;

@end

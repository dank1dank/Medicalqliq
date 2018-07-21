//
//  SettingsSupportTableViewCell.h
//  qliq
//
//  Created by Valeriy Lider on 24.11.14.
//
//

#import <UIKit/UIKit.h>
#import "SettingsItem.h"

@protocol SettingsSupportCellDelegate <NSObject>

- (void)closeConnectionWasPressed;

@end

@interface SettingsSupportTableViewCell : UITableViewCell

@property (nonatomic, assign) id <SettingsSupportCellDelegate> delegate;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UISwitch *switchOption;
@property (weak, nonatomic) IBOutlet UIImageView *arrowImage;

@property (weak, nonatomic) IBOutlet UIButton *rightButton;

- (void)configureCellWithItem:(SettingsItem *)item;

@end

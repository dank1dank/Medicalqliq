//
//  SettingsRingtoneTableViewCell.h
//  qliq
//
//  Created by Valeriy Lider on 25.11.14.
//
//

#import <UIKit/UIKit.h>

@interface SettingsRingtoneTableViewCell : UITableViewCell

// Settings
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UISwitch *switchOption;
@property (weak, nonatomic) IBOutlet UISegmentedControl *volumeBar;
@property (weak, nonatomic) IBOutlet UIButton *editButton;

// Ringtones
@property (weak, nonatomic) IBOutlet UILabel *ringtoneNameLabel;

@end

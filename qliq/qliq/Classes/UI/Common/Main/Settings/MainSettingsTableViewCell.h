//
//  MainSettingsTableViewCell.h
//  qliq
//
//  Created by Valeriy Lider on 17.11.14.
//
//

#import <UIKit/UIKit.h>

@protocol MainSettingsCellDelegate <NSObject>

- (void) syncContactsWasPressed;
- (void) logOutWasPressed;

@end

@interface MainSettingsTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *nameOptionLabel;
@property (weak, nonatomic) IBOutlet UISwitch *switchOptionMode;
@property (weak, nonatomic) IBOutlet UIImageView *arrowImageView;
@property (weak, nonatomic) IBOutlet UITextField *textField;

@property (nonatomic, assign) id <MainSettingsCellDelegate> delegate;

@end

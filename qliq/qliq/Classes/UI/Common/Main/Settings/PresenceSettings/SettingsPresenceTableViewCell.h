//
//  SettingsPresenceTableViewCell.h
//  qliq
//
//  Created by Valeriy Lider on 18.12.14.
//
//

#import <UIKit/UIKit.h>
#import "PresenceEditView.h"

@protocol SettingsPresenceCellDelegate <NSObject>

- (void) joinGroupWasPressed;
- (void) leaveGroupWasPressed;

@end

@interface SettingsPresenceTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet PresenceEditView *presenceEditView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *heightPresenceEditViewConstraint;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
//@property (weak, nonatomic) IBOutlet UIButton *checkBox;
@property (weak, nonatomic) IBOutlet UIButton *checkBoxButton;

@property (weak, nonatomic) IBOutlet UIButton *leftButton;

@property (weak, nonatomic) IBOutlet UIButton *rightButton;


@property (nonatomic, assign) id <SettingsPresenceCellDelegate> delegate;


@end

//
//  SelectFaxContactTableViewCell.h
//  qliq
//
//  Created by Valeriy Lider on 1/12/18.
//

#import <UIKit/UIKit.h>

@protocol SelectFaxContactCellDelegate <NSObject>

- (void)onPhoneButton:(NSString*)phone;

@end

@interface SelectFaxContactTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *organizationLabel;
@property (weak, nonatomic) IBOutlet UILabel *faxLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameContactLabel;
@property (weak, nonatomic) IBOutlet UILabel *phoneNumberLabel;

@property (weak, nonatomic) IBOutlet UIButton *onCallButton;
@property (weak, nonatomic) IBOutlet UIImageView *contactIcon;

@property (weak, nonatomic) IBOutlet UIView *avatarImageView;
@property (weak, nonatomic) IBOutlet UIImageView *avatarImage;

@property (nonatomic, assign) id <SelectFaxContactCellDelegate> delegate;

- (void)setCheckedBox:(BOOL)isCheked;
- (IBAction)onPhone:(UIButton *)sender;


@end

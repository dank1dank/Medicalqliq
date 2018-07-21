//
//  DetailContactInfoCell.h
//  qliq
//
//  Created by Valerii Lider on 10/21/14.
//
//

#import <UIKit/UIKit.h>

@protocol DetailContactInfoCellDelegate <NSObject>

- (void)onPhoneButton:(NSString*)phone;
- (void)onMessageButton;

@end

@interface DetailContactInfoCell : UITableViewCell

@property (nonatomic, assign) id <DetailContactInfoCellDelegate> delegate;

@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UILabel *information;

@property (weak, nonatomic) IBOutlet UIButton *phoneButton;
@property (weak, nonatomic) IBOutlet UIButton *chatButton;
@property (weak, nonatomic) IBOutlet UILabel *inlineTitle;
@property (weak, nonatomic) IBOutlet UILabel *inlineInfo;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *titleLableTrallingToPhoneButton;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *informationLabelTrallingToPhonButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *informationLableHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *chatButonWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *chatButtonLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *phoneButtonWidthConstraint;

- (IBAction)onPhone:(UIButton *)sender;
- (IBAction)onChat:(UIButton *)sender;


@end

//
//  SelectFaxContactTableViewCell.m
//  qliq
//
//  Created by Valeriy Lider on 1/12/18.
//

#import "SelectFaxContactTableViewCell.h"

@interface SelectFaxContactTableViewCell ()

@property (nonatomic, weak) IBOutlet UIButton *checkBox;

@end

@implementation SelectFaxContactTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - Public

- (void)setCheckedBox:(BOOL)isCheked
{
    UIImage *image = nil;
    image = isCheked ? [UIImage imageNamed:@"ConversationChecked"] : [UIImage imageNamed:@"ConversationUnChecked"];
    [self.checkBox setImage:image forState:UIControlStateNormal];
}

- (IBAction)onPhone:(UIButton *)sender {
    [self.delegate onPhoneButton:self.phoneNumberLabel.text];
}

@end

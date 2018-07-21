//
//  DetailContactInfoCell.m
//  qliq
//
//  Created by Valerii Lider on 10/21/14.
//
//

#import "DetailContactInfoCell.h"

@implementation DetailContactInfoCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.information.numberOfLines = 1;
    self.information.minimumScaleFactor = 10.f / self.information.font.pointSize;
    self.information.adjustsFontSizeToFitWidth = YES;
   
    self.title.numberOfLines = 1;
    self.title.minimumScaleFactor = 10.f / self.title.font.pointSize;
    self.title.adjustsFontSizeToFitWidth = YES;
    
    self.inlineTitle.numberOfLines = 1;
    self.inlineTitle.minimumScaleFactor = 10.f / self.information.font.pointSize;
    self.inlineTitle.adjustsFontSizeToFitWidth = YES;
    
    self.inlineInfo.numberOfLines = 1;
    self.inlineInfo.minimumScaleFactor = 10.f / self.title.font.pointSize;
    self.inlineInfo.adjustsFontSizeToFitWidth = YES;
    
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.inlineInfo.text = @"";
    self.inlineInfo.hidden = YES;
 
    self.inlineTitle.text = @"";
    self.inlineTitle.hidden = YES;

    self.title.text = @"";
    self.title.hidden = YES;
    
    self.information.text = @"";
    self.information.hidden = YES;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (IBAction)onPhone:(UIButton *)sender {
    [self.delegate onPhoneButton:self.information.text];
}

- (IBAction)onChat:(UIButton *)sender {
        [self.delegate onMessageButton];
}

@end

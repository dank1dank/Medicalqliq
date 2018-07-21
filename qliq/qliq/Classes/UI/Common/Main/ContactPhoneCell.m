//
//  ContactPhoneCell.m
//  qliq
//
//  Created by Valerii Lider on 8/17/15.
//
//

#import "ContactPhoneCell.h"

@implementation ContactPhoneCell

- (void)awakeFromNib {
    [super awakeFromNib];

    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.anonymousCallButton.layer.cornerRadius = 5;
    self.anonymousCallButton.layer.borderColor = [UIColor colorWithRed:0x4c / 255.f green:0xb5 / 255.f blue:0xe0 / 255.f alpha:1.0f].CGColor;
    self.anonymousCallButton.layer.borderWidth = 2;
}

@end

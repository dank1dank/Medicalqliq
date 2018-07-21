//
//  ContactPhoneCell.h
//  qliq
//
//  Created by Valerii Lider on 8/17/15.
//
//

#import <UIKit/UIKit.h>

@interface ContactPhoneCell : UITableViewCell
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *subTitleLabel;
@property (nonatomic, weak) IBOutlet UILabel *typeLabel;
@property (nonatomic, weak) IBOutlet UIButton *phoneButton;

@property (nonatomic, weak) IBOutlet UIButton *anonymousCallButton;
@property (nonatomic, weak) IBOutlet UIButton *withCalledIDButton;
@end

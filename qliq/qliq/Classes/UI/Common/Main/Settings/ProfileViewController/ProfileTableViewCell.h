//
//  ProfileTableViewCell.h
//  qliq
//
//  Created by Valeriy Lider on 17.11.14.
//
//

#import <UIKit/UIKit.h>

@interface ProfileTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UITextField *descriptionTextField;

@end

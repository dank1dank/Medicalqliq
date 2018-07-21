//
//  QuickMessageCell.h
//  qliq
//
//  Created by Valerii Lider on 9/26/14.
//
//

#import <UIKit/UIKit.h>

@interface QuickMessageCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *quickMessageLabel;

+ (CGFloat)heightOfText:(NSString *)text withFont:(UIFont *)font;

@end

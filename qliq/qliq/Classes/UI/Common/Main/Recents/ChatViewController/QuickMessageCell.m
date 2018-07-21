//
//  QuickMessageCell.m
//  qliq
//
//  Created by Valerii Lider on 9/26/14.
//
//

#import "QuickMessageCell.h"

@implementation QuickMessageCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

+ (CGFloat)heightOfText:(NSString *)text withFont:(UIFont *)font
{
    CGFloat neededHeightSizeText = [text boundingRectWithSize:CGSizeMake(UIScreen.mainScreen.bounds.size.width-10.f, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:font} context:nil].size.height;
    
    return neededHeightSizeText;
}

@end

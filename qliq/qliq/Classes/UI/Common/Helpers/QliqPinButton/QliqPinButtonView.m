//
//  QliqPinButtonView.m
//  qliq
//
//  Created by Valerii Lider on 16/11/15.
//
//

#import "QliqPinButtonView.h"

#import "QliqPinButton.h"

@interface QliqPinButtonView ()

@property (weak, nonatomic) IBOutlet QliqPinButton *digitButton;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;

@end

@implementation QliqPinButtonView

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.backgroundColor = [UIColor clearColor];
    
    self.digitButton.layer.masksToBounds = YES;
    self.digitButton.layer.cornerRadius = self.frame.size.width/2;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end

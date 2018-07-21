//
//  StatusView.m
//  qliq
//
//  Created by Valerii Lider on 4/17/15.
//
//

#import "StatusView.h"

@interface StatusView ()

@end

@implementation StatusView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.layer.cornerRadius = self.frame.size.width/2.f;
    self.layer.masksToBounds = YES;
    
    CGFloat offset = 4;
    
    self.statusColorView =  [[ UIView alloc ] initWithFrame:CGRectMake(0, 0, self.frame.size.width - offset, self.frame.size.height - offset)];
    self.statusColorView.layer.cornerRadius = self.statusColorView.frame.size.width/2.f;
    self.statusColorView.layer.masksToBounds = YES;
    self.statusColorView.center = CGPointMake(self.frame.size.width/2.f, self.frame.size.height/2.f);
    [self addSubview:self.statusColorView];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end

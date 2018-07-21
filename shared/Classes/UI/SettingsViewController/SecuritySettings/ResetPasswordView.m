//
//  ResetPasswordView.m
//  qliq
//
//  Created by Aleksey Garbarev on 29.10.12.
//
//

#import "ResetPasswordView.h"

@implementation ResetPasswordView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        UIImageView * backgroundView = [[UIImageView alloc] initWithFrame:self.bounds];
        backgroundView.image = [UIImage imageNamed:@"SettingsAboutBackground"];
        [self addSubview:backgroundView];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end

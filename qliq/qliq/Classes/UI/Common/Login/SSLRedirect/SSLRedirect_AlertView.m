//
//  SSLRedirect_AlertView.m
//  qliq
//
//  Created by developer on 11/4/16.
//
//

#import "SSLRedirect_AlertView.h"

@implementation SSLRedirect_AlertView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)dealloc
{
    self.sslPresentingController = nil;
}

@end

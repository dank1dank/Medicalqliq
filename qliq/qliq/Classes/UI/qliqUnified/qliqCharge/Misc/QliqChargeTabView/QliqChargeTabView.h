//
//  QliqChargeTabView.h
//  qliq
//
//  Created by Paul Bar on 3/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QliqTabBarProtocols.h"
#import "SliderView.h"

@interface QliqChargeTabView : UIView <QliqTabViewProtocol,SliderViewDelegate>
{
    SliderView *sliderView;
    UIButton *chatButton;
    UIButton *pagesButton;
}

@end

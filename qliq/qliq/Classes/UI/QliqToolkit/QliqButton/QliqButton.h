//
//  QliqButton.h
//  qliqConnect
//
//  Created by Aleksey Garbarev on 01/10/12.
//  Copyright (c) 2012 Al Digit. All rights reserved.
//

#import <UIKit/UIKit.h>

#define QliqButtonStyleDefault QliqButtonStyleRoundedBlue

typedef enum {
    QliqButtonStyleNavigationBackOld,
    QliqButtonStyleRoundedBlue,
    QliqButtonStyleBlue,
    QliqButtonStyleNavigationBack,
    QliqButtonStyleTabBarItem,
    QliqButtonStyleToolbarItem}
QliqButtonStyle;

@interface QliqButton : UIButton

@property(nonatomic, strong) NSObject * context;

@property (nonatomic) CGSize titleOffset;
@property (nonatomic) CGSize imageOffset;

- (id) initWithStyle:(QliqButtonStyle) style __attribute__((deprecated));
- (id) initWithFrame:(CGRect) frame style:(QliqButtonStyle) _style;

- (void) setFontSize:(CGFloat) fontSize;

@end

//
//  QliqLabel.h
//  qliq
//
//  Created by Aleksey Garbarev on 11/9/12.
//
//

#import <UIKit/UIKit.h>


typedef enum {QliqLabelStyleNormal, QliqLabelStyleBold} QliqLabelStyle;


@interface QliqLabel : UILabel

- (id) initWithFrame:(CGRect) frame style:(QliqLabelStyle) style;

- (void) setFontSize:(CGFloat) fontSize;

@end

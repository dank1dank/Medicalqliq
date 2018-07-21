//
//  QliqTextfield.h
//  qliq
//
//  Created by Aleksey Garbarev on 30.10.12.
//
//

#import <UIKit/UIKit.h>

@class QliqTextfield;
@protocol QliqTextfieldDelegate <UITextFieldDelegate>

@optional
- (void)textFieldDidDeleteBackward:(QliqTextfield *)textField;
- (void)textFieldDidDeleteBackwardOnEmpty:(QliqTextfield *)textField;
@end

typedef enum {
    QliqTextfieldStyleClear,
    QliqTextfieldStyleRoundedCentered
} QliqTextfieldStyle;

@interface QliqTextfield : UITextField

@property (nonatomic, unsafe_unretained) id<QliqTextfieldDelegate> delegate;

- (id)initWithFrame:(CGRect)frame style:(QliqTextfieldStyle) style;

- (void)setFontSize:(CGFloat)fontSize;

@end

//
//  QliqTextfield.m
//  qliq
//
//  Created by Aleksey Garbarev on 30.10.12.
//
//

#import "QliqTextfield.h"
#import "NSInvocation_Class.h"


@interface QliqTextfield () <UITextInput, UIKeyInput>

@end

@implementation QliqTextfield

@dynamic delegate;

- (id) initWithFrame:(CGRect)frame style:(QliqTextfieldStyle) style{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        if (style == QliqTextfieldStyleRoundedCentered){
            UIView * paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 35)];
            self.background = QliqTextFieldBackground;
            self.clearButtonMode = UITextFieldViewModeWhileEditing;
            self.font = [UIFont fontWithName:QliqFontNameBold size:16];
            [self setLeftView:paddingView];
            self.leftViewMode = UITextFieldViewModeAlways;
            self.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
            self.textAlignment = NSTextAlignmentCenter;
        }
        
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame style:QliqTextfieldStyleRoundedCentered];
}

#pragma - UIKeyInput protocol

/* Called in iOS6 automatically. To work with iOS5 see hack below */
- (void)deleteBackward {
    BOOL wasEmpty = self.text.length == 0;
    [super deleteBackward];
    BOOL nowEmpty = self.text.length == 0;
    
    if ([self.delegate respondsToSelector:@selector(textFieldDidDeleteBackward:)])
        [self.delegate textFieldDidDeleteBackward:self];

    if (wasEmpty && nowEmpty && [self.delegate respondsToSelector:@selector(textFieldDidDeleteBackwardOnEmpty:)])
        [self.delegate textFieldDidDeleteBackwardOnEmpty:self];

}

/* iOS5 hack */
//- (BOOL) keyboardInputShouldDelete:(id) object{
//
//    BOOL shouldDelete = [NSInvocation boolOfInvokingTarget:self withSelector:@selector(keyboardInputShouldDelete:) ofClass:[UITextField class] arg:object];
    
//    if (shouldDelete && systemVersion >= 5.0 && systemVersion < 6.0)
//        [self deleteBackward];

//    return shouldDelete;
//}

- (void) setFontSize:(CGFloat) fontSize{
    [self setFont:[self.font fontWithSize:fontSize]];
}

@end

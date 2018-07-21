//
//  DeleteDetectingTextField.m
//  CarZ
//
//  Created by Ivan Zezyulya on 04.04.12.
//  Copyright (c) 2012 Al Digit. All rights reserved.
//

#import "DeleteDetectingTextField.h"

@interface DeleteDetectingTextField () <UITextFieldDelegate>
@end

@implementation DeleteDetectingTextField {
    UILabel *placeholderLabel;
    UITextField *hiddenField; // for hiding cursor
}

@synthesize textField, delegate, showPlaceholder, hideCursor;
@dynamic placeholder;

- (id) initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        self.backgroundColor = [UIColor whiteColor];

        showPlaceholder = YES;

        textField = [[UITextField alloc] initWithFrame:CGRectZero];
        textField.backgroundColor = [UIColor clearColor];
        textField.delegate = self;
        textField.text = @"\u200B"; // Zero-width character for detecting backspace tap
        [self addSubview:textField];

        [textField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];

        placeholderLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        placeholderLabel.textColor = [UIColor darkGrayColor];
        placeholderLabel.userInteractionEnabled = NO;
        placeholderLabel.adjustsFontSizeToFitWidth = YES;
        [self addSubview:placeholderLabel];

        hiddenField = [[UITextField alloc] initWithFrame:CGRectZero];
        hiddenField.delegate = self;
        hiddenField.hidden = YES;
        hiddenField.text = @"\u200B";
        [self addSubview:hiddenField];
    }

    return self;
}

- (void) syncPlaceholderStyle
{
    placeholderLabel.font = textField.font;
    placeholderLabel.backgroundColor = textField.backgroundColor;
}

- (BOOL) isEditing
{
    return [textField isEditing] || [hiddenField isEditing];
}

- (void) clear
{
    textField.text = [textField.text substringToIndex:1];
}

- (void) layoutSubviews
{
    [super layoutSubviews];

    textField.frame = self.bounds;
    placeholderLabel.frame = self.bounds;
}

- (void) setShowPlaceholder:(BOOL)ishowPlaceholder
{
    showPlaceholder = ishowPlaceholder;

    [UIView animateWithDuration:0.3 animations:^{
        placeholderLabel.alpha = showPlaceholder ? 1 : 0;
    }];
}

- (void) setPlaceholder:(NSString *)placeholder
{
    placeholderLabel.text = placeholder;

    [self syncPlaceholderStyle];
}

- (NSString *) placeholder
{
    return placeholderLabel.text;
}

- (void) setHideCursor:(BOOL)ihideCursor
{
    hideCursor = ihideCursor;

    if (hideCursor) {
        [hiddenField becomeFirstResponder];
    } else {
        [hiddenField resignFirstResponder];
    }
}

#pragma mark - UITextFieldDelegate

- (void) textFieldDidChange:(UITextField *)atextField
{
    NSString *newText = [textField.text substringFromIndex:1];

    if ([delegate respondsToSelector:@selector(ddTextField:didChangeTextTo:)]) {
        [delegate ddTextField:self didChangeTextTo:newText];
    }
}

- (BOOL) textFieldShouldBeginEditing:(UITextField *)atextField
{
    if (atextField == textField) {
        if ([delegate respondsToSelector:@selector(ddTextFieldShouldBeginEditing:)]) {
            return [delegate ddTextFieldShouldBeginEditing:self];
        }
    }

    return YES;
}

- (void) textFieldDidBeginEditing:(UITextField *)atextField
{
    if (atextField == textField) {
        [UIView animateWithDuration:0.3 animations:^{
            placeholderLabel.alpha = 0;
        }];

        if ([delegate respondsToSelector:@selector(ddTextFieldDidBeginEditing:)]) {
            [delegate ddTextFieldDidBeginEditing:self];
        }
    }
}

- (BOOL) textFieldShouldEndEditing:(UITextField *)atextField
{
    if (atextField == textField) {
        if ([delegate respondsToSelector:@selector(ddTextFieldShouldEndEditing:)]) {
            return [delegate ddTextFieldShouldEndEditing:self];
        }
    }

    return YES;
}

- (void) textFieldDidEndEditing:(UITextField *)atextField
{
    if (atextField == textField)
    {
        if ([textField.text length] == 1 && showPlaceholder && !hideCursor) {
            [UIView animateWithDuration:0.3 animations:^{
                placeholderLabel.alpha = 1;
            }];
        }

        hideCursor = NO;

        if ([delegate respondsToSelector:@selector(ddTextFieldDidEndEditing:)]) {
            [delegate ddTextFieldDidEndEditing:self];
        }
    }
}

- (BOOL) textField:(UITextField *)atextField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (atextField == hiddenField)
    {
        if ([delegate respondsToSelector:@selector(ddTextFieldDeleteBackwardOnEmpty:)]) {
            [delegate ddTextFieldDeleteBackwardOnEmpty:self];
        }

        return NO;
    }
    else if (atextField == textField)
    {
        NSString *newText = [atextField.text stringByReplacingCharactersInRange:range withString:string];

        if ([newText length] == 0) {
            if ([delegate respondsToSelector:@selector(ddTextFieldDeleteBackwardOnEmpty:)]) {
                [delegate ddTextFieldDeleteBackwardOnEmpty:self];
            }
            return NO;
        }

        if ([delegate respondsToSelector:@selector(ddTextField:shouldChangeTextTo:)]) {
            return [delegate ddTextField:self shouldChangeTextTo:newText];
        }
    }

    return YES;
}

- (BOOL) textFieldShouldClear:(UITextField *)atextField
{
    if (atextField == textField) {
        if ([delegate respondsToSelector:@selector(ddTextFieldShouldClear:)]) {
            return [delegate ddTextFieldShouldClear:self];
        }
    }

    return YES;
}

- (BOOL) textFieldShouldReturn:(UITextField *)atextField
{
    if (atextField == hiddenField)
    {
        [hiddenField resignFirstResponder];
        if ([textField.text length] == 1 && showPlaceholder) {
            [UIView animateWithDuration:0.3 animations:^{
                placeholderLabel.alpha = 1;
            }];
        }
        if ([delegate respondsToSelector:@selector(ddTextFieldWillReturn:)]) {
            [delegate ddTextFieldWillReturn:self];
        }
    }
    else if (atextField == textField)
    {
        if ([delegate respondsToSelector:@selector(ddTextFieldShouldReturn:)]) {
            BOOL result = [delegate ddTextFieldShouldReturn:self];
            if (result) {
                if ([delegate respondsToSelector:@selector(ddTextFieldWillReturn:)]) {
                    [delegate ddTextFieldWillReturn:self];
                }
            }
            return result;
        }
    }

    return YES;
}

@end

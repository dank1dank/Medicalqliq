//
//  DeleteDetectingTextField.h
//  CarZ
//
//  Created by Ivan Zezyulya on 04.04.12.
//  Copyright (c) 2012 Al Digit. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol DeleteDetectingTextFieldDelegate;


@interface DeleteDetectingTextField : UIView

@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) NSString *placeholder;
@property (nonatomic) BOOL showPlaceholder;
@property (nonatomic) BOOL hideCursor;
@property (nonatomic, unsafe_unretained) id <DeleteDetectingTextFieldDelegate> delegate;

- (void) clear;
- (void) syncPlaceholderStyle;
- (BOOL) isEditing;

@end


@protocol DeleteDetectingTextFieldDelegate <NSObject>

@optional

- (BOOL) ddTextFieldShouldBeginEditing:(DeleteDetectingTextField *)textField;
- (void) ddTextFieldDidBeginEditing:(DeleteDetectingTextField *)textField;
- (BOOL) ddTextFieldShouldEndEditing:(DeleteDetectingTextField *)textField;
- (void) ddTextFieldDidEndEditing:(DeleteDetectingTextField *)textField;

- (BOOL) ddTextField:(DeleteDetectingTextField *)textField shouldChangeTextTo:(NSString *)newText;
- (void) ddTextField:(DeleteDetectingTextField *)textField didChangeTextTo:(NSString *)newText;

- (BOOL) ddTextFieldShouldClear:(DeleteDetectingTextField *)textField;
- (BOOL) ddTextFieldShouldReturn:(DeleteDetectingTextField *)textField;
- (void) ddTextFieldWillReturn:(DeleteDetectingTextField *)textField;

- (void) ddTextFieldDeleteBackwardOnEmpty:(DeleteDetectingTextField *)textField;

@end

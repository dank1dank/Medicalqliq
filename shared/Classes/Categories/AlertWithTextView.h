//
//  AlertWithTextView.h
//  
//
//  Created by MK on 8/25/11.
//  Copyright 2011 AlDigit. All rights reserved.
//


#import <UIKit/UIKit.h>


@interface AlertWithTextView : UIAlertView <UIAlertViewDelegate> {
	NSString    * message;
	NSString    * hint;
	UILabel     * messageLabel;
	UILabel     * hintLabel;
	UITextField * textField;
}

@property (nonatomic, strong)   UITextField * textField;
@property (nonatomic, retain) NSString    * enteredText;

- (id)initWithTitle:(NSString *)title message:(NSString *)message hint:(NSString *)hint completionBlock:(void (^)(NSUInteger buttonIndex))block cancelButtonTitle:(NSString *)cancelButtonTitle okButtonTitle:(NSString *)okButtonTitle;

@end
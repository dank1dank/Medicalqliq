//
//  AlertWithTextView.m
//  
//
//  Created by MK on 8/25/11.
//  Copyright 2011 AlDigit. All rights reserved.
//


#import <QuartzCore/QuartzCore.h>
#import "AlertWithTextView.h"
#import <objc/runtime.h>

@interface AlertWithTextView()

-(void) createSubviews;

@end


@implementation AlertWithTextView


@synthesize textField;
@synthesize enteredText;


- (id)initWithTitle:(NSString *)title message:(NSString *)_message hint:(NSString *)_hint completionBlock:(void (^)(NSUInteger buttonIndex))block cancelButtonTitle:(NSString *)cancelButtonTitle okButtonTitle:(NSString *)okButtonTitle {
	if ((self = [super initWithTitle:title message:nil delegate:self cancelButtonTitle:cancelButtonTitle otherButtonTitles:okButtonTitle, nil])) {
		
        objc_setAssociatedObject(self, "blockCallback", [block copy], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        message			= (_message)?[[NSString alloc] initWithString:_message]:nil;
		hint			= (_hint)?[[NSString alloc] initWithString:_hint]:nil;
		[self createSubviews];
	}
	return self;
}

- (void)show {
	[textField becomeFirstResponder];
	[super show];
}


- (NSString *)enteredText {
	return textField.text;
}


- (void)createSubviews {
    self.alertViewStyle = UIAlertViewStylePlainTextInput;
    textField = [self textFieldAtIndex:0];//since iOS5.0 no needs to add subviews for having UITextField on UIAlertView
    messageLabel						= [[UILabel alloc] initWithFrame:CGRectZero];
	messageLabel.text					= message;
	messageLabel.textColor				= [UIColor whiteColor];
	messageLabel.backgroundColor		= [UIColor clearColor];
	messageLabel.numberOfLines			= 0;
	messageLabel.textAlignment			= UITextAlignmentCenter;
	[self addSubview:messageLabel];
	
	hintLabel							= [[UILabel alloc] init];
	hintLabel.text						= hint;
	hintLabel.textColor					= [UIColor whiteColor];
	hintLabel.backgroundColor			= [UIColor clearColor];
	hintLabel.numberOfLines				= 0;
	hintLabel.textAlignment				= UITextAlignmentCenter;
	[self addSubview:hintLabel];
}


- (void)layoutSubviews {
	[super layoutSubviews];

	NSInteger fontSize		= [UIFont labelFontSize];
	UIFont * font			= [UIFont systemFontOfSize:fontSize];

	CGFloat lineHeight		= font.lineHeight;
	CGFloat sideOffset		= 12;
	CGFloat currentWidth	= MIN(self.frame.size.width - 2 * sideOffset, 260);
	CGFloat topOffset		= 60;
	
	if (self.frame.size.width > self.frame.size.height) {
		topOffset				= 40;
	}
	
	CGSize messageSize		= [message sizeWithFont:font constrainedToSize:CGSizeMake(currentWidth, 2 * lineHeight) lineBreakMode:UILineBreakModeWordWrap];
	messageLabel.frame		= CGRectMake(sideOffset, topOffset, currentWidth, messageSize.height);
	
    CGFloat yOffset         = (messageSize.height==0)?topOffset+30.0:topOffset + messageLabel.frame.size.height + 5;
	textField.frame			= CGRectMake(sideOffset, yOffset, currentWidth, lineHeight + 4);
	
    if (hint) {
        CGSize hintSize			= [hint sizeWithFont:font forWidth:currentWidth lineBreakMode:UILineBreakModeWordWrap];
        hintLabel.frame			= CGRectMake(sideOffset, topOffset + messageLabel.frame.size.height + textField.frame.size.height + 10, currentWidth, hintSize.height);
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    void (^block)(NSUInteger buttonIndex) = objc_getAssociatedObject(self, "blockCallback");
    block(buttonIndex);
}

@end
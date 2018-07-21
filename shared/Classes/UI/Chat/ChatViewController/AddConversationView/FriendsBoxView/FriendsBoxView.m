//
//  FriendsBoxView.m
//  CarZ
//
//  Created by Ivan Zezyulya on 30.03.12.
//  Copyright (c) 2012 Al Digit. All rights reserved.
//

#import "FriendsBoxView.h"
#import "RoundedRectLabel.h"
#import "UIViewExtras.h"
#import "UILabelExtras.h"
#import "DispatchExtras.h"
#import "DeleteDetectingTextField.h"

@interface FriendsBoxView () <DeleteDetectingTextFieldDelegate>
- (void) layout;
@end

@implementation FriendsBoxView {
    NSMutableArray *riders;
    NSMutableArray *labels;
    UILabel *whoAreYouWithLabel;
    DeleteDetectingTextField *inputField;
}

@synthesize delegate;
@dynamic ridersNumber;

- (id) initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        riders = [NSMutableArray new];
        labels = [NSMutableArray new];

        self.backgroundColor = [UIColor whiteColor];

        inputField = [[DeleteDetectingTextField alloc] initWithFrame:CGRectMake(0, 0, 0, 20)];
        inputField.textField.font = [UIFont systemFontOfSize:15];
        //inputField.textField.returnKeyType = UIReturnKeyDone;
        inputField.placeholder = @"Who you are with?";
        inputField.delegate = self;

        [self addSubview:inputField];

        [self layout];
    }

    return self;
}

- (void) layout
{
    float minX = 5;
    float maxX = self.width - 5;
    float gapX = 7;
    float lineStep = [RoundedRectLabel height] + 5;
    float x = minX;
    float y = 5;

    // Layout labels

    for (RoundedRectLabel *label in labels)
    {
        if (x + gapX + label.width > maxX) {
            y += lineStep;
            x = minX;
        }
        label.X = x;
        label.Y = y;

        x += gapX + label.width;
    }

    // Layout input field

    if (x + gapX + 50 > maxX) {
        y += lineStep;
        x = minX;
    }

    inputField.x = x;
    inputField.y = y + 2;
    inputField.width = maxX - inputField.x;

    // Update frame

    CGRect newFrame = self.frame;
    newFrame.size.height = y + lineStep;

    if (!CGRectEqualToRect(newFrame, self.frame))
    {
        self.frame = newFrame;

        if ([delegate respondsToSelector:@selector(friendsBoxViewDidChangeFrame:)]) {
            [delegate friendsBoxViewDidChangeFrame:self];
        }
    }
}

- (int) ridersNumber
{
    return [riders count];
}


- (void) addRecipient:(id<Recipient> )recipient
{
    [riders addObject:recipient];

    RoundedRectLabel *label = [[RoundedRectLabel alloc] initWithText:[recipient recipientTitle]];
    label.alpha = 0;

    [labels addObject:label];
    [self addSubview:label];

    [UIView animate:^{
        [self layout];
        label.alpha = 1;
    }];

    if ([riders count] == 1) {
        inputField.showPlaceholder = NO;
    }
}

- (void) removeRecipient:(id<Recipient>)recipient
{
    NSUInteger index = [riders indexOfObject:recipient];

    if (index == NSNotFound) {
        return;
    }

    RoundedRectLabel *label = [labels objectAtIndex:index];

    [labels removeObject:label];
    [riders removeObject:recipient];

    [UIView animate:^{
        label.alpha = 0;
        [self layout];
    } completion:^{
        [label removeFromSuperview];
    }];

    DDLogInfo(@"[riders count] = %d", [riders count]);
    DDLogInfo(@"inputField = %@", inputField);

    if ([riders count] == 0) {
        inputField.showPlaceholder = YES;
    }
}

- (void) highlightOrDeleteLastRider
{
    if ([riders count] == 0) {
        return;
    }

    inputField.hideCursor = YES;

    RoundedRectLabel *lastLabel = [labels lastObject];
    id <Recipient> lastRider = [riders lastObject];

    if (!lastLabel.highlighted) {
        [UIView animate:^{
            lastLabel.highlighted = YES;
        }];
    } else {
        if ([delegate respondsToSelector:@selector(friendsBoxViewWantsRemoveRider:)]) {
            [delegate friendsBoxViewWantsRemoveRecipient:lastRider];
        }
    }
}

#pragma mark - UITextFieldDelegate

- (void) ddTextFieldDeleteBackwardOnEmpty:(DeleteDetectingTextField *)textField
{
    [self highlightOrDeleteLastRider];
}

- (void) ddTextField:(DeleteDetectingTextField *)textField didChangeTextTo:(NSString *)newText
{
    if ([delegate respondsToSelector:@selector(friendsBoxViewInputFieldDidChangeTextTo:)]) {
        [delegate friendsBoxViewInputFieldDidChangeTextTo:newText];
    }
}

- (void) ddTextFieldDidBeginEditing:(DeleteDetectingTextField *)textField
{
    Dispatch_ToMainThread(^{
        if ([delegate respondsToSelector:@selector(friendsBoxViewInputFieldDidBeginEditing)]) {
            [delegate friendsBoxViewInputFieldDidBeginEditing];
        }
    });
}

- (void) ddTextFieldDidEndEditing:(DeleteDetectingTextField *)textField
{
    if ([delegate respondsToSelector:@selector(friendsBoxViewInputFieldDidEndEditing)]) {
        [delegate friendsBoxViewInputFieldDidEndEditing];
    }
}

- (BOOL) ddTextFieldShouldReturn:(DeleteDetectingTextField *)textField
{
    [textField.textField resignFirstResponder];

    return YES;
}

@end

//
//  UITextField+CategoryTextField.m
//  qliq
//
//  Created by Valeriy Lider on 9/12/14.
//
//

#import "UITextField+CategoryTextField.h"

@implementation UITextField (CategoryTextField)

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.autocapitalizationType = UITextAutocorrectionTypeNo;
    }
    return self;
}

@end

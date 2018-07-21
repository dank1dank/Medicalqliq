//
//  UIButton+Blocks.h
//  qliq
//
//  Created by Valerii Lider on 12/12/13.
//
//

#import <UIKit/UIKit.h>

@interface UIButton (Blocks)

- (void)addBlock:(void (^)(UIButton *sender))actionBlock forControlEvents:(UIControlEvents)controlEvents;

@end

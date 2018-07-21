//
//  UIImage+ScaleAndRotate.h
//  qliqConnect
//
//  Created by Paul Bar on 12/16/11.
//  Copyright (c) 2011 Al Digit. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (ScaleAndRotate)

- (UIImage*) scaleAndRotate;
- (UIImage*) scaleWithMaxResolution:(NSInteger)maxResolution;

@end
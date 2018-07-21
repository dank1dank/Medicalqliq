//
//  MyUIImageHelper.m
//  OxibeoApp
//
//  Created by Aleksey on 02.06.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "UIImageViewHelper.h"


@implementation UIImageView (UIImageView_Frame)


- (CGRect) imageFrame{
	CGRect _imageFrame;
	switch (self.contentMode) {
        case UIViewContentModeScaleAspectFit:
            if ((self.image.size.height / self.image.size.width) > (self.frame.size.height/self.frame.size.width)) {
                _imageFrame.size.width  = (self.frame.size.height / (self.image.size.height / self.image.size.width));
                _imageFrame.size.height = self.frame.size.height;
                _imageFrame.origin = CGPointMake((self.frame.size.width - _imageFrame.size.width)/2, 0);
            }else{//fit by width
                _imageFrame.size.height = (self.frame.size.width / (self.image.size.width / self.image.size.height));
                _imageFrame.size.width  = self.frame.size.width;
                _imageFrame.origin = CGPointMake(0, (self.frame.size.height - _imageFrame.size.height)/2);
            }
            break;
        case UIViewContentModeScaleToFill:
        default:
            _imageFrame = self.frame;
            NSLog(@"[UIImageView imageFrame] method not implemented for this content mode. Returned value as for UIViewContentModeScaleToFill");
            break;
    }
    
	return _imageFrame;
}

- (CGFloat) imageScale{
	CGRect imageFrame = [self imageFrame];
	return self.image.size.height /  imageFrame.size.height;
}


@end

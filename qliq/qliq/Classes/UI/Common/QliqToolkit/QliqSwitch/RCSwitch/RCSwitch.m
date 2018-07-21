/*g
 Copyright (c) 2010 Robert Chin
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

#import "RCSwitch.h"
#import <QuartzCore/QuartzCore.h>

@interface RCSwitch ()
- (void)regenerateImages;
- (void)performSwitchToPercent:(float)toPercent;
@end

@implementation RCSwitch{
    UIImageView * knobImageView;
    
    UIImageView * sliderOnImageView;
    UIImageView * sliderOffImageView;
    
    UIImageView * overlayMaskImageView;
    CALayer * overlayMaskLayer;
    UIView * onSliderMaskView;
    
    void(^animationEndedBlock)(void);
}

- (void)initCommon
{
    drawHeight = 28;
	/* It seems that the animation length was changed in iOS 4.0 to animate the switch slower. */
	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_4_0){
		animationDuration = 0.25;
	} else {
		animationDuration = 0.175;
	}
	self.contentMode = UIViewContentModeRedraw;
	[self setKnobWidth:30];
	[self regenerateImages];
	sliderOff = [[UIImage imageNamed:@"btn_slider_off.png"] stretchableImageWithLeftCapWidth:12.0
																				 topCapHeight:0.0];
    /*Create image views*/
    sliderOffImageView = [[UIImageView alloc] init];
    [self addSubview:sliderOffImageView];
    
    sliderOnImageView = [[UIImageView alloc] init];
    [self addSubview:sliderOnImageView];
    
    sliderOnImageView.autoresizingMask = sliderOffImageView.autoresizingMask =
    UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    
    overlayView = [[UIView alloc] initWithFrame:self.bounds];
    overlayView.userInteractionEnabled = NO;
    [self addSubview:overlayView];
    
    knobImageView = [[UIImageView alloc] init];
    [self addSubview:knobImageView];
    
    
    /*Create mask views*/
    overlayMaskImageView = [[UIImageView alloc] init];
    overlayMaskLayer = [[CALayer alloc] init];
    onSliderMaskView = [[UIView alloc] init];
    onSliderMaskView.backgroundColor = [UIColor whiteColor];
    
    knobImageOffset = CGSizeZero;
    
	if([[UIScreen mainScreen] respondsToSelector:@selector(scale)])
		scale = [[UIScreen mainScreen] scale];
	else
		scale = 1.0;
	self.opaque = NO;
}

- (id)initWithFrame:(CGRect)aRect
{
	if((self = [super initWithFrame:aRect])){
		[self initCommon];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	if((self = [super initWithCoder:aDecoder])){
		[self initCommon];
	}
	return self;
}


- (void)setKnobWidth:(float)aFloat
{
	knobWidth = roundf(aFloat); // whole pixels only
	endcapWidth = roundf(knobWidth / 2.0);
	
	{
		UIImage *knobTmpImage = [UIImage imageNamed:@"btn_slider_thumb.png"];
		UIImage *knobImageStretch = [knobTmpImage stretchableImageWithLeftCapWidth:12.0
																	  topCapHeight:0.0];
		CGRect knobRect = CGRectMake(0, 0, knobWidth, [knobImageStretch size].height);

		if(&UIGraphicsBeginImageContextWithOptions != NULL)
			UIGraphicsBeginImageContextWithOptions(knobRect.size, NO, scale);
		else
			UIGraphicsBeginImageContext(knobRect.size);

		[knobImageStretch drawInRect:knobRect];
		knobImage = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();	
	}
	
	{
		UIImage *knobTmpImage = [UIImage imageNamed:@"btn_slider_thumb_pressed.png"];
		UIImage *knobImageStretch = [knobTmpImage stretchableImageWithLeftCapWidth:12.0
																	  topCapHeight:0.0];
		CGRect knobRect = CGRectMake(0, 0, knobWidth, [knobImageStretch size].height);
		if(&UIGraphicsBeginImageContextWithOptions != NULL)
			UIGraphicsBeginImageContextWithOptions(knobRect.size, NO, scale);
		else
			UIGraphicsBeginImageContext(knobRect.size);
		[knobImageStretch drawInRect:knobRect];
		knobImagePressed = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();	
	}
}

- (float)knobWidth
{
	return knobWidth;
}




- (void)regenerateImages
{
	CGRect boundsRect = self.bounds;
	UIImage *sliderOnBase = [[UIImage imageNamed:@"btn_slider_on.png"] stretchableImageWithLeftCapWidth:12.0
																						   topCapHeight:0.0];
	sliderOn = sliderOnBase;
	
	{
		UIImage *buttonTmpImage = [UIImage imageNamed:@"btn_slider_track.png"];
		UIImage *buttonEndTrackBase = [buttonTmpImage stretchableImageWithLeftCapWidth:12.0
																		  topCapHeight:0.0];
		CGRect sliderOnRect = boundsRect;
		/* works around < 4.0 bug with not scaling height (see http://stackoverflow.com/questions/785986/resizing-an-image-with-stretchableimagewithleftcapwidth) */
		if(&UIGraphicsBeginImageContextWithOptions != NULL)
			UIGraphicsBeginImageContextWithOptions(sliderOnRect.size, NO, scale);
		else {
			UIGraphicsBeginImageContext(sliderOnRect.size);
		}
		[buttonEndTrackBase drawInRect:sliderOnRect];
		buttonEndTrack = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();		
	}
	
	{
		UIImage *buttonTmpImage = [UIImage imageNamed:@"btn_slider_track_pressed.png"];
		UIImage *buttonEndTrackBase = [buttonTmpImage stretchableImageWithLeftCapWidth:12.0
																		  topCapHeight:0.0];
		CGRect sliderOnRect = boundsRect;
		if(&UIGraphicsBeginImageContextWithOptions != NULL)
			UIGraphicsBeginImageContextWithOptions(sliderOnRect.size, NO, scale);
		else
			UIGraphicsBeginImageContext(sliderOnRect.size);		
		[buttonEndTrackBase drawInRect:sliderOnRect];
		buttonEndTrackPressed = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();		
	}
}

- (void)drawUnderlayersInRect:(CGRect)aRect withOffset:(float)offset inTrackWidth:(float)trackWidth
{
}

- (void) switchAnimationDidStop{
    if (animationEndedBlock) {
        animationEndedBlock();
        animationEndedBlock = nil;
    }
}


- (void)drawRect:(CGRect)rect
{
	CGRect boundsRect = self.bounds;
    boundsRect.size.height = drawHeight;
	if(!CGSizeEqualToSize(boundsRect.size, lastBoundsSize)){
		[self regenerateImages];
		lastBoundsSize = boundsRect.size;
	}
	
	float width = boundsRect.size.width;
	float drawPercent = percent;
	if(((width - knobWidth) * drawPercent) < 3)
		drawPercent = 0.0;
	if(((width - knobWidth) * drawPercent) > (width - knobWidth - 3))
		drawPercent = 1.0;
	
	if(endDate){
		NSTimeInterval interval = [endDate timeIntervalSinceNow];
		if(interval < 0.0){
			endDate = nil;
		} else {
			if(percent == 1.0)
				drawPercent = cosf((interval / animationDuration) * (M_PI / 2.0));
			else
				drawPercent = 1.0 - cosf((interval / animationDuration) * (M_PI / 2.0));
			[self performSelector:@selector(setNeedsDisplay) withObject:nil afterDelay:0.0];
		}
	}
	self.layer.masksToBounds = NO;
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	
    CGContextSaveGState(context);
    UIGraphicsPushContext(context);
    
		if(drawPercent == 0.0){
			CGRect insetClipRect = boundsRect;
			insetClipRect.origin.x += endcapWidth;
			insetClipRect.size.width -= endcapWidth;
			UIRectClip(insetClipRect);
		}

		if(drawPercent == 1.0){
			CGRect insetClipRect = boundsRect;
			insetClipRect.size.width -= endcapWidth;
			UIRectClip(insetClipRect);
		}

    {
        CGRect sliderOffRect = boundsRect;
        sliderOffRect.size.height = [sliderOff size].height;
        
        sliderOffImageView.image = sliderOff;
        sliderOffImageView.frame = sliderOffRect;
        
    }
    
    if(drawPercent > 0.0){
        
        sliderOnImageView.hidden = NO;
        
        float onWidth = knobWidth / 2 + ((width - knobWidth / 2) - knobWidth / 2) * drawPercent;
        
        CGRect drawOnRect = CGRectMake(0, 0, onWidth, [sliderOn size].height);
        
        
        sliderOnImageView.image = sliderOn;
        sliderOnImageView.frame = CGRectMake(0, 0, self.bounds.size.width, sliderOn.size.height);
        

        onSliderMaskView.frame = drawOnRect;
        sliderOnImageView.layer.mask = onSliderMaskView.layer;

        
        
    }else{
        sliderOnImageView.hidden = YES;
    }
    
    {
        CGContextSaveGState(context);
        UIGraphicsPushContext(context);

        /*add mask to overlay view*/
        if (overlayMaskImageView.image != sliderOff){
            [overlayMaskImageView.layer removeFromSuperlayer];
            overlayMaskImageView.image = sliderOff;
            overlayMaskImageView.frame = sliderOffImageView.frame;
            
            [overlayMaskLayer addSublayer:overlayMaskImageView.layer];
            overlayView.layer.mask = overlayMaskLayer;
        }
        
        [self drawUnderlayersInRect:rect
                         withOffset:drawPercent * (boundsRect.size.width - knobWidth + knobEndcapOffset.width*2) - knobEndcapOffset.width
                       inTrackWidth:(boundsRect.size.width - knobWidth)];
        
        
        UIGraphicsPopContext();
        CGContextRestoreGState(context);
    }
    
    {
        CGContextScaleCTM(context, 1.0, -1.0);
        CGContextTranslateCTM(context, 0.0, -boundsRect.size.height);
        CGPoint location = boundsRect.origin;
        UIImage *imageToDraw = knobImage;
        if(self.highlighted)
            imageToDraw = knobImagePressed;
        
        
        CGRect drawOnRect = CGRectMake(-knobEndcapOffset.width + location.x - 1 + roundf(drawPercent * (boundsRect.size.width - knobWidth + 2 + knobEndcapOffset.width*2)),
                                       location.y, knobWidth, [knobImage size].height);
        
        drawOnRect.origin.y = location.y + roundf((self.bounds.size.height - drawOnRect.size.height) / 2);
        drawOnRect.origin.x += knobImageOffset.width;
        drawOnRect.origin.y += knobImageOffset.height;
        
        knobImageView.frame = drawOnRect;
        knobImageView.image = imageToDraw;
        
    }
    UIGraphicsPopContext();
    CGContextRestoreGState(context);
	
	
	if(drawPercent == 0.0 || drawPercent == 1.0){
		CGContextSaveGState(context);
		CGContextScaleCTM(context, 1.0, -1.0);
		CGContextTranslateCTM(context, 0.0, -boundsRect.size.height);	
		
		UIImage *buttonTrackDrawImage = buttonEndTrack;
		if(self.highlighted)
			buttonTrackDrawImage = buttonEndTrackPressed;
		
		if(drawPercent == 0.0){
			CGRect sourceRect = CGRectMake(0, 0.0, floorf(endcapWidth * scale), [buttonTrackDrawImage size].height * scale);
			CGRect drawOnRect = CGRectMake(0, 0.0, floorf(endcapWidth), [buttonTrackDrawImage size].height);
			CGImageRef buttonTrackSubImage = CGImageCreateWithImageInRect([buttonTrackDrawImage CGImage], sourceRect);
            CGRect drawIntoRect = drawOnRect;
            drawIntoRect.origin.y = 1;
			CGContextDrawImage(context, drawIntoRect, buttonTrackSubImage);
			CGImageRelease(buttonTrackSubImage);		
		}
		
		if(drawPercent == 1.0){
			CGRect sourceRect = CGRectMake(([buttonTrackDrawImage size].width - endcapWidth) * scale, 0.0, endcapWidth * scale, [buttonTrackDrawImage size].height * scale);
			CGRect drawOnRect = CGRectMake(boundsRect.size.width - ceilf(endcapWidth), 0.0, ceilf(endcapWidth), [buttonTrackDrawImage size].height);
			CGImageRef buttonTrackSubImage = CGImageCreateWithImageInRect([buttonTrackDrawImage CGImage], sourceRect);
            CGRect drawIntoRect = drawOnRect;
            drawIntoRect.origin.y = 1;
			CGContextDrawImage(context, drawIntoRect, buttonTrackSubImage);
			CGImageRelease(buttonTrackSubImage);
		}
		
		CGContextRestoreGState(context);
        if (!endDate) [self switchAnimationDidStop];
	}	
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	self.highlighted = YES;
	oldPercent = percent;
	endDate = nil;
	mustFlip = YES;
	[self setNeedsDisplay];
	[self sendActionsForControlEvents:UIControlEventTouchDown];
	return YES;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	CGPoint point = [touch locationInView:self];
	percent = (point.x - knobWidth / 2.0) / (self.bounds.size.width - knobWidth);
	if(percent < 0.0)
		percent = 0.0;
	if(percent > 1.0)
		percent = 1.0;
	if((oldPercent < 0.25 && percent > 0.5) || (oldPercent > 0.75 && percent < 0.5))
		mustFlip = NO;
	[self setNeedsDisplay];
	[self sendActionsForControlEvents:UIControlEventTouchDragInside];
	return YES;
}

- (void)finishEvent
{
	self.highlighted = NO;
	endDate = nil;
	float toPercent = roundf(1.0 - oldPercent);
	if(!mustFlip){
		if(oldPercent < 0.25){
			if(percent > 0.5)
				toPercent = 1.0;
			else
				toPercent = 0.0;
		}
		if(oldPercent > 0.75){
			if(percent < 0.5)
				toPercent = 0.0;
			else
				toPercent = 1.0;
		}
	}
	[self performSwitchToPercent:toPercent];
}

- (void)cancelTrackingWithEvent:(UIEvent *)event
{
	[self finishEvent];
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	[self finishEvent];
}

- (BOOL)isOn
{
	return percent > 0.5;
}

- (void)setOn:(BOOL)aBool
{
	[self setOn:aBool animated:NO];
}

- (void)setOn:(BOOL)aBool animated:(BOOL)animated
{
	if(animated){
		float toPercent = aBool ? 1.0 : 0.0;
		if((percent < 0.5 && aBool) || (percent > 0.5 && !aBool))
			[self performSwitchToPercent:toPercent];
	} else {
		percent = aBool ? 1.0 : 0.0;
		[self setNeedsDisplay];
		[self sendActionsForControlEvents:UIControlEventValueChanged];
	}
}

- (void)performSwitchToPercent:(float)toPercent
{
	endDate = [NSDate dateWithTimeIntervalSinceNow:fabsf(percent - toPercent) * animationDuration];
	percent = toPercent;
	[self setNeedsDisplay];
	[self sendActionsForControlEvents:UIControlEventTouchUpInside];
    
    __unsafe_unretained id selfPointer = self;
    animationEndedBlock = ^{
        [selfPointer sendActionsForControlEvents:UIControlEventValueChanged];
    };
    
}

//- (void)layoutSubviews{
//    
//    CGRect sliderOffRect = self.bounds;
//    sliderOffRect.origin.y = roundf((self.bounds.size.height - sliderOff.size.height)/2);
//    sliderOffRect.size.height = sliderOff.size.height;
//    sliderOffImageView.frame  = sliderOffRect;
//    
//    CGRect sliderOnRect = self.bounds;
//    sliderOnRect.origin.y = roundf((self.bounds.size.height - sliderOn.size.height)/2);
//    sliderOnRect.size.height = sliderOn.size.height;
//    sliderOnImageView.frame  = sliderOnRect;
//    
//    
//    overlayView.frame = self.bounds;
////    knobImageView = [[UIImageView alloc] init];
//    [super layoutSubviews];
//    
//}

@end

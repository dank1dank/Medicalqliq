//
//  HPTextView.m
//
//  Created by Hans Pinckaers on 29-06-10.
//
//	MIT License
//
//	Copyright (c) 2011 Hans Pinckaers
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights
//	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the Software is
//	furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in
//	all copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//	THE SOFTWARE.

#import "HPGrowingTextView.h"
#import "EGOTextView.h"
#import <QuartzCore/QuartzCore.h>

@interface HPGrowingTextView(private)
-(void)commonInitialiser;
-(void)resizeTextView:(CGFloat)newSizeH;
-(void)growDidStop;
@end

@implementation HPGrowingTextView

@synthesize internalTextView;
@synthesize minHeight;
@synthesize maxHeight;

@synthesize animateHeightChange;

// having initwithcoder allows us to use HPGrowingTextView in a Nib. -- aob, 9/2011
- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
        [self commonInitialiser];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self commonInitialiser];
    }
    return self;
}


-(void)commonInitialiser
{
    // Initialization code
    CGRect r = self.frame;
    r.origin.y = 0;
    r.origin.x = 0;
    
//    UIImageView * textViewBackground = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"ConversationKeyboardTfBg"] stretchableImageWithLeftCapWidth:10 topCapHeight:10]];
//    [self addSubview:textViewBackground];
    
    internalTextView = [[EGOTextView alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 36.0)];
	internalTextView.accessibilityLabel = @"MessageInput";
    internalTextView.delegate = self;
    internalTextView.scrollEnabled = NO;
    internalTextView.font = [UIFont systemFontOfSize:13.0]; 
    internalTextView.showsHorizontalScrollIndicator = NO;
    internalTextView.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    //internalTextView.text = @"-";
    internalTextView.textInsets = UIEdgeInsetsMake(6.0,
                                                   8.0,
                                                   0.0,
                                                   8.0);
    
    internalTextView.frame = self.bounds;
    internalTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
//    textViewBackground.frame = CGRectMake(internalTextView.frame.origin.x, internalTextView.frame.origin.y + 1, internalTextView.frame.size.width, internalTextView.frame.size.height - 2);
//    textViewBackground.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    [self addSubview:internalTextView];
    self.minHeight = 0.0;
    self.maxHeight = 80.0;
    self.autoresizesSubviews = YES;
    internalTextView.text = @"";
    
}

- (void) setFrame:(CGRect)frame{
    [super setFrame:frame];

}


-(UIEdgeInsets)contentInset
{
    return contentInset;
}

-(void) egoTextViewSetupScroll
{
        if (internalTextView.contentSize.height >= internalTextView.frame.size.height)
        {
            if(!internalTextView.scrollEnabled){
                internalTextView.scrollEnabled = YES;
                [internalTextView flashScrollIndicators];
            }
            
        } else {
            internalTextView.scrollEnabled = NO;
        }
}


//- (void)textViewDidChange:(UITextView *)textView
-(void) egoTextViewDidChange:(EGOTextView *)textView
{	
	NSInteger newSizeH = internalTextView.contentSize.height;
    
	if(newSizeH < minHeight || !internalTextView.hasText)
    {
        newSizeH = minHeight;
    }
    if (newSizeH/*internalTextView.frame.size.height*/ > maxHeight)
    {
        newSizeH = maxHeight; // not taller than maxHeight
    }

	if (internalTextView.frame.size.height != newSizeH)
	{
        // [fixed] Pasting too much text into the view failed to fire the height change, 
        // thanks to Gwynne <http://blog.darkrainfall.org/>
        
        if (newSizeH > maxHeight && internalTextView.frame.size.height <= maxHeight)
        {
            newSizeH = maxHeight;
        }
        
		if (newSizeH <= maxHeight)
		{
            animateHeightChange = NO;
//            if(animateHeightChange) 
//            {
//                [UIView beginAnimations:@"" context:nil];
//                [UIView setAnimationDuration:0.2f];
//                [UIView setAnimationDelegate:self];
//                [UIView setAnimationDidStopSelector:@selector(growDidStop)];
//                [UIView setAnimationBeginsFromCurrentState:YES];
//                [self resizeTextView:newSizeH];
//                [UIView commitAnimations];
//            } 
//            else 
            {
                [self resizeTextView:newSizeH];                
//                [self growDidStop];
            }
		}
		
        
        // if our new height is greater than the maxHeight
        // sets not set the height or move things
        // around and enable scrolling
        
		if (newSizeH >= self.maxHeight)
		{
			if(!internalTextView.scrollEnabled){
				internalTextView.scrollEnabled = YES;
			}
			
		} else {
			internalTextView.scrollEnabled = NO;
		}
	}

	if ([self.delegate respondsToSelector:@selector(growingTextViewDidChange:)])
    {
		[self.delegate growingTextViewDidChange:self];
	}
	
}

-(void) egoTextView:(EGOTextView *)textView didChangeContentSize:(CGSize)size
{
    [self egoTextViewDidChange:textView];
}

-(void)resizeTextView:(CGFloat)newSizeH
{
//    if (fabs(self.frame.size.height - newSizeH) < 5)
//        return;

    if ([self.delegate respondsToSelector:@selector(growingTextView:willChangeHeight:)]) {
        [self.delegate growingTextView:self willChangeHeight:newSizeH];
    }
   
//    CGRect newFrame = self.frame;
//    newFrame.size.height = newSizeH;
//    self.frame = newFrame;
}

//-(void)growDidStop
//{
//	if ([self.delegate respondsToSelector:@selector(growingTextView:didChangeHeight:)]) {
//		[self.delegate growingTextView:self didChangeHeight:self.frame.size.height];
//	}
//	
//}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.internalTextView becomeFirstResponder];
}

- (BOOL)becomeFirstResponder
{
    
    [super becomeFirstResponder];
    return [self.internalTextView becomeFirstResponder];
}

-(BOOL)resignFirstResponder
{
	[super resignFirstResponder];
	return [self.internalTextView resignFirstResponder];
}

-(void)setText:(NSString *)newText
{
    self.internalTextView.text = newText;
    
    // include this line to analyze the height of the textview.
    // fix from Ankit Thakur
//    [self performSelector:@selector(egoTextViewDidChange:) withObject:internalTextView];
}

-(NSString*) text
{
    return internalTextView.text;
}


- (BOOL)hasText
{
	return [internalTextView hasText];
}

#pragma mark -
#pragma mark EGOTextViewDelegate

-(BOOL) egoTextViewShouldBeginEditing:(EGOTextView *)textView
{
	if ([self.delegate respondsToSelector:@selector(growingTextViewShouldBeginEditing:)])
    {
		return [self.delegate growingTextViewShouldBeginEditing:self];
		
	}
    else
    {
		return YES;
	}
}

-(BOOL) egoTextViewShouldEndEditing:(EGOTextView *)textView
{
	if ([self.delegate respondsToSelector:@selector(growingTextViewShouldEndEditing:)])
    {
		return [self.delegate growingTextViewShouldEndEditing:self];
		
	}
    else
    {
		return YES;
	}
}

-(void) egoTextViewDidBeginEditing:(EGOTextView *)textView
{
	if ([self.delegate respondsToSelector:@selector(growingTextViewDidBeginEditing:)]) {
		[self.delegate growingTextViewDidBeginEditing:self];
	}
}

-(void)egoTextViewDidEndEditing:(EGOTextView *)textView
{		
	if ([self.delegate respondsToSelector:@selector(growingTextViewDidEndEditing:)]) {
		[self.delegate growingTextViewDidEndEditing:self];
	}
}

-(void) egoTextViewDidChangeSelection:(EGOTextView *)textView
{
	if ([self.delegate respondsToSelector:@selector(growingTextViewDidChangeSelection:)])
    {
		[self.delegate growingTextViewDidChangeSelection:self];
	}
}

-(void) egoTextView:(EGOTextView *)textView willDeleteAttachment:(UIView *)attachment
{
    [self.delegate growingTextView:self willDeleteAttachment:attachment];
}

-(void) insertAttachment:(id)egoAttachmentCell
{
    [self.internalTextView insertAttachment:egoAttachmentCell];
    //[self.internalTextView appendText:@"\n"];
}

-(void) removeAttachments
{
    [self.internalTextView removeAttachments];
}

-(void) appendText:(NSString *)text_
{
    [self.internalTextView appendText:text_];
}





@end

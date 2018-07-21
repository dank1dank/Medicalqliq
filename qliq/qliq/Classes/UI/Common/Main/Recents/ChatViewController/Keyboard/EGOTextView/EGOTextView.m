 
//  EGOTextView.m
//
//  Created by Devin Doty on 4/18/11.
//  Copyright (C) 2011 by enormego.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "EGOTextView.h"
#import "MessageAttachment.h"
#import <QuartzCore/QuartzCore.h>

@interface NSMutableAttributedString (RangeCheck)
- (void)safeReplaceCharactersInRange:(NSRange)range withString:(NSString *)str;
- (void)safeReplaceCharactersInRange:(NSRange)range withAttributedString:(NSAttributedString *)attrString;
@end

@implementation NSMutableAttributedString (RangeCheck)

- (void)safeReplaceCharactersInRange:(NSRange)range withString:(NSString *)str {
    
    if (NSNotFound == range.location)
        range.location = 0U;
    
    // I removed that to avoid wrong symbols after typing from the QuickType Keyboard
    //    if (range.location >= self.length) {
    //        range.location = 0U;
    //    }
    
    if (range.location + range.length > self.length) {
        
        DDLogWarn(@"Attempt to call replaceCharactersInRange:withString: with invalid range(%@) for string (%@). Range will be normalized to fit string length", NSStringFromRange(range), self);
        
        range.length = self.length - range.location;
    }
    
    [self replaceCharactersInRange:range withString:str];
}

- (void)safeReplaceCharactersInRange:(NSRange)range withAttributedString:(NSAttributedString *)attrString {
    
    if (NSNotFound == range.location)
        range.location = 0U;
    
    // I removed that to avoid wrong symbols after typing from the QuickType Keyboard
    //    if (range.location >= self.length) {
    //        range.location = 0U;
    //    }
    
    if (range.location + range.length > self.length) {
        
        DDLogWarn(@"Attempt to call replaceCharactersInRange:withAttributedString: with invalid range(%@) for string (%@). Range will be normalized to fit string length", NSStringFromRange(range), self);
        
        range.length = self.length - range.location;
    }
    
    [self replaceCharactersInRange:range withAttributedString:attrString];
}

@end

NSString * const EGOTextAttachmentAttributeName = @"com.enormego.EGOTextAttachmentAttribute";
NSString * const EGOTextAttachmentPlaceholderString = @"\uFFFC";

typedef enum {
    EGOWindowLoupe = 0,
    EGOWindowMagnify,
} EGOWindowType;

typedef enum {
    EGOSelectionTypeLeft = 0,
    EGOSelectionTypeRight,
} EGOSelectionType;

// MARK: Text attachment helper functions
static void AttachmentRunDelegateDealloc(void *refCon) {
    //(__bridge id)refCon;
}

static CGSize AttachmentRunDelegateGetSize(void *refCon)
{
    id obj = (__bridge id) refCon;
    if([obj conformsToProtocol:@protocol(EGOTextAttachmentCell)])
    {
        id <EGOTextAttachmentCell> cell = (__bridge id) refCon;
        if ([cell respondsToSelector: @selector(attachmentSize)]) {
            return [cell attachmentSize];
        } else {
            return [[cell attachmentView] frame].size;
        }
    }
    else if ([obj isKindOfClass:[UIView class]])
    {
        UIView *view = (__bridge UIView *)refCon;
        return view.frame.size;
    }
    return CGSizeMake(0.0, 0.0);
}

static CGFloat AttachmentRunDelegateGetAscent(void *refCon) {
    return AttachmentRunDelegateGetSize(refCon).height;
    //return [UIFont systemFontOfSize:17].ascender;
}

static CGFloat AttachmnetRunDelegateGetDescent(void *refCon)
{
    //return 0.0;
    return - [UIFont systemFontOfSize:17].descender; //TODO when we are changing the default font, we need to change font here as well.
    //return AttachmentRunDelegateGetSize(refCon).height;
}

static CGFloat AttachmentRunDelegateGetWidth(void *refCon) {
    return AttachmentRunDelegateGetSize(refCon).width;
}

// MARK: EGOContentView definition

@interface EGOContentView : UIView {
@private
    __unsafe_unretained id _delegate;
}
@property(nonatomic,assign) id delegate;
@end

// MARK: EGOCaretView definition

@interface EGOCaretView : UIView {
    NSTimer *_blinkTimer;
}

- (void)delayBlink;
- (void)show;
@end


// MARK: EGOLoupeView definition

@interface EGOLoupeView : UIView {
@private
    UIImage *_contentImage;
}
- (void)setContentImage:(UIImage*)image;
@end


// MARK: MagnifyView definition

@interface EGOMagnifyView : UIView {
@private
    UIImage *_contentImage;
}
- (void)setContentImage:(UIImage*)image;
@end


// MARK: EGOTextWindow definition

@interface EGOTextWindow : UIWindow {
@private
    UIView              *_view;
    EGOWindowType       _type;
    EGOSelectionType    _selectionType;
    BOOL                _showing;
    
}
@property(nonatomic,assign) EGOWindowType type;
@property(nonatomic,assign) EGOSelectionType selectionType;
@property(nonatomic,readonly,getter=isShowing) BOOL showing;
- (void)setType:(EGOWindowType)type;
- (void)renderWithContentView:(UIView*)view fromRect:(CGRect)rect;

- (void)showFromView:(UIView*)view andRenderView:(UIView*)viewToRender rect:(CGRect)rect ;
- (void)showFromView:(UIView*)view rect:(CGRect)rect;
- (void)hide:(BOOL)animated;
- (void)updateWindowTransform;
@end


// MARK: EGOSelectionView definition

@interface EGOSelectionView : UIView {
@private
    UIView *_leftDot;
    UIView *_rightDot;
    UIView *_leftCaret;
    UIView *_rightCaret;
}
@property (nonatomic, readwrite, getter = isDotsHidden) BOOL dotsHidden;
- (void)setBeginCaret:(CGRect)begin endCaret:(CGRect)rect;
@end

// MARK: UITextPosition  definition

@interface EGOIndexedPosition : UITextPosition {
    NSUInteger               _index;
    id  <UITextInputDelegate> _inputDelegate;
}

@property (nonatomic) NSUInteger index;
+ (EGOIndexedPosition *)positionWithIndex:(NSUInteger)index;

@end

// MARK: UITextRange definition

@interface EGOIndexedRange : UITextRange {
    NSRange _range;
}

@property (nonatomic) NSRange range;
+ (EGOIndexedRange *)rangeWithNSRange:(NSRange)range;
@end

// MARK: EGOTextView private

@interface EGOTextView (Private)

- (CGRect)caretRectForIndex:(NSInteger)index;
- (CGRect)firstRectForNSRange:(NSRange)range;
- (NSInteger)closestIndexToPoint:(CGPoint)point;
- (NSRange)characterRangeAtPoint_:(CGPoint)point;
- (void)checkSpellingForRange:(NSRange)range;
- (void)textChanged;
- (void)removeCorrectionAttributesForRange:(NSRange)range;
- (void)insertCorrectionAttributesForRange:(NSRange)range;
- (void)showCorrectionMenuForRange:(NSRange)range;
- (void)checkLinksForRange:(NSRange)range;
- (void)scanAttachments;
- (void)showMenu;
- (CGRect)menuPresentationRect;

+ (UIColor *)selectionColor;
+ (UIColor *)spellingSelectionColor;
+ (UIColor *)caretColor;

@end

@interface EGOTextView ()
@property(nonatomic,retain) NSDictionary *defaultAttributes;
@property(nonatomic,retain) NSDictionary *correctionAttributes;
@property(nonatomic,retain) NSMutableDictionary *menuItemActions;
@property(nonatomic) NSRange correctionRange;
@property(nonatomic, assign) BOOL isVoiceText;
@end


@implementation EGOTextView

@synthesize delegate;
@synthesize attributedString=_attributedString;
@synthesize text=_text;
@synthesize font=_font;
@synthesize editable=_editable;
@synthesize markedRange=_markedRange;
@synthesize selectedRange=_selectedRange;
@synthesize correctionRange=_correctionRange;
@synthesize defaultAttributes=_defaultAttributes;
@synthesize correctionAttributes=_correctionAttributes;
@synthesize markedTextStyle=_markedTextStyle;
@synthesize inputDelegate=_inputDelegate;
@synthesize menuItemActions;

@synthesize dataDetectorTypes;
@synthesize autocapitalizationType;
@synthesize autocorrectionType;
@synthesize spellCheckingType;
@synthesize keyboardType;
@synthesize keyboardAppearance;
@synthesize returnKeyType;
@synthesize enablesReturnKeyAutomatically;
@synthesize textInsets;

@synthesize parentView;

@synthesize inputAccessoryView;

- (void)commonInit {
    
    [self setText:@""];
    self.alwaysBounceVertical = YES;
    self.editable = YES;
    self.font = [UIFont systemFontOfSize:17];
    //    self.backgroundColor = [UIColor whiteColor];
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.clipsToBounds = YES;
    
    //    EGOContentView *contentView = [[EGOContentView alloc] initWithFrame:CGRectInset(self.bounds, 8.0f, 8.0f)];
    EGOContentView *contentView = [[EGOContentView alloc] initWithFrame:CGRectMake(8.0,
                                                                                   8.0,
                                                                                   self.frame.size.width,
                                                                                   self.frame.size.height)];
    
    contentView.autoresizingMask = self.autoresizingMask;
    contentView.delegate = self;
    contentView.backgroundColor = [UIColor clearColor];
    [self addSubview:contentView];
    _textContentView = contentView;
    _textContentView.autoresizingMask = UIViewAutoresizingNone;
    
    UILongPressGestureRecognizer *gesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    gesture.delegate = (id<UIGestureRecognizerDelegate>)self;
    [self addGestureRecognizer:gesture];
    _longPress = gesture;
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
    [doubleTap setNumberOfTapsRequired:2];
    [self addGestureRecognizer:doubleTap];
    
    UITapGestureRecognizer *singleTap =  [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    [self addGestureRecognizer:singleTap];
    
    _attachmentViews = [[NSMutableArray alloc] init];
    
    self.superview.backgroundColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.3 alpha:0.3];
}

- (NSArray *)selectionRectsForRange:(UITextRange *)range
{
    return NULL;
}

- (UIView *) parentView{
    return [[[self superview] superview] superview]; //Yes, it is ugly and temroary. It is ChatInputAccessoryView class
}

-(void) layoutSubviews
{
    [super layoutSubviews];
}

-(void) setContentInset:(UIEdgeInsets)contentInset_
{
}

-(UIEdgeInsets) contentInset
{
    return UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self commonInit];
    }
    return self;
}

- (id)init {
    if ((self = [self initWithFrame:CGRectZero])) {}
    return self;
}

- (id)initWithCoder: (NSCoder *)aDecoder {
    if ((self = [super initWithCoder: aDecoder])) {
        [self commonInit];
    }
    return self;
}

- (void)dealloc {
    
    _attachmentViews = nil;
    _textWindow=nil;
    _font=nil;
    _attributedString=nil;
    _caretView=nil;
    self.menuItemActions=nil;
    self.defaultAttributes=nil;
    self.correctionAttributes=nil;
    
    if (_frame != NULL) CFRelease(_frame);
    if (_framesetter != NULL) CFRelease(_framesetter);
}

- (void)clearPreviousLayoutInformation {
    
    if (_framesetter != NULL) {
        CFRelease(_framesetter);
        _framesetter = NULL;
    }
    
    if (_frame != NULL) {
        CFRelease(_frame);
        _frame = NULL;
    }
}

- (CGFloat)boundingWidthForHeight:(CGFloat)height {
    
    CGSize suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(_framesetter, CFRangeMake(0, 0), NULL, CGSizeMake(CGFLOAT_MAX, height), NULL);
    return suggestedSize.width;
    
}

- (CGFloat)boundingHeightForWidth:(CGFloat)width {
    
    CGSize suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(_framesetter, CFRangeMake(0, 0), NULL, CGSizeMake(width, CGFLOAT_MAX), NULL);
    CGFloat rez = suggestedSize.height;
    
    if([_attributedString.string characterAtIndex:([_attributedString length] - 1)] == '\n')
    {
        rez += self.font.leading;
        
        if([[UIDevice currentDevice].systemVersion floatValue] >= 9.0)
        {
            /*
             Somewhy on iOS > 9.0 'self.font.leading' returns zero instead of value
             */
            rez += 22.0;
        }
    }
    
    if([[UIDevice currentDevice].systemVersion floatValue] < 5.0)
    {
        rez += 1.0; //i dont know why, but this makes it work on ios4x device
    }
    
    return rez;
    
}

- (void)textChanged {
    
    if ([[UIMenuController sharedMenuController] isMenuVisible]) {
        [[UIMenuController sharedMenuController] setMenuVisible:NO animated:NO];
    }
    
    CTFramesetterRef framesetter = _framesetter;
    _framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)self.attributedString);
    
    if (framesetter!=NULL) {
        CFRelease(framesetter);
    }
    
    CGRect rect = CGRectMake(self.textInsets.left,
                             self.textInsets.top,
                             self.frame.size.width - (self.textInsets.left + self.textInsets.right),
                             self.frame.size.height - (self.textInsets.top + self.textInsets.bottom));//_textContentView.frame;
    CGFloat height = [self boundingHeightForWidth:rect.size.width];
    rect.size.height = height;//+self.font.lineHeight;
    [UIView setAnimationsEnabled:NO];
    _textContentView.frame = rect;
    [UIView setAnimationsEnabled:YES];
    
    CGSize newContentSize = CGSizeMake(floor(self.frame.size.width),
                                       floor(_textContentView.frame.size.height+(self.textInsets.top + self.textInsets.bottom)));
    
    if (!CGSizeEqualToSize(newContentSize, self.contentSize))
    {
        [UIView animateWithDuration:0.2 animations:^{
            self.contentSize = newContentSize;
        }];
        
        [self.delegate egoTextView:self didChangeContentSize:self.contentSize];
    }
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:_textContentView.bounds];
    
    CTFrameRef frameRef = _frame;
    _frame =  CTFramesetterCreateFrame(_framesetter, CFRangeMake(0, 0), [path CGPath], NULL);
    if (frameRef!=NULL) {
        CFRelease(frameRef);
    }
    
    for (UIView *view in _attachmentViews) {
        if([view respondsToSelector:@selector(removeFromSuperview)])
        {
            [view removeFromSuperview];
        }
    }
    [self scanAttachments];
    __block NSUInteger numOfAttachmentAttributes = 0;
    [_attributedString enumerateAttribute: EGOTextAttachmentAttributeName inRange: NSMakeRange(0, [_attributedString length]) options: 0 usingBlock: ^(id value, NSRange range, BOOL *stop) {
        
        if([value conformsToProtocol:@protocol(EGOTextAttachmentCell)])
        {
            UIView *view = [value attachmentView];
            [_attachmentViews addObject: view];
            
            CGRect rect = [self firstRectForNSRange: range];
            rect.size = [view frame].size;
            
            [view setFrame: rect];
            [self addSubview: view];
        }
        else if([value isKindOfClass:[UIView class]])
        {
            UIView *view = (UIView*)value;
            [_attachmentViews addObject: view];
            
            CGRect rect = [self firstRectForNSRange: range];
            rect.size = [view frame].size;
            [view setFrame: rect];
            [self addSubview: view];
        }
        numOfAttachmentAttributes ++;
    }];
    //    NSLog(@"Num of attachment attributes: %d", numOfAttachmentAttributes); //Less spam in log is better. Think about it before 'push' =)
    [_textContentView setNeedsDisplay];
    
}

- (NSString *) stringWithoutAttachmentsNewlinesFrom:(NSAttributedString *) str{
    
    __block NSString * result = _attributedString.string;
    
    [_attributedString enumerateAttribute: EGOTextAttachmentAttributeName inRange: NSMakeRange(0, [_attributedString length]) options: 0 usingBlock: ^(id value, NSRange range, BOOL *stop) {
        NSRange _r;
        _r.location = range.location + range.length;
        _r.length = 1;
        
        if (_r.location < _attributedString.string.length && [[_attributedString.string substringWithRange:_r] isEqualToString:@"\n"]){
            result = [result stringByReplacingCharactersInRange:_r withString:@""];
        }
    }];
    
    NSString *attachmentSting = self.attachmentString.string;
    if (attachmentSting)
    {
        if ([result isEqualToString:attachmentSting])
            result = @"";
        else
            result = [result stringByReplacingOccurrencesOfString:attachmentSting withString:@""];
    }
    return result;
}

- (NSString *)textAsciiOnly //aii
//- (NSString *)text
{
    // we cant send non-ascii symbols because schema validator cant handle it right
    // when validator will be fixed this method will be:
    //return _attributedString.string;
    
    NSMutableString *asciiCharacters = [NSMutableString string];
    for (NSInteger i = 32; i < 127; i++)  { //Aleksey: why from 32, not from 0? //because http://en.wikipedia.org/wiki/ASCII?control#ASCII_control_characters
        [asciiCharacters appendFormat:@"%ld", (long)i]; //!!!! DONT CHANGE %C, its critical !!!!
    }
    [asciiCharacters appendString:@"\n"];   //fix to enable '\n' character
    
    NSCharacterSet *nonAsciiCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:asciiCharacters] invertedSet];
    
    NSString *string = [self stringWithoutAttachmentsNewlinesFrom:_attributedString];
    NSArray *array = [string componentsSeparatedByCharactersInSet:nonAsciiCharacterSet];
    string = [array componentsJoinedByString:@""];
    return string;
}

- (NSString *)text {
    return [self stringWithoutAttachmentsNewlinesFrom:_attributedString];
}

- (void)setFont:(UIFont *)font {
    
    _font = font;
    
    CTFontRef ctFont = CTFontCreateWithName((__bridge CFStringRef) self.font.fontName, self.font.pointSize, NULL);
    NSDictionary *dictionary = [[NSDictionary alloc] initWithObjectsAndKeys:
                                (__bridge id)ctFont, (NSString *)kCTFontAttributeName,
                                (id)[UIColor blackColor].CGColor, kCTForegroundColorAttributeName,
                                nil];
    self.defaultAttributes = dictionary;
    
    CFRelease(ctFont);
    
    [self textChanged];
    
}

- (void)setText:(NSString *)text
{
    [self.inputDelegate textWillChange:self];
    
    NSAttributedString *string = [[NSAttributedString alloc] initWithString:text attributes:self.defaultAttributes];
    [self setAttributedString:string];
    [self.inputDelegate textDidChange:self];
    self.selectedRange = NSMakeRange(text.length, 0);
    self.markedRange = NSMakeRange(text.length, 0);
}

- (void)setAttributedString:(NSAttributedString*)string {
    
    @synchronized(self) {
        
        _attributedString = [string copy];
        
        NSRange range = NSMakeRange(0, _attributedString.string.length);
        if (!_editing && !_editable) {
            [self checkLinksForRange:range];
            [self scanAttachments];
        }
        
        [self textChanged];
        
        if (_delegateRespondsToDidChange) {
            [self.delegate egoTextViewDidChange:self];
        }
    }
}

- (void)setDelegate:(id<EGOTextViewDelegate>)aDelegate {
    if (aDelegate) {
        [super setDelegate:(id<UIScrollViewDelegate>)aDelegate];
    }
    delegate = aDelegate;
    
    _delegateRespondsToShouldBeginEditing = [delegate respondsToSelector:@selector(egoTextViewShouldBeginEditing:)];
    _delegateRespondsToShouldEndEditing = [delegate respondsToSelector:@selector(egoTextViewShouldEndEditing:)];
    _delegateRespondsToDidBeginEditing = [delegate respondsToSelector:@selector(egoTextViewDidBeginEditing:)];
    _delegateRespondsToDidEndEditing = [delegate respondsToSelector:@selector(egoTextViewDidEndEditing:)];
    _delegateRespondsToDidChange = [delegate respondsToSelector:@selector(egoTextViewDidChange:)];
    _delegateRespondsToDidChangeSelection = [delegate respondsToSelector:@selector(egoTextViewDidChangeSelection:)];
    _delegateRespondsToDidSelectURL = [delegate respondsToSelector:@selector(egoTextView:didSelectURL:)];
}

- (void)setEditable:(BOOL)editable {
    
    if (editable) {
        
        if (_caretView==nil) {
            _caretView = [[EGOCaretView alloc] initWithFrame:CGRectZero];
        }
        
        _tokenizer = [[UITextInputStringTokenizer alloc] initWithTextInput:self];
        _textChecker = [[UITextChecker alloc] init];
        _mutableAttributedString = [[NSMutableAttributedString alloc] init];
        
        NSDictionary *dictionary = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInt:(int)(kCTUnderlineStyleThick|kCTUnderlinePatternDot)], kCTUnderlineStyleAttributeName, (id)[UIColor colorWithRed:1.0f green:0.0f blue:0.0f alpha:1.0f].CGColor, kCTUnderlineColorAttributeName, nil];
        self.correctionAttributes = dictionary;
        
    } else {
        
        if (_caretView) {
            [_caretView removeFromSuperview];
            _caretView=nil;
        }
        
        self.correctionAttributes=nil;
        if (_textChecker!=nil) {
            _textChecker=nil;
        }
        if (_tokenizer!=nil) {
            _tokenizer=nil;
        }
        if (_mutableAttributedString!=nil) {
            _mutableAttributedString=nil;
        }
        
    }
    _editable = editable;
}

/////////////////////////////////////////////////////////////////////////////
// MARK: -
// MARK: Layout methods
/////////////////////////////////////////////////////////////////////////////

- (NSRange)rangeIntersection:(NSRange)first withSecond:(NSRange)second {
    
    NSRange result = NSMakeRange(NSNotFound, 0);
    
    if (first.location > second.location) {
        NSRange tmp = first;
        first = second;
        second = tmp;
    }
    
    if (second.location < first.location + first.length) {
        result.location = second.location;
        NSUInteger end = MIN(first.location + first.length, second.location + second.length);
        result.length = end - result.location;
    }
    return result;
}

- (void)drawPathFromRects:(NSArray*)array cornerRadius:(CGFloat)cornerRadius {
    
    if (array==nil || [array count] == 0) return;
    
    CGMutablePathRef _path = CGPathCreateMutable();
    
    CGRect firstRect = CGRectFromString([array lastObject]);
    CGRect lastRect = CGRectFromString([array objectAtIndex:0]);
    if ([array count]>1) {
        lastRect.size.width = _textContentView.bounds.size.width-lastRect.origin.x;
    }
    
    if (cornerRadius>0) {
        CGPathAddPath(_path, NULL, [UIBezierPath bezierPathWithRoundedRect:firstRect cornerRadius:cornerRadius].CGPath);
        CGPathAddPath(_path, NULL, [UIBezierPath bezierPathWithRoundedRect:lastRect cornerRadius:cornerRadius].CGPath);
    } else {
        CGPathAddRect(_path, NULL, firstRect);
        CGPathAddRect(_path, NULL, lastRect);
    }
    
    if ([array count] > 1) {
        
        CGRect fillRect = CGRectZero;
        
        CGFloat originX = ([array count]==2) ? MIN(CGRectGetMinX(firstRect), CGRectGetMinX(lastRect)) : 0.0f;
        CGFloat originY = firstRect.origin.y + firstRect.size.height;
        CGFloat width = ([array count]==2) ? originX+MIN(CGRectGetMaxX(firstRect), CGRectGetMaxX(lastRect)) : _textContentView.bounds.size.width;
        CGFloat height =  MAX(0.0f, lastRect.origin.y-originY);
        
        fillRect = CGRectMake(originX, originY, width, height);
        
        if (cornerRadius>0) {
            CGPathAddPath(_path, NULL, [UIBezierPath bezierPathWithRoundedRect:fillRect cornerRadius:cornerRadius].CGPath);
        } else {
            CGPathAddRect(_path, NULL, fillRect);
        }
        
    }
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextAddPath(ctx, _path);
    CGContextFillPath(ctx);
    CGPathRelease(_path);
}

- (void)drawBoundingRangeAsSelection:(NSRange)selectionRange cornerRadius:(CGFloat)cornerRadius {
    
    if (selectionRange.length == 0 || selectionRange.location == NSNotFound) {
        return;
    }
    
    NSMutableArray *pathRects = [[NSMutableArray alloc] init];
    NSArray *lines = (__bridge NSArray*)CTFrameGetLines(_frame);
    CGPoint *origins = (CGPoint*)malloc([lines count] * sizeof(CGPoint));
    CTFrameGetLineOrigins(_frame, CFRangeMake(0, [lines count]), origins);
    NSInteger count = [lines count];
    
    for (int i = 0; i < count; i++) {
        
        CTLineRef line = (__bridge CTLineRef) [lines objectAtIndex:i];
        CFRange lineRange = CTLineGetStringRange(line);
        NSRange range = NSMakeRange(lineRange.location==kCFNotFound ? NSNotFound : lineRange.location, lineRange.length);
        NSRange intersection = [self rangeIntersection:range withSecond:selectionRange];
        
        if (intersection.location != NSNotFound && intersection.length > 0) {
            
            CGFloat xStart = CTLineGetOffsetForStringIndex(line, intersection.location, NULL);
            CGFloat xEnd = CTLineGetOffsetForStringIndex(line, intersection.location + intersection.length, NULL);
            
            CGPoint origin = origins[i];
            CGFloat ascent, descent;
            CTLineGetTypographicBounds(line, &ascent, &descent, NULL);
            
            CGRect selectionRect = CGRectMake(origin.x + xStart,
                                              fabs(origin.y - _textContentView.frame.size.height) - ascent,
                                              xEnd - xStart,
                                              ascent + descent);
            
            if (range.length==1) {
                selectionRect.size.width = _textContentView.bounds.size.width;
            }
            
            [pathRects addObject:NSStringFromCGRect(selectionRect)];
        }
    }
    
    [self drawPathFromRects:pathRects cornerRadius:cornerRadius];
    
    free(origins);
}

- (void)drawContentInRect:(CGRect)rect {
    
    [[UIColor colorWithRed:0.8f green:0.8f blue:0.8f alpha:1.0f] setFill];
    [self drawBoundingRangeAsSelection:_linkRange cornerRadius:2.0f];
    [[EGOTextView selectionColor] setFill];
    [self drawBoundingRangeAsSelection:self.selectedRange cornerRadius:0.0f];
    [[EGOTextView spellingSelectionColor] setFill];
    [self drawBoundingRangeAsSelection:self.correctionRange cornerRadius:2.0f];
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    CGContextSetTextMatrix(ctx, CGAffineTransformIdentity);
    CGContextTranslateCTM(ctx, 0, rect.size.height);
    CGContextScaleCTM(ctx, 1.0, -1.0);
    
    /*CGPathRef framePath = CTFrameGetPath(_frame);
     CGRect frameRect = CGPathGetBoundingBox(framePath);*/
    
    NSArray *lines = (__bridge NSArray*)CTFrameGetLines(_frame);
    NSInteger count = [lines count];
    
    CGPoint *origins = (CGPoint*)malloc(count * sizeof(CGPoint));
    CTFrameGetLineOrigins(_frame, CFRangeMake(0, 0), origins);
    
    for (int i = 0 ; i < count; i++)
    {
        //NSLog(@"i = %d, origin.y = %f", i, origins[i].y);
        CTLineRef line = (CTLineRef)CFArrayGetValueAtIndex((__bridge CFArrayRef)lines, i);
        CGContextSetTextPosition(ctx, origins[i].x, origins[i].y);
        CTLineDraw(line, ctx);
        
        
        //        CFArrayRef runs = CTLineGetGlyphRuns(line);
        //        CFIndex runsCount = CFArrayGetCount(runs);
        /*for (CFIndex runsIndex = 0; runsIndex < runsCount; runsIndex++)
         {
         CTRunRef run = CFArrayGetValueAtIndex(runs, runsIndex);
         CFDictionaryRef attributes = CTRunGetAttributes(run);
         id <EGOTextAttachmentCell> attachmentCell = [(id)attributes objectForKey: EGOTextAttachmentAttributeName];
         if (attachmentCell != nil)
         {
         CGPoint position;
         CTRunGetPositions(run, CFRangeMake(0, 0), &position);
         UIView *attachmentView = (UIView*) attachmentCell;
         [attachmentView removeFromSuperview];
         CGSize size = attachmentView.frame.size;
         CGRect rect = { { origins[(count - 1) - i].x + position.x, origins[count-1 - i].y + position.y }, size };
         
         [_textContentView addSubview:attachmentView];
         attachmentView.frame = rect;
         [attachmentView setNeedsDisplay];
         }
         }*/
    }
    free(origins);
    CGContextRestoreGState(ctx);
}

- (NSInteger)closestWhiteSpaceIndexToPoint:(CGPoint)point {
    
    point = [self convertPoint:point toView:_textContentView];
    point.y = fabs(point.y - _textContentView.frame.size.height);
    NSArray *lines = (__bridge NSArray*)CTFrameGetLines(_frame);
    NSInteger count = [lines count];
    CGPoint *origins = (CGPoint*)malloc(count * sizeof(CGPoint));
    CTFrameGetLineOrigins(_frame, CFRangeMake(0, count), origins);
    
    __block NSRange returnRange = NSMakeRange(_attributedString.length, 0);
    
    for (int i = 0; i < lines.count; i++) {
        
        if (point.y > origins[i].y) {
            //            NSLog(@"point.y = %f, origins[i].y = %f", point.y, origins[i].y);
            
            CTLineRef line = (__bridge CTLineRef)[lines objectAtIndex:i];
            CFRange cfRange = CTLineGetStringRange(line);
            NSRange range = NSMakeRange(cfRange.location == kCFNotFound ? NSNotFound : cfRange.location, cfRange.length);
            CGPoint convertedPoint = CGPointMake(point.x - origins[i].x,
                                                 point.y - origins[i].y);
            CFIndex cfIndex = CTLineGetStringIndexForPosition(line, convertedPoint);
            NSInteger index = cfIndex == kCFNotFound ? NSNotFound : cfIndex;
            
            if(range.location==NSNotFound)
                break;
            
            if (index>=_attributedString.length) {
                returnRange = NSMakeRange(_attributedString.length, 0);
                break;
            }
            
            if (range.length <= 1) {
                returnRange = NSMakeRange(range.location, 0);
                break;
            }
            
            if (index == range.location) {
                returnRange = NSMakeRange(range.location, 0);
                break;
            }
            
            
            if (index >= (range.location+range.length)) {
                
                if (range.length > 1 && [_attributedString.string characterAtIndex:(range.location+range.length)-1] == '\n') {
                    
                    returnRange = NSMakeRange(index-1, 0);
                    break;
                    
                } else {
                    
                    returnRange = NSMakeRange(range.location+range.length, 0);
                    break;
                    
                }
                
            }
            
            [_attributedString.string enumerateSubstringsInRange:range options:NSStringEnumerationByWords usingBlock:^(NSString *subString, NSRange subStringRange, NSRange enclosingRange, BOOL *stop){
                
                
                if (NSLocationInRange(index, enclosingRange)) {
                    
                    if (index > (enclosingRange.location+(enclosingRange.length/2))) {
                        
                        returnRange = NSMakeRange(subStringRange.location+subStringRange.length, 0);
                        
                    } else {
                        
                        returnRange = NSMakeRange(subStringRange.location, 0);
                        
                    }
                    
                    *stop = YES;
                }
                
            }];
            
            break;
            
        }
    }
    free((void *)origins);
    return returnRange.location;
}


- (NSInteger)closestIndexToPoint:(CGPoint)point {
    
    point = [self convertPoint:point toView:_textContentView];
    NSArray *lines = (__bridge NSArray*)CTFrameGetLines(_frame);
    NSInteger count = [lines count];
    CGPoint *origins = (CGPoint*)malloc(count * sizeof(CGPoint));
    CTFrameGetLineOrigins(_frame, CFRangeMake(0, count), origins);
    CFIndex index = kCFNotFound;
    
    for (int i = 0; i < lines.count; i++) {
        if (point.y < fabs(origins[i].y - _textContentView.frame.size.height))
        {
            CTLineRef line = (__bridge CTLineRef)[lines objectAtIndex:i];
            CGPoint convertedPoint = CGPointMake(point.x - origins[i].x, point.y - (origins[i].y - fabs(_textContentView.frame.size.height)));
            index = CTLineGetStringIndexForPosition(line, convertedPoint);
            break;
        }
    }
    
    if (index == kCFNotFound) {
        index = [_attributedString length];
    }
    
    free(origins);
    return index;
    
}

- (NSRange)characterRangeAtPoint_:(CGPoint)point {
    
    __block NSArray *lines = (__bridge NSArray*)CTFrameGetLines(_frame);
    
    CGPoint *origins = (CGPoint*)malloc([lines count] * sizeof(CGPoint));
    CTFrameGetLineOrigins(_frame, CFRangeMake(0, [lines count]), origins);
    __block NSRange returnRange = NSMakeRange(NSNotFound, 0);
    
    for (int i = 0; i < lines.count; i++) {
        
        if (point.y > origins[i].y) {
            
            CTLineRef line = (__bridge CTLineRef)[lines objectAtIndex:i];
            CGPoint convertedPoint = CGPointMake(point.x - origins[i].x, point.y - origins[i].y);
            NSInteger index = CTLineGetStringIndexForPosition(line, convertedPoint);
            
            CFRange cfRange = CTLineGetStringRange(line);
            NSRange range = NSMakeRange(cfRange.location == kCFNotFound ? NSNotFound : cfRange.location, cfRange.length);
            
            [_attributedString.string enumerateSubstringsInRange:range options:NSStringEnumerationByWords usingBlock:^(NSString *subString, NSRange subStringRange, NSRange enclosingRange, BOOL *stop){
                
                if (index - subStringRange.location <= subStringRange.length) {
                    returnRange = subStringRange;
                    *stop = YES;
                }
                
            }];
            
            break;
        }
    }
    
    free(origins);
    return  returnRange;
    
}

- (NSRange)characterRangeAtIndex:(NSInteger)index {
    
    __block NSArray *lines = (__bridge NSArray*)CTFrameGetLines(_frame);
    NSInteger count = [lines count];
    __block NSRange returnRange = NSMakeRange(NSNotFound, 0);
    
    for (int i=0; i < count; i++) {
        
        __block CTLineRef line = (__bridge CTLineRef)[lines objectAtIndex:i];
        CFRange cfRange = CTLineGetStringRange(line);
        NSRange range = NSMakeRange(cfRange.location == kCFNotFound ? NSNotFound : cfRange.location, cfRange.length == kCFNotFound ? 0 : cfRange.length);
        
        if (index >= range.location && index <= range.location+range.length) {
            
            if (range.length > 1) {
                
                [_attributedString.string enumerateSubstringsInRange:range options:NSStringEnumerationByWords usingBlock:^(NSString *subString, NSRange subStringRange, NSRange enclosingRange, BOOL *stop){
                    
                    if (index - subStringRange.location <= subStringRange.length) {
                        returnRange = subStringRange;
                        *stop = YES;
                    }
                    
                }];
                
            }
            
        }
    }
    
    return returnRange;
    
}

- (CGRect)caretRectForIndex:(NSInteger)index {
    
    NSArray *lines = (__bridge NSArray*)CTFrameGetLines(_frame);
    
    // no text / first index
    if (_attributedString.length == 0 && index == 0) {
        //CGPoint origin = CGPointMake(CGRectGetMinX(_textContentView.bounds), CGRectGetMaxY(_textContentView.bounds) - self.font.leading);
        return CGRectMake(0.0, 0.0, 3, self.font.ascender + fabs(self.font.descender));
    }
    
    // last index is newline
    if (index == _attributedString.length && [_attributedString.string characterAtIndex:(index - 1)] == '\n' ) {
        
        CTLineRef line = (__bridge CTLineRef)[lines lastObject];
        CFRange range = CTLineGetStringRange(line);
        CGFloat xPos = CTLineGetOffsetForStringIndex(line, range.location, NULL);
        CGFloat ascent, descent;
        CTLineGetTypographicBounds(line, &ascent, &descent, NULL);
        
        CGPoint origin;
        CGPoint *origins = (CGPoint*)malloc(1 * sizeof(CGPoint));
        CTFrameGetLineOrigins(_frame, CFRangeMake([lines count]-1, 0), origins);
        origin = origins[0];
        free(origins);
        
        origin.y = fabs(origin.y - _textContentView.frame.size.height);
        origin.y = origin.y + (- self.font.descender);
        
        return CGRectMake(origin.x + xPos,
                          origin.y,
                          3,
                          self.font.ascender +  fabs(self.font.descender));
        
    }
    
    index = MAX(index, 0);
    index = MIN(_attributedString.string.length, index);
    
    NSInteger count = [lines count];
    CGPoint *origins = (CGPoint*)malloc(count * sizeof(CGPoint));
    CTFrameGetLineOrigins(_frame, CFRangeMake(0, count), origins);
    CGRect returnRect = CGRectZero;
    
    for (int i = 0; i < count; i++) {
        
        CTLineRef line = (__bridge CTLineRef)[lines objectAtIndex:i];
        CFRange cfRange = CTLineGetStringRange(line);
        NSRange range = NSMakeRange(cfRange.location == kCFNotFound ? NSNotFound : cfRange.location, cfRange.length);
        
        if (index >= range.location && index <= range.location+range.length) {
            
            CGFloat ascent, descent, xPos;
            xPos = CTLineGetOffsetForStringIndex(line, index, NULL);
            CTLineGetTypographicBounds(line, &ascent, &descent, NULL);
            CGPoint origin = origins[i];
            
            if (_selectedRange.length>0 && index != _selectedRange.location && range.length == 1) {
                
                xPos = _textContentView.bounds.size.width - 3.0f; // selection of entire line
                
            } else if (index-1 >= 0 ) {
                
                if ([_attributedString.string characterAtIndex:index-1] == '\n' && range.length == 1) {
                    
                    xPos = 0.0f; // empty line
                }
            }
            //NSLog(@"Ascent: %f, Descent: %f", ascent, descent);
            returnRect = CGRectMake(origin.x + xPos,
                                    floorf(fabs(origin.y - _textContentView.frame.size.height) - ascent),
                                    3,
                                    ascent + descent);
            
        }
        
    }
    
    free(origins);
    return returnRect;
}

- (CGRect)firstRectForNSRange:(NSRange)range {
    
    NSInteger index = range.location;
    
    NSArray *lines = (__bridge NSArray *) CTFrameGetLines(_frame);
    NSInteger count = [lines count];
    CGPoint *origins = (CGPoint*)malloc(count * sizeof(CGPoint));
    CTFrameGetLineOrigins(_frame, CFRangeMake(0, count), origins);
    CGRect returnRect = CGRectNull;
    
    for (int i = 0; i < count; i++) {
        
        CTLineRef line = (__bridge CTLineRef) [lines objectAtIndex:i];
        CFRange lineRange = CTLineGetStringRange(line);
        NSInteger localIndex = index - lineRange.location;
        
        if (localIndex >= 0 && localIndex < lineRange.length) {
            
            NSInteger finalIndex = MIN(lineRange.location + lineRange.length, range.location + range.length);
            CGFloat xStart = CTLineGetOffsetForStringIndex(line, index, NULL);
            CGFloat xEnd = CTLineGetOffsetForStringIndex(line, finalIndex, NULL);
            CGPoint origin = origins[i];
            CGFloat ascent, descent;
            CTLineGetTypographicBounds(line, &ascent, &descent, NULL);
            CGRect absRect = CGRectMake(origin.x + xStart,
                                        fabs(origin.y - _textContentView.frame.size.height) - ascent,
                                        xEnd - xStart,
                                        ascent + descent);
            returnRect = [_textContentView convertRect:absRect toView:self];
            break;
        }
    }
    
    free(origins);
    return returnRect;
}

- (CGRect)getFrameToScrollToTop:(BOOL)top {
    CGRect frame = CGRectMake(0, 0, 1, 1);
    if ([self isFirstResponder])
    {
        CGRect caretFrame = _caretView.frame;
        frame = [_textContentView convertRect:caretFrame toView:self];
    }
    else
    {
        NSString *attachmentSting = self.attachmentString.string;
        if (attachmentSting && !top)
        {
            //            CGRect caretFrame = [self caretRectForIndex:self.selectedRange.location];
            CGRect preAttachmentFrame = [self caretRectForIndex:self.selectedRange.location - 1];
            frame = [_textContentView convertRect:preAttachmentFrame toView:self];
        }
        else
        {
            frame = [_textContentView convertRect:CGRectMake(0, 0, 1, 1) toView:self];
        }
    }
    
    return frame;
}


/////////////////////////////////////////////////////////////////////////////
// MARK: -
// MARK: Text Selection
/////////////////////////////////////////////////////////////////////////////

- (void)selectionChanged {
    
    if (!_editing) {
        [_caretView removeFromSuperview];
    }
    
    _ignoreSelectionMenu = NO;
    
    if (self.selectedRange.length == 0) {
        
        if (_selectionView!=nil) {
            [_selectionView removeFromSuperview];
            _selectionView=nil;
        }
        
        if (!_caretView.superview && _editing) {
            [_textContentView addSubview:_caretView];
            [_textContentView setNeedsDisplay];
        }
        
        [UIView setAnimationsEnabled:NO];
        _caretView.frame = [self caretRectForIndex:self.selectedRange.location];
        [_caretView delayBlink];
        [UIView setAnimationsEnabled:YES];
        
        if ([self isFirstResponder])
        {
            CGRect frame = _caretView.frame;
            //        frame.origin.y += 5;
            frame = [_textContentView convertRect:frame toView:self];
            [self scrollRectToVisible:frame animated:self.scrollEnabled];
        }
        
        [_textContentView setNeedsDisplay];
        
        _longPress.minimumPressDuration = 0.5f;
        
    } else {
        
        _longPress.minimumPressDuration = 0.0f;
        
        if ((_caretView!=nil) && _caretView.superview) {
            [_caretView removeFromSuperview];
        }
        
        if (_selectionView==nil) {
            
            EGOSelectionView *view = [[EGOSelectionView alloc] initWithFrame:_textContentView.bounds];
            [_textContentView addSubview:view];
            _selectionView=view;
            
        }
        
        CGRect begin = [self caretRectForIndex:_selectedRange.location];
        CGRect end = [self caretRectForIndex:_selectedRange.location+_selectedRange.length];
        [_selectionView setBeginCaret:begin endCaret:end];
        [_textContentView setNeedsDisplay];
    }
    
    //    if (self.markedRange.location != NSNotFound) {
    //        [_textContentView setNeedsDisplay];
    //    }
}

- (NSRange)markedRange {
    return _markedRange;
}

- (NSRange)selectedRange {
    return _selectedRange;
}

- (void)setMarkedRange:(NSRange)range {
    _markedRange = range;
    //[self selectionChanged];
}

- (void)setSelectedRange:(NSRange)range {
    _selectedRange = NSMakeRange(range.location == NSNotFound ? NSNotFound : MAX(0, range.location), range.length);
    [self selectionChanged];
}

- (void)setCorrectionRange:(NSRange)range {
    
    if (NSEqualRanges(range, _correctionRange) && range.location == NSNotFound && range.length == 0) {
        _correctionRange = range;
        return;
    }
    
    _correctionRange = range;
    if (range.location != NSNotFound && range.length > 0) {
        
        if (_caretView.superview) {
            [_caretView removeFromSuperview];
        }
        
        [self removeCorrectionAttributesForRange:_correctionRange];
        [self showCorrectionMenuForRange:_correctionRange];
        
        
    } else {
        
        if (!_caretView.superview) {
            [_textContentView addSubview:_caretView];
            [_caretView delayBlink];
        }
        
    }
    
    [_textContentView setNeedsDisplay];
    
}

- (void)setLinkRange:(NSRange)range {
    
    _linkRange = range;
    
    if (_linkRange.length>0) {
        
        if (_caretView.superview!=nil) {
            [_caretView removeFromSuperview];
        }
        
    } else {
        
        if (_caretView.superview==nil) {
            if (!_caretView.superview) {
                [_textContentView addSubview:_caretView];
                _caretView.frame = [self caretRectForIndex:self.selectedRange.location];
                [_caretView delayBlink];
            }
        }
        
    }
    
    [_textContentView setNeedsDisplay];
    
}

- (void)setLinkRangeFromTextCheckerResults:(NSTextCheckingResult*)results {
    
    if (_linkRange.length>0)
    {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:[[results URL] absoluteString]
                                                                 delegate:(id<UIActionSheetDelegate>)self
                                                        cancelButtonTitle:NSLocalizedString(@"4-ButtonCancel", nil)
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:NSLocalizedString(@"25-ButtonOpen", nil), nil];
        [actionSheet showInView:self];
    }
    
}

+ (UIColor*)selectionColor {
    static UIColor *color = nil;
    if (color == nil) {
        color = [UIColor colorWithRed:0.800f green:0.867f blue:0.929f alpha:1.0f];
    }
    return color;
}

+ (UIColor*)caretColor {
    static UIColor *color = nil;
    if (color == nil) {
        color = [UIColor colorWithRed:0.259f green:0.420f blue:0.949f alpha:1.0f];
    }
    return color;
}

+ (UIColor*)spellingSelectionColor {
    static UIColor *color = nil;
    if (color == nil) {
        color = [UIColor colorWithRed:1.000f green:0.851f blue:0.851f alpha:1.0f];
    }
    return color;
}


/////////////////////////////////////////////////////////////////////////////
// MARK: -
// MARK: UITextInput methods
/////////////////////////////////////////////////////////////////////////////


// MARK: UITextInput - Replacing and Returning Text

- (NSString *)textInRange:(UITextRange *)range {
    
    EGOIndexedRange *r = (EGOIndexedRange *)range;
    
    
    NSUInteger length = [_attributedString.string length];
    if (r.range.location + r.range.length > length) {
        //NSLog(@"ERROR (%s): Invalid range! Range {%d, %d} is out of bounds {0, %d}",(char*)_cmd, r.range.location,r.range.length,length);
        return @"";
    }
    
    return ([_attributedString.string substringWithRange:r.range]);
}

- (void)replaceRange:(UITextRange *)range withText:(NSString *)text {
    
    EGOIndexedRange *r = (EGOIndexedRange *)range;
    
    NSRange selectedNSRange = self.selectedRange;
    
    if ((r.range.location + r.range.length) < selectedNSRange.location) {
        selectedNSRange.location -= (r.range.length - text.length);
    } else if ((r.range.location + r.range.length) != selectedNSRange.location) {
        selectedNSRange = [self rangeIntersection:r.range withSecond:_selectedRange];
    }
    BOOL safeReplaceChatactersInRange = NO;
    
    if (text.length == 1 && [text isEqualToString:@" "]) {
        safeReplaceChatactersInRange = YES;
    }
    
    NSString *notValidText = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (![notValidText isEqualToString:@""]) {
        safeReplaceChatactersInRange = YES;
    }
    
    if (safeReplaceChatactersInRange) {
        
        [_mutableAttributedString safeReplaceCharactersInRange:r.range withString:text];
        [_mutableAttributedString setAttributes:self.defaultAttributes range:NSMakeRange(r.range.location, text.length)];
        
        //set YES for prevent duplicate text
        //        _duplicateText = YES;
        selectedNSRange = NSMakeRange(_mutableAttributedString.length, 0);
        self.selectedRange = selectedNSRange;
    }
    else {
        safeReplaceChatactersInRange = YES;
        self.selectedRange = selectedNSRange;
    }
    
    self.attributedString = _mutableAttributedString;
    
    //replace cursor to end of text
    selectedNSRange.location = _mutableAttributedString.string.length;
    self.selectedRange = selectedNSRange;
    //set YES for prevent duplicate text
    self.isVoiceText = YES;
}

// MARK: UITextInput - Working with Marked and Selected Text

- (UITextRange *)selectedTextRange {
    return [EGOIndexedRange rangeWithNSRange:self.selectedRange];
}

- (void)setSelectedTextRange:(UITextRange *)range {
    EGOIndexedRange *r = (EGOIndexedRange *)range;
    self.selectedRange = r.range;
}

- (UITextRange *)markedTextRange {
    return [EGOIndexedRange rangeWithNSRange:self.markedRange];
}

- (void)setMarkedText:(NSString *)markedText selectedRange:(NSRange)selectedRange {
    if(!markedText)
    {
        return;
    }
    NSRange selectedNSRange = self.selectedRange;
    NSRange markedTextRange = self.markedRange;
    
    if (markedTextRange.location != NSNotFound) {
        if (!markedText)
            markedText = @"";
        
        [_mutableAttributedString safeReplaceCharactersInRange:markedTextRange withString:markedText];
        markedTextRange.length = markedText.length;
        
    } else if (selectedNSRange.length > 0) {
        
        [_mutableAttributedString safeReplaceCharactersInRange:selectedNSRange withString:markedText];
        markedTextRange.location = selectedNSRange.location;
        markedTextRange.length = markedText.length;
        
    } else {
        
        NSAttributedString *string = [[NSAttributedString alloc] initWithString:markedText attributes:self.defaultAttributes];
        [_mutableAttributedString insertAttributedString:string atIndex:selectedNSRange.location];
        
        markedTextRange.location = selectedNSRange.location;
        markedTextRange.length = markedText.length;
    }
    
    selectedNSRange = NSMakeRange(selectedRange.location, selectedRange.length);
    
    self.attributedString = _attributedString;
    self.markedRange = markedTextRange;
    self.selectedRange = selectedNSRange;
    
}

- (void)unmarkText {
    
    NSRange markedTextRange = self.markedRange;
    
    if (markedTextRange.location == NSNotFound)
        return;
    
    markedTextRange.location = NSNotFound;
    self.markedRange = markedTextRange;
    
}

// MARK: UITextInput - Computing Text Ranges and Text Positions

- (UITextPosition*)beginningOfDocument {
    return [EGOIndexedPosition positionWithIndex:0];
}

- (UITextPosition*)endOfDocument {
    return [EGOIndexedPosition positionWithIndex:_attributedString.length];
}

- (UITextRange*)textRangeFromPosition:(UITextPosition *)fromPosition toPosition:(UITextPosition *)toPosition {
    
    EGOIndexedPosition *from = (EGOIndexedPosition *)fromPosition;
    EGOIndexedPosition *to = (EGOIndexedPosition *)toPosition;
    NSRange range = NSMakeRange(MIN(from.index, to.index), ABS(to.index - from.index));
    return [EGOIndexedRange rangeWithNSRange:range];
    
}

- (UITextPosition*)positionFromPosition:(UITextPosition *)position offset:(NSInteger)offset {
    
    EGOIndexedPosition *pos = (EGOIndexedPosition *)position;
    NSInteger end = pos.index + offset;
    
    if (end > _attributedString.length || end < 0)
        return nil;
    
    return [EGOIndexedPosition positionWithIndex:end];
}

- (UITextPosition*)positionFromPosition:(UITextPosition *)position inDirection:(UITextLayoutDirection)direction offset:(NSInteger)offset {
    
    EGOIndexedPosition *pos = (EGOIndexedPosition *)position;
    NSInteger newPos = pos.index;
    
    switch (direction) {
        case UITextLayoutDirectionRight:
            newPos += offset;
            break;
        case UITextLayoutDirectionLeft:
            newPos -= offset;
            break;
        UITextLayoutDirectionUp: // not supported right now
            break;
        UITextLayoutDirectionDown: // not supported right now
            break;
        default:
            break;
            
    }
    
    if (newPos < 0)
        newPos = 0;
    
    if (newPos > _attributedString.length)
        newPos = _attributedString.length;
    
    return [EGOIndexedPosition positionWithIndex:newPos];
}

// MARK: UITextInput - Evaluating Text Positions

- (NSComparisonResult)comparePosition:(UITextPosition *)position toPosition:(UITextPosition *)other {
    EGOIndexedPosition *pos = (EGOIndexedPosition *)position;
    EGOIndexedPosition *o = (EGOIndexedPosition *)other;
    
    if (pos.index == o.index) {
        return NSOrderedSame;
    } if (pos.index < o.index) {
        return NSOrderedAscending;
    } else {
        return NSOrderedDescending;
    }
}

- (NSInteger)offsetFromPosition:(UITextPosition *)from toPosition:(UITextPosition *)toPosition {
    EGOIndexedPosition *f = (EGOIndexedPosition *)from;
    EGOIndexedPosition *t = (EGOIndexedPosition *)toPosition;
    return (t.index - f.index);
}

// MARK: UITextInput - Text Input Delegate and Text Input Tokenizer

- (id <UITextInputTokenizer>)tokenizer {
    return _tokenizer;
}

// MARK: UITextInput - Text Layout, writing direction and position

- (UITextPosition *)positionWithinRange:(UITextRange *)range farthestInDirection:(UITextLayoutDirection)direction {
    
    EGOIndexedRange *r = (EGOIndexedRange *)range;
    NSInteger pos = r.range.location;
    
    switch (direction) {
        case UITextLayoutDirectionUp:
        case UITextLayoutDirectionLeft:
            pos = r.range.location;
            break;
        case UITextLayoutDirectionRight:
        case UITextLayoutDirectionDown:
            pos = r.range.location + r.range.length;
            break;
    }
    
    return [EGOIndexedPosition positionWithIndex:pos];
}

- (UITextRange *)characterRangeByExtendingPosition:(UITextPosition *)position inDirection:(UITextLayoutDirection)direction {
    
    EGOIndexedPosition *pos = (EGOIndexedPosition *)position;
    NSRange result = NSMakeRange(pos.index, 1);
    
    switch (direction) {
        case UITextLayoutDirectionUp:
        case UITextLayoutDirectionLeft:
            result = NSMakeRange((pos.index > 0 ? pos.index - 1 : 0), 1);
            break;
        case UITextLayoutDirectionRight:
        case UITextLayoutDirectionDown:
            result = NSMakeRange(pos.index, 1);
            break;
    }
    
    return [EGOIndexedRange rangeWithNSRange:result];
}

- (UITextWritingDirection)baseWritingDirectionForPosition:(UITextPosition *)position inDirection:(UITextStorageDirection)direction {
    return UITextWritingDirectionLeftToRight;
}

- (void)setBaseWritingDirection:(UITextWritingDirection)writingDirection forRange:(UITextRange *)range {
    // only ltr supported for now.
}

// MARK: UITextInput - Geometry

- (CGRect)firstRectForRange:(UITextRange *)range {
    
    EGOIndexedRange *r = (EGOIndexedRange *)range;
    CGRect thisViewRect = [self firstRectForNSRange:r.range];
    
    return [self convertRect:thisViewRect toView:self.parentView];
}

- (CGRect)caretRectForPosition:(UITextPosition *)position {
    
    EGOIndexedPosition *pos = (EGOIndexedPosition *)position;
    CGRect caretRect = [self caretRectForIndex:pos.index];
    
    return [self convertRect:caretRect toView:self.parentView];
}

- (UIView *)textInputView {
    
    return self.parentView;
}

// MARK: UITextInput - Hit testing

- (UITextPosition*)closestPositionToPoint:(CGPoint)point {
    EGOIndexedPosition *position = [EGOIndexedPosition positionWithIndex:[self closestIndexToPoint:point]];
    return position;
    
}

- (UITextPosition*)closestPositionToPoint:(CGPoint)point withinRange:(UITextRange *)range {
    EGOIndexedPosition *position = [EGOIndexedPosition positionWithIndex:[self closestIndexToPoint:point]];
    return position;
    
}

- (UITextRange*)characterRangeAtPoint:(CGPoint)point {
    
    EGOIndexedRange *range = [EGOIndexedRange rangeWithNSRange:[self characterRangeAtPoint_:point]];
    return range;
    
}

// MARK: UITextInput - Styling Information

- (NSDictionary*)textStylingAtPosition:(UITextPosition *)position inDirection:(UITextStorageDirection)direction {
    
    EGOIndexedPosition *pos = (EGOIndexedPosition*)position;
    NSInteger index = pos.index;
    
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:1];
    
    if (index >= 0 && index < _attributedString.length) {
        NSDictionary *attribs = [self.attributedString attributesAtIndex:index effectiveRange:nil];
        CTFontRef ctFont = (__bridge CTFontRef)[attribs valueForKey:(NSString*)kCTFontAttributeName];
        UIFont *font = [UIFont fontWithName:(__bridge_transfer NSString*)CTFontCopyFamilyName(ctFont) size:CTFontGetSize(ctFont)];
        
        [dictionary setObject:font forKey:NSFontAttributeName];
    }
    
    return dictionary;
    
}


/////////////////////////////////////////////////////////////////////////////
// MARK: -
// MARK: UIKeyInput methods
/////////////////////////////////////////////////////////////////////////////

- (BOOL)hasText {
    return (_attributedString.length != 0);
}

- (BOOL)hasOldTextBeforeSending {
    return (_mutableAttributedString.length != 0);
}

- (void) removeOldText {
    _mutableAttributedString = [[NSMutableAttributedString alloc] initWithString:@""];
    self.selectedRange = NSMakeRange(0, _mutableAttributedString.length);
    
    [_mutableAttributedString safeReplaceCharactersInRange:self.selectedRange withString:_mutableAttributedString.string];
}

- (void)insertText:(NSString *)text {
    
    if ([self validText:text]) {
        
        NSRange oldSelectedRange = self.selectedRange;
        NSRange oldMarkedRange   = self.markedRange;
        NSAttributedString * oldString = [self.attributedString copy];
        
        if (self.isVoiceText && self.selectedRange.location == 0) {
            self.isVoiceText = NO;
        }
        @try {
            NSRange selectedNSRange = self.selectedRange;
            NSRange markedTextRange = self.markedRange;
            [_mutableAttributedString setAttributedString:self.attributedString];
            
            NSAttributedString *newString = [[NSAttributedString alloc] initWithString:text attributes:self.defaultAttributes];
            
            if (_correctionRange.location != NSNotFound && _correctionRange.length > 0){
                
                [_mutableAttributedString safeReplaceCharactersInRange:self.correctionRange withAttributedString:newString];
                selectedNSRange.length = 0;
                selectedNSRange.location = (self.correctionRange.location+text.length);
                self.correctionRange = NSMakeRange(NSNotFound, 0);
                
            } else if (markedTextRange.location != NSNotFound) {
                
                NSString *validStr = [newString.string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                NSRange oldRange = [[newString.string lowercaseString] rangeOfString:[oldString.string lowercaseString]];
                
                if (oldRange.location == NSNotFound && ![validStr isEqualToString:@""]) {
                    [_mutableAttributedString safeReplaceCharactersInRange:markedTextRange withAttributedString:newString];
                    selectedNSRange.location += text.length;
                }
                selectedNSRange.length = 0;
                markedTextRange = NSMakeRange(NSNotFound, 0);
                
            } else if (selectedNSRange.length > 0) {
                
                [_mutableAttributedString safeReplaceCharactersInRange:selectedNSRange withAttributedString:newString];
                selectedNSRange.length = 0;
                selectedNSRange.location = (selectedNSRange.location + text.length);
                
            } else {
                
                NSString *validNewText = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                NSRange oldRange = [[oldString.string lowercaseString] rangeOfString:[validNewText lowercaseString]];
                
                BOOL insertingSpace = NO;
                
                if (newString.string.length == 1 && [newString.string isEqualToString:@" "]) {
                    insertingSpace = YES;
                }
                
                BOOL insertText = YES;
                if (oldRange.location != NSNotFound && oldRange.location + oldRange.length != validNewText.length && self.isVoiceText) {
                    
                    NSString *lastInsertingText = [[[oldString.string substringWithRange:oldRange] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] lowercaseString];
                    
                    if ([lastInsertingText isEqualToString:[validNewText lowercaseString]]) {
                        
                        if (lastInsertingText.length > 1) {
                            insertText = NO;
                        }
                        //                    insertText = NO;
                    }
                    //Need to set 'isVoiceText' to NO for new letters (4/5/2017)
                    self.isVoiceText = NO;
                }
                
                if (insertText) {
                    
                    if (((oldRange.location == NSNotFound || oldRange.location + oldRange.length != validNewText.length) && (![validNewText isEqualToString:@""] || insertingSpace)) || newString.string.length == 1) {
                        
                        [_mutableAttributedString insertAttributedString:newString atIndex:selectedNSRange.location];
                        selectedNSRange.location += text.length;
                    }
                    else {
                        if (oldRange.location + oldRange.length == validNewText.length && [[[_mutableAttributedString.string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] lowercaseString] isEqualToString:[validNewText lowercaseString]]) {
                            
                            newString = [[NSAttributedString alloc] initWithString:@" " attributes:self.defaultAttributes];
                        }
                    }
                }
                //                selectedNSRange.location += text.length;
                //                    if (![text isEqual:@"          "]) {
                //                        [_mutableAttributedString insertAttributedString:newString atIndex:selectedNSRange.location];
                //                        selectedNSRange.location += text.length;
                //                    } else {
                //                        selectedNSRange.location += text.length;
                //                        _textWasSet = NO;
                //                    }
            }
            
            self.attributedString = _mutableAttributedString;
            self.markedRange = markedTextRange;
            self.selectedRange = selectedNSRange;
            
            if (text.length > 1 || ([text isEqualToString:@" "] || [text isEqualToString:@"\n"])) {
                [self checkSpellingForRange:[self characterRangeAtIndex:self.selectedRange.location-1]];
                [self checkLinksForRange:NSMakeRange(0, self.attributedString.length)];
            }
        }
        
        @catch (NSException *exception) {
            self.markedRange = oldMarkedRange;
            self.selectedRange = oldSelectedRange;
            self.attributedString = oldString;
            DDLogError(@"Exception during inserting text: %@. Exception: %@",text, exception.reason);
        }
    }
}

- (BOOL)validText:(NSString*)text {
    
    BOOL valid;
    
    if ([text isEqualToString:@" "]) {
        //it's 1 space - Valid text
        valid = YES;
    } else {
        
        NSString *validNewText = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ([validNewText isEqualToString:@""]) {
            //        if ([text isEqual:@"          "]) {
            
            //set YES for prevent duplicate dictation text
            _duplicateText = YES;
            
            //it's no valid text (is set after end dictation automatically)
            valid =  NO;
        } else {
            if (_duplicateText){
                //it's duplicate text - no Valid
                valid = NO;
                _duplicateText = NO;
            } else {
                //it's normal text from keyboard - Valid
                valid = YES;
            }
        }
    }
    return valid;
}

//- (void)insertText:(NSString *)text {
//
//    if ([self validText:text]) {
//
//        NSRange selectedNSRange = self.selectedRange;
//        NSRange markedTextRange = self.markedRange;
//
//        [_mutableAttributedString setAttributedString:self.attributedString];
//
//        NSAttributedString *newString = [[NSAttributedString alloc] initWithString:text attributes:self.defaultAttributes];
//
//        if (_correctionRange.location != NSNotFound && _correctionRange.length > 0){
//
//            [_mutableAttributedString replaceCharactersInRange:self.correctionRange withAttributedString:newString];
//
//            selectedNSRange.length = 0;
//            selectedNSRange.location = (self.correctionRange.location+text.length);
//
//            self.correctionRange = NSMakeRange(NSNotFound, 0);
//
//        } else if (markedTextRange.location != NSNotFound) {
//
//            [_mutableAttributedString replaceCharactersInRange:markedTextRange withAttributedString:newString];
//
//            selectedNSRange.location = markedTextRange.location + text.length;
//
//            selectedNSRange.length = 0;
//
//            markedTextRange = NSMakeRange(NSNotFound, 0);
//
//        } else if (selectedNSRange.length > 0) {
//
//            [_mutableAttributedString replaceCharactersInRange:selectedNSRange withAttributedString:newString];
//
//            selectedNSRange.length = 0;
//
//            selectedNSRange.location = (selectedNSRange.location + text.length);
//
//        } else {
//            [_mutableAttributedString insertAttributedString:newString atIndex:selectedNSRange.location];
//            selectedNSRange.location += text.length;
//        }
//
//        self.attributedString = _mutableAttributedString;
//
//        self.markedRange = markedTextRange;
//
//        self.selectedRange = selectedNSRange;
//
//        if (text.length > 1 || ([text isEqualToString:@" "] || [text isEqualToString:@"\n"])) {
//
//            [self checkSpellingForRange:[self characterRangeAtIndex:self.selectedRange.location-1]];
//
//            [self checkLinksForRange:NSMakeRange(0, self.attributedString.length)];
//        }
//    }
//}

-(void) insertAttachment:(id)attachment
{
    //[self becomeFirstResponder];
    NSRange selectedNSRange = self.selectedRange;
    NSRange markedTextRange = self.markedRange;
    
    [_mutableAttributedString setAttributedString:self.attributedString];
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
    [attributes addEntriesFromDictionary:self.defaultAttributes];
    [attributes setObject:attachment forKey:EGOTextAttachmentAttributeName];
    NSAttributedString *stringToInsert = [[NSAttributedString alloc] initWithString:EGOTextAttachmentPlaceholderString attributes:attributes];
    self.attachmentString = nil;
    self.attachmentString = [[NSAttributedString alloc] initWithString:stringToInsert.string];
    [_mutableAttributedString insertAttributedString:stringToInsert atIndex:_mutableAttributedString.length];
    self.attributedString = _mutableAttributedString;
    
    selectedNSRange.location += [EGOTextAttachmentPlaceholderString length];
    markedTextRange.location = NSNotFound;
    markedTextRange.length = 0.0;
    [self scanAttachments];
    [self textChanged];
    
    [_textContentView setNeedsDisplay];
    self.selectedRange = selectedNSRange;
    self.markedRange = markedTextRange;
    
    //    [self selectionChanged];
    [self appendText:@"\n"];
    
    self.contentOffset = CGPointZero;
    [self scrollRectToVisible:[self getFrameToScrollToTop:NO] animated:self.scrollEnabled];
}

-(void) removeAttachments
{
    [_mutableAttributedString setAttributedString:self.attributedString];
    while(YES)
    {
        NSRange range = [_mutableAttributedString.string rangeOfString:EGOTextAttachmentPlaceholderString];
        if(range.location == NSNotFound)
        {
            break;
        }
        if (_mutableAttributedString.length > range.location + range.length)
        {
            if ([_mutableAttributedString attributedSubstringFromRange:NSMakeRange(range.location + range.length, 1)].string.length > 0 &&
                [[_mutableAttributedString attributedSubstringFromRange:NSMakeRange(range.location + range.length, 1)].string isEqualToString:@"\n"])
            {
                [_mutableAttributedString deleteCharactersInRange:NSMakeRange(range.location + range.length, 1)];
            }
        }
        
        [_mutableAttributedString deleteCharactersInRange:range];
    }
    
    if (![self.attributedString isEqualToAttributedString:_mutableAttributedString]) {
        self.attributedString = _mutableAttributedString;
        self.selectedRange = NSMakeRange([_attributedString length], 0);
    }
}

-(void) appendText:(NSString *)text
{
    self.selectedRange = NSMakeRange([_attributedString length], 0);
    [self insertText:text];
}

- (void)deleteBackward  {
    
    @try {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(showCorrectionMenuWithoutSelection) object:nil];
        
        NSRange selectedNSRange = self.selectedRange;
        NSRange markedTextRange = self.markedRange;
        
        NSRange replacementRange = NSMakeRange(NSNotFound, 0);
        
        [_mutableAttributedString setAttributedString:self.attributedString];
        
        if (_correctionRange.location != NSNotFound && _correctionRange.length > 0) {
            
            replacementRange = self.correctionRange;
            self.correctionRange = NSMakeRange(NSNotFound, 0);
            selectedNSRange.length = 0;
            
        } else if (markedTextRange.location != NSNotFound) {
            
            replacementRange = selectedNSRange;
            selectedNSRange.location = markedTextRange.location;
            selectedNSRange.length = 0;
            markedTextRange = NSMakeRange(NSNotFound, 0);
            
        } else if (selectedNSRange.length > 0) {
            
            replacementRange = selectedNSRange;
            selectedNSRange.length = 0;
            
        } else if (selectedNSRange.location > 0) {
            
            NSInteger index = MAX(0, selectedNSRange.location-1);
            index = MIN(_attributedString.length-1, index);
            if ([_attributedString.string characterAtIndex:index] == ' ') {
                [self performSelector:@selector(showCorrectionMenuWithoutSelection) withObject:nil afterDelay:0.2f];
            }
            
            selectedNSRange.location--;
            selectedNSRange.length = 1;
            
            replacementRange = selectedNSRange;
            selectedNSRange.length = 0;
        }
        
        //NSLog(@"Replacement range loc:%d length:%d", replacementRange.location, replacementRange.length);
        
        [self.attributedString enumerateAttribute:EGOTextAttachmentAttributeName
                                          inRange:replacementRange
                                          options:0
                                       usingBlock:^(id value, NSRange range, BOOL *stop)
         {
             if(value != nil)
             {
                 [self.delegate egoTextView:self willDeleteAttachment:value];
             }
         }];
        
        if(replacementRange.location != NSNotFound && replacementRange.length > 0)
        {
            [_mutableAttributedString beginEditing];
            [_mutableAttributedString deleteCharactersInRange:replacementRange];
            [_mutableAttributedString endEditing];
        }
        
        self.attributedString = _mutableAttributedString;
        self.markedRange = markedTextRange;
        self.selectedRange = selectedNSRange;
    }
    @catch (NSException *exception) {
        DDLogError(@"Exception during delete backward Exception: %@", exception.reason);
    }
}


/////////////////////////////////////////////////////////////////////////////
// MARK: -
// MARK: Data Detectors (links)
/////////////////////////////////////////////////////////////////////////////

- (NSTextCheckingResult*)linkAtIndex:(NSInteger)index {
    
    NSRange range = [self characterRangeAtIndex:index];
    if (range.location==NSNotFound || range.length == 0) {
        return nil;
    }
    
    __block NSTextCheckingResult *link = nil;
    NSError *error = nil;
    NSDataDetector *linkDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:&error];
    [linkDetector enumerateMatchesInString:[self.attributedString string] options:0 range:range usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        
        if ([result resultType] == NSTextCheckingTypeLink) {
            *stop = YES;
            link = result;
        }
        
    }];
    
    return link;
    
}

- (void)checkLinksForRange:(NSRange)range {
    
    NSDictionary *linkAttributes = [NSDictionary dictionaryWithObjectsAndKeys:(id)[UIColor blueColor].CGColor, kCTForegroundColorAttributeName, [NSNumber numberWithInt:(int)kCTUnderlineStyleSingle], kCTUnderlineStyleAttributeName, nil];
    
    NSMutableAttributedString *string = [_attributedString mutableCopy];
    NSError *error = nil;
    NSDataDetector *linkDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:&error];
    [linkDetector enumerateMatchesInString:[string string] options:0 range:range usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        
        if ([result resultType] == NSTextCheckingTypeLink) {
            [string addAttributes:linkAttributes range:[result range]];
        }
    }];
    
    if (![self.attributedString isEqualToAttributedString:string]) {
        self.attributedString = string;
    }
}

- (void)scanAttachments {
    
    __block NSMutableAttributedString *mutableAttributedString = nil;
    
    [_attributedString enumerateAttribute: EGOTextAttachmentAttributeName inRange: NSMakeRange(0, [_attributedString length]) options: 0 usingBlock: ^(id value, NSRange range, BOOL *stop) {
        // we only care when an attachment is set
        if (value != nil) {
            // create the mutable version of the string if it's not already there
            if (mutableAttributedString == nil)
                mutableAttributedString = [_attributedString mutableCopy];
            
            CTRunDelegateCallbacks callbacks = {
                .version = kCTRunDelegateVersion1,
                .dealloc = AttachmentRunDelegateDealloc,
                .getAscent = AttachmentRunDelegateGetAscent,
                .getDescent = AttachmnetRunDelegateGetDescent,
                .getWidth = AttachmentRunDelegateGetWidth,
            };
            
            // the retain here is balanced by the release in the Dealloc function
            CTRunDelegateRef runDelegate = CTRunDelegateCreate(&callbacks,(__bridge void *) value);
            [mutableAttributedString addAttribute: (NSString *)kCTRunDelegateAttributeName value: (__bridge id)runDelegate range:range];
            CFRelease(runDelegate);
        }
    }];
    
    if (mutableAttributedString) {
        _attributedString = mutableAttributedString;
    }
}

- (BOOL)selectedLinkAtIndex:(NSInteger)index {
    
    NSTextCheckingResult *_link = [self linkAtIndex:index];
    if (_link!=nil) {
        [self setLinkRange:[_link range]];
        return YES;
    }
    
    return NO;
}

- (void)openLink:(NSURL*)aURL {
    
    [[UIApplication sharedApplication] openURL:aURL];
    
    //self.
    
}


/////////////////////////////////////////////////////////////////////////////
// MARK: -
// MARK: Spell Checking
/////////////////////////////////////////////////////////////////////////////

- (void)insertCorrectionAttributesForRange:(NSRange)range {
    
    NSMutableAttributedString *string = [_attributedString mutableCopy];
    [string addAttributes:self.correctionAttributes range:range];
    self.attributedString = string;
    
}

- (void)removeCorrectionAttributesForRange:(NSRange)range {
    
    NSMutableAttributedString *string = [_attributedString mutableCopy];
    [string removeAttribute:(NSString*)kCTUnderlineStyleAttributeName range:range];
    self.attributedString = string;
    
}

- (void)checkSpellingForRange:(NSRange)range {
    
    [_mutableAttributedString setAttributedString:self.attributedString];
    
    NSInteger location = range.location-1;
    NSInteger currentOffset = MAX(0, location);
    NSRange currentRange;
    NSString *string = self.attributedString.string;
    NSRange stringRange = NSMakeRange(0, (string.length > 0 ? string.length-1 : 0));
    NSArray *guesses;
    BOOL done = NO;
    
    NSString *language = [[UITextChecker availableLanguages] objectAtIndex:0];
    if (!language) {
        language = @"en_US";
    }
    
    while (!done) {
        
        currentRange = [_textChecker rangeOfMisspelledWordInString:string range:stringRange startingAt:currentOffset wrap:NO language:language];
        
        if (currentRange.location == NSNotFound || currentRange.location > range.location) {
            done = YES;
            continue;
        }
        
        guesses = [_textChecker guessesForWordRange:currentRange inString:string language:language];
        
        if (guesses!=nil) {
            [_mutableAttributedString addAttributes:self.correctionAttributes range:currentRange];
        }
        
        currentOffset = currentOffset + (currentRange.length-1);
        
    }
    
    if (![self.attributedString isEqualToAttributedString:_mutableAttributedString]) {
        self.attributedString = _mutableAttributedString;
    }
    
}


/////////////////////////////////////////////////////////////////////////////
// MARK: -
// MARK: Gestures
/////////////////////////////////////////////////////////////////////////////

- (EGOTextWindow*)egoTextWindow {
    
    if (_textWindow==nil) {
        
        EGOTextWindow *window = nil;
        
        for (EGOTextWindow *aWindow in [[UIApplication sharedApplication] windows]){
            if ([aWindow isKindOfClass:[EGOTextWindow class]]) {
                window = aWindow;
                window.frame = [[UIScreen mainScreen] bounds];
                break;
            }
        }
        
        if (window==nil) {
            window = [[EGOTextWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        }
        
        window.windowLevel = UIWindowLevelStatusBar;
        window.hidden = NO;
        _textWindow=window;
        
    }
    
    return _textWindow;
    
}

- (void)longPress:(UILongPressGestureRecognizer*)gesture {
    
    if (gesture.state==UIGestureRecognizerStateBegan || gesture.state == UIGestureRecognizerStateChanged) {
        
        if (_linkRange.length>0 && gesture.state == UIGestureRecognizerStateBegan) {
            NSTextCheckingResult *link = [self linkAtIndex:_linkRange.location];
            [self setLinkRangeFromTextCheckerResults:link];
            gesture.enabled=NO;
            gesture.enabled=YES;
        }
        
        
        UIMenuController *menuController = [UIMenuController sharedMenuController];
        if ([menuController isMenuVisible]) {
            [menuController setMenuVisible:NO animated:NO];
        }
        
        CGPoint point = [gesture locationInView:self];
        BOOL _selection = (_selectionView!=nil) && !_selectionView.dotsHidden;
        
        if (!_selection && _caretView!=nil) {
            [_caretView show];
        }
        
        UIView * contentView = self;/*_textContentView*/
        _textWindow = [self egoTextWindow];
        [_textWindow updateWindowTransform];
        [_textWindow setType:_selection ? EGOWindowMagnify : EGOWindowLoupe];
        
        point.y -= 20.0f;
        NSInteger index = [self closestIndexToPoint:point];
        
        
        
        if (_selection) {
            
            if (gesture.state == UIGestureRecognizerStateBegan) {
                _textWindow.selectionType = (index > (_selectedRange.location+(_selectedRange.length/2))) ? EGOSelectionTypeRight : EGOSelectionTypeLeft;
            }
            
            CGRect rect = CGRectZero;
            if (_textWindow.selectionType==EGOSelectionTypeLeft) {
                
                NSInteger begin = MAX(0, index);
                begin = MIN(_selectedRange.location+_selectedRange.length-1, begin);
                
                NSInteger end = _selectedRange.location + _selectedRange.length;
                end = MIN(_attributedString.string.length, end-begin);
                
                self.selectedRange = NSMakeRange(begin, end);
                index = _selectedRange.location;
                
            } else {
                
                NSInteger length = MIN(index-_selectedRange.location, _attributedString.string.length-_selectedRange.location);
                length = MAX(1, length);
                self.selectedRange = NSMakeRange(self.selectedRange.location, length);
                index = (_selectedRange.location+_selectedRange.length);
                
            }
            
            rect = [self caretRectForIndex:index];
            
            if (gesture.state == UIGestureRecognizerStateBegan) {
                [_textWindow showFromView:_textContentView andRenderView:contentView rect:[_textContentView convertRect:rect toView:_textWindow]];
                
            } else {
                [_textWindow renderWithContentView:contentView fromRect:[_textContentView convertRect:rect toView:_textWindow]];
                
            }
            
        } else {
            
            CGPoint location = [gesture locationInView:_textWindow];
            CGRect rect = CGRectMake(location.x, location.y, _caretView.bounds.size.width, _caretView.bounds.size.height);
            
            NSInteger index = [self closestWhiteSpaceIndexToPoint:[gesture locationInView:self]];
            [self.inputDelegate selectionWillChange:self];
            self.selectedRange = [self characterRangeAtIndex:index];
            [self.inputDelegate selectionDidChange:self];
            _selectionView.dotsHidden = YES;
            
            if (gesture.state == UIGestureRecognizerStateBegan) {
                [_textWindow showFromView:_textContentView andRenderView:contentView rect:rect];
                
            } else {
                [_textWindow renderWithContentView:contentView fromRect:rect];
                
            }
        }
        
    } else {
        
        if (_caretView!=nil) {
            [_caretView delayBlink];
        }
        
        if ((_textWindow!=nil)) {
            [_textWindow hide:YES];
            _textWindow=nil;
        }
        
        if (gesture.state == UIGestureRecognizerStateEnded) {
            /*
             when did longPress check if EGOTextView is NOT first responder.
             Need for correct work of UIMenuController
             24_02_16
             */
            if (![self isFirstResponder]) {
                [self becomeFirstResponder];
                self.longPressToBecomeFirstResponder = YES;
            }
            
            if (self.selectedRange.location == NSNotFound) {
                NSInteger index = [self closestWhiteSpaceIndexToPoint:[gesture locationInView:self]];
                self.selectedRange  = NSMakeRange(index, 0);
            }
            
            if (self.selectedRange.location!=NSNotFound) {
                _selectionView.dotsHidden = self.selectedRange.length == 0;
                
                /*
                 if longPress call becomeFirstResponder no need to call 'showMenu' method immidiately.
                 Otherwise UIMenuController will be shown and then dissmised at once.
                 Need for correct work of UIMenuController
                 24_02_16
                 */
                if (self.longPressToBecomeFirstResponder) {
                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showMenu) name:@"showTextViewMenuNotification" object:nil];
                } else {
                    [self performSelector:@selector(showMenu) withObject:nil afterDelay:0.35f];
                }
            }
        }
    }
    
}

- (void)doubleTap:(UITapGestureRecognizer*)gesture {
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(showMenu) object:nil];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(showCorrectionMenu) object:nil];
    
    NSInteger index = [self closestWhiteSpaceIndexToPoint:[gesture locationInView:self]];
    NSRange range = [self characterRangeAtIndex:index];
    if (range.location!=NSNotFound && range.length>0) {
        
        [self.inputDelegate selectionWillChange:self];
        self.selectedRange = range;
        [self.inputDelegate selectionDidChange:self];
        
        if (![[UIMenuController sharedMenuController] isMenuVisible]) {
            [self performSelector:@selector(showMenu) withObject:nil afterDelay:0.1f];
        }
    }
    
}

- (void)tap:(UITapGestureRecognizer*)gesture {
    
    if (_editable && ![self isFirstResponder]) {
        [self becomeFirstResponder];
        return;
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(showMenu) object:nil];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(showCorrectionMenu) object:nil];
    
    self.correctionRange = NSMakeRange(NSNotFound, 0);
    if (self.selectedRange.length>0) {
        self.selectedRange = NSMakeRange(_selectedRange.location, 0);
    }
    
    NSInteger index = [self closestIndexToPoint:[gesture locationInView:self]];
    
    if (_delegateRespondsToDidSelectURL && !_editing) {
        if ([self selectedLinkAtIndex:index]) {
            return;
        }
    }
    
    UIMenuController *menuController = [UIMenuController sharedMenuController];
    if ([menuController isMenuVisible])
    {
        [menuController setMenuVisible:NO animated:NO];
    }
    //else {
    //
    //    if (index==self.selectedRange.location) {
    //        [self performSelector:@selector(showMenu) withObject:nil afterDelay:0.35f];
    //    } else {
    //        if (_editing) {
    //            [self performSelector:@selector(showCorrectionMenu) withObject:nil afterDelay:0.35f];
    //        }
    //    }
    //
    //}
    
    [self.inputDelegate selectionWillChange:self];
    
    self.markedRange = NSMakeRange(NSNotFound, 0);
    self.selectedRange = NSMakeRange(index, 0);
    
    [self.inputDelegate selectionDidChange:self];
    
}


/////////////////////////////////////////////////////////////////////////////
// MARK: -
// MARK: UIGestureRecognizerDelegate
/////////////////////////////////////////////////////////////////////////////

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    
    if ([gestureRecognizer isKindOfClass:NSClassFromString(@"UIScrollViewPanGestureRecognizer")]) {
        UIMenuController *menuController = [UIMenuController sharedMenuController];
        if ([menuController isMenuVisible]) {
            [menuController setMenuVisible:NO animated:NO];
        }
    }
    
    return NO;
    
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{
    
    if (gestureRecognizer==_longPress) {
        
        if (_selectedRange.length>0 && _selectionView!=nil) {
            return CGRectContainsPoint(CGRectInset([_textContentView convertRect:_selectionView.frame toView:self], -20.0f, -20.0f) , [gestureRecognizer locationInView:self]);
        }
        
    }
    
    return YES;
    
}


/////////////////////////////////////////////////////////////////////////////
// MARK: -
// MARK: UIActionSheetDelegate
/////////////////////////////////////////////////////////////////////////////

- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex {
    
    if (actionSheet.cancelButtonIndex != buttonIndex) {
        
        if (_delegateRespondsToDidChange) {
            [self.delegate egoTextView:self didSelectURL:[NSURL URLWithString:actionSheet.title]];
        } else {
            [self openLink:[NSURL URLWithString:actionSheet.title]];
        }
        
    } else {
        
        [self becomeFirstResponder];
        
    }
    
    [self setLinkRange:NSMakeRange(NSNotFound, 0)];
    
}


/////////////////////////////////////////////////////////////////////////////
// MARK: -
// MARK: UIResponder
/////////////////////////////////////////////////////////////////////////////

- (BOOL)canBecomeFirstResponder {
    
    if (_editable && _delegateRespondsToShouldBeginEditing) {
        _editing = [self.delegate egoTextViewShouldBeginEditing:self];
        //        [self selectionChanged];
        return _editing;
    }
    
    return YES;
}

- (BOOL)becomeFirstResponder {
    
    BOOL becameFirstResponder = [super becomeFirstResponder];
    
    if (_editable) {
        
        _editing = YES;
        
        [self textChanged];
        [self selectionChanged];
        
        if ([[self.attributedString string] length] == 0 || NSEqualRanges(self.selectedRange, NSMakeRange(0, 0)))
        {
            [self deleteBackward];
        }
        
        if (_delegateRespondsToDidBeginEditing) {
            [self.delegate egoTextViewDidBeginEditing:self];
        }
    }
    
    return becameFirstResponder;
}

- (BOOL)canResignFirstResponder {
    
    if (_editable && _delegateRespondsToShouldEndEditing) {
        return [self.delegate egoTextViewShouldEndEditing:self];
    }
    
    return YES;
}

- (BOOL)resignFirstResponder {
    
    BOOL resigned = [super resignFirstResponder];
    
    if (_editable) {
        
        _editing = NO;
        
        /*
         need for dissmiss selected range and selection view on keyboard dissmissing
         24_02_16
         */
        if (self.selectedRange.length>0) {
            self.selectedRange = NSMakeRange(_selectedRange.location, 0);
        }
        else
        {
            [self selectionChanged];
        }
        
        [self textChanged];
        
        if (_delegateRespondsToDidEndEditing) {
            [self.delegate egoTextViewDidEndEditing:self];
        }
    }
    
    return resigned;
    
}


/////////////////////////////////////////////////////////////////////////////
// MARK: -
// MARK: UIMenu Presentation
/////////////////////////////////////////////////////////////////////////////

- (CGRect)menuPresentationRect {
    
    CGRect rect = [_textContentView convertRect:_caretView.frame toView:self];
    
    if (_selectedRange.location != NSNotFound && _selectedRange.length > 0) {
        
        if (_selectionView!=nil) {
            rect = [_textContentView convertRect:_selectionView.frame toView:self];
        } else {
            rect = [self firstRectForNSRange:_selectedRange];
        }
        
    } else if (_editing && _correctionRange.location != NSNotFound && _correctionRange.length > 0) {
        
        rect = [self firstRectForNSRange:_correctionRange];
        
    }
    
    return rect;
    
}

- (void)showMenu {
    
    UIMenuController *menuController = [UIMenuController sharedMenuController];
    
    if ([menuController isMenuVisible]) {
        [menuController setMenuVisible:NO animated:NO];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [menuController setMenuItems:nil];
        [menuController setTargetRect:[self menuPresentationRect] inView:self];
        [menuController update];
        [menuController setMenuVisible:YES animated:NO]; // animated:YES 24_02_16
    });
    
    /*
     check if 'showMenu' method was called after receving notification
     24_02_16
     */
    if (self.longPressToBecomeFirstResponder) {
        self.longPressToBecomeFirstResponder = NO;
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"showTextViewMenuNotification" object:nil];
    }
}

- (void)showCorrectionMenu {
    
    if (_editing) {
        
        NSRange range = [self characterRangeAtIndex:self.selectedRange.location];
        if (range.location!=NSNotFound && range.length>1) {
            
            NSString *language = [[UITextChecker availableLanguages] objectAtIndex:0];
            if (!language)
                language = @"en_US";
            self.correctionRange = [_textChecker rangeOfMisspelledWordInString:_attributedString.string range:range startingAt:0 wrap:YES language:language];
            
        }
    }
    
}

- (void)showCorrectionMenuWithoutSelection {
    
    if (_editing) {
        
        NSRange range = [self characterRangeAtIndex:self.selectedRange.location];
        [self showCorrectionMenuForRange:range];
        
    } else {
        
        [self showMenu];
        
    }
    
}

- (void)showCorrectionMenuForRange:(NSRange)range {
    
    if (range.location==NSNotFound || range.length==0) return;
    
    range.location = MAX(0, range.location);
    range.length = MIN(_attributedString.string.length, range.length);
    
    [self removeCorrectionAttributesForRange:range];
    
    UIMenuController *menuController = [UIMenuController sharedMenuController];
    
    if ([menuController isMenuVisible]) return;
    _ignoreSelectionMenu = YES;
    
    NSString *language = [[UITextChecker availableLanguages] objectAtIndex:0];
    if (!language) {
        language = @"en_US";
    }
    
    NSArray *guesses = [_textChecker guessesForWordRange:range inString:_attributedString.string language:language];
    
    [menuController setTargetRect:[self menuPresentationRect] inView:self];
    
    if (guesses!=nil && [guesses count]>0) {
        
        NSMutableArray *items = [[NSMutableArray alloc] init];
        
        if (self.menuItemActions==nil) {
            self.menuItemActions = [NSMutableDictionary dictionary];
        }
        
        for (NSString *word in guesses){
            
            NSString *selString = [NSString stringWithFormat:@"spellCheckMenu_%lu:", (unsigned long)[word hash]];
            SEL sel = sel_registerName([selString UTF8String]);
            
            [self.menuItemActions setObject:word forKey:NSStringFromSelector(sel)];
            class_addMethod([self class], sel, [[self class] instanceMethodForSelector:@selector(spellingCorrection:)], "v@:@");
            
            UIMenuItem *item = [[UIMenuItem alloc] initWithTitle:word action:sel];
            [items addObject:item];
            if ([items count]>=4) {
                break;
            }
        }
        
        [menuController setMenuItems:items];
    } else {
        
        UIMenuItem *item = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"1117-TextNoReplacementsFound", nil) action:@selector(spellCheckMenuEmpty:)];
        [menuController setMenuItems:[NSArray arrayWithObject:item]];
        
    }
    
    [menuController setMenuVisible:YES animated:YES];
}

/////////////////////////////////////////////////////////////////////////////
// MARK: -
// MARK: UIMenu Actions
/////////////////////////////////////////////////////////////////////////////

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    
    if (self.correctionRange.length>0 || _ignoreSelectionMenu) {
        if ([NSStringFromSelector(action) hasPrefix:@"spellCheckMenu"]) {
            return YES;
        }
        return NO;
    }
    
    if (action==@selector(cut:)) {
        return (_selectedRange.length>0 && _editing);
    }
    else if (action==@selector(copy:)) {
        return ((_selectedRange.length>0));
    }
    else if ((action == @selector(select:) || action == @selector(selectAll:))) {
        return (_selectedRange.length==0 && [self hasText]);
    }
    else if (action == @selector(paste:)) {
        return (_editing && ([UIPasteboard pasteboardWithName:UIPasteboardNameQliq create:YES].string || [UIPasteboard generalPasteboard].string || [QliqAvatar sharedInstance].mediaFile));
    }
    else if (action == @selector(delete:)) {
        return NO;
    }
    
    return [super canPerformAction:action withSender:sender];
}

- (void)spellingCorrection:(UIMenuController*)sender {
    
    NSRange replacementRange = _correctionRange;
    
    if (replacementRange.location==NSNotFound || replacementRange.length==0) {
        replacementRange = [self characterRangeAtIndex:self.selectedRange.location];
    }
    if (replacementRange.location!=NSNotFound && replacementRange.length!=0) {
        NSString *text = [self.menuItemActions objectForKey:NSStringFromSelector(_cmd)];
        [self.inputDelegate textWillChange:self];
        [self replaceRange:[EGOIndexedRange rangeWithNSRange:replacementRange] withText:text];
        [self.inputDelegate textDidChange:self];
        replacementRange.length = text.length;
        [self removeCorrectionAttributesForRange:replacementRange];
    }
    
    self.correctionRange = NSMakeRange(NSNotFound, 0);
    self.menuItemActions = nil;
    [sender setMenuItems:nil];
    
}

- (void)spellCheckMenuEmpty:(id)sender {
    
    self.correctionRange = NSMakeRange(NSNotFound, 0);
    
}

- (void)menuDidHide:(NSNotification*)notification {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIMenuControllerDidHideMenuNotification object:nil];
    
    if (_selectionView) {
        [self showMenu];
    }
}

- (void)paste:(id)sender
{
    if ([UIPasteboard generalPasteboard].string.length) {
        [self insertText:[UIPasteboard generalPasteboard].string];
    }
    else {
        NSString *pasteText = [UIPasteboard pasteboardWithName:UIPasteboardNameQliq create:YES].string;
        
        if (pasteText.length) {
            [self insertText:pasteText];
            //[UIPasteboard pasteboardWithName:UIPasteboardNameQliq create:YES].string = @""; //AII Pasteboard
        }
        
        if ([QliqAvatar sharedInstance].mediaFile) {
            MessageAttachment *attachment = [[ MessageAttachment alloc ] initWithMediaFile:[QliqAvatar sharedInstance].mediaFile];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"AddAttachmentToMessage" object:attachment userInfo:nil];
        }
    }
}

- (void)selectAll:(id)sender {
    
    NSString *string = [_attributedString string];
    NSString *trimmedString = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    self.selectedRange = [_attributedString.string rangeOfString:trimmedString];
    
    if (self.selectedRange.location == NSNotFound){
        _selectedRange.location = _selectedRange.length;
        _selectedRange.length = 0;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(menuDidHide:) name:UIMenuControllerDidHideMenuNotification object:nil];
    
}

- (void)select:(id)sender {
    
    NSRange range = [self characterRangeAtPoint_:_caretView.center];
    self.selectedRange = range;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(menuDidHide:) name:UIMenuControllerDidHideMenuNotification object:nil];
    
}

- (void)cut:(id)sender
{
    [UIPasteboard generalPasteboard].string = @"";
    
    NSUInteger length = [_attributedString.string length];
    if (_selectedRange.location + _selectedRange.length > length) {
        return;
    }
    
    NSString *string = [_attributedString.string substringWithRange:_selectedRange];
    [UIPasteboard pasteboardWithName:UIPasteboardNameQliq create:YES].string = string;
    
    [_mutableAttributedString setAttributedString:self.attributedString];
    [_mutableAttributedString deleteCharactersInRange:_selectedRange];
    
    [self.inputDelegate textWillChange:self];
    [self setAttributedString:_mutableAttributedString];
    [self.inputDelegate textDidChange:self];
    
    self.selectedRange = NSMakeRange(_selectedRange.location, 0);
    
}

- (void)copy:(id)sender
{
    [UIPasteboard generalPasteboard].string = @"";
    
    NSUInteger length = [_attributedString.string length];
    if (_selectedRange.location + _selectedRange.length > length) {
        return;
    }
    
    NSString *string = [self.attributedString.string substringWithRange:_selectedRange];
    [UIPasteboard pasteboardWithName:UIPasteboardNameQliq create:YES].string = string;
}

- (void)delete:(id)sender {
    
    [_mutableAttributedString setAttributedString:self.attributedString];
    [_mutableAttributedString deleteCharactersInRange:_selectedRange];
    [self.inputDelegate textWillChange:self];
    [self setAttributedString:_mutableAttributedString];
    [self.inputDelegate textDidChange:self];
    
    self.selectedRange = NSMakeRange(_selectedRange.location, 0);
    
}

- (void)replace:(id)sender {
    
    
}

@end

/////////////////////////////////////////////////////////////////////////////
// MARK: -
// MARK: EGOIndexedPosition
/////////////////////////////////////////////////////////////////////////////

@implementation EGOIndexedPosition
@synthesize index=_index;

+ (EGOIndexedPosition *)positionWithIndex:(NSUInteger)index {
    EGOIndexedPosition *pos = [[EGOIndexedPosition alloc] init];
    pos.index = index;
    return pos;
}

@end


/////////////////////////////////////////////////////////////////////////////
// MARK: -
// MARK: EGOIndexedRange
/////////////////////////////////////////////////////////////////////////////

@implementation EGOIndexedRange
@synthesize range=_range;

+ (EGOIndexedRange *)rangeWithNSRange:(NSRange)theRange {
    if (theRange.location == NSNotFound)
        return nil;
    
    EGOIndexedRange *range = [[EGOIndexedRange alloc] init];
    range.range = theRange;
    return range;
}

- (UITextPosition *)start {
    return [EGOIndexedPosition positionWithIndex:self.range.location];
}

- (UITextPosition *)end {
    return [EGOIndexedPosition positionWithIndex:(self.range.location + self.range.length)];
}

-(BOOL)isEmpty {
    return (self.range.length == 0);
}

@end


/////////////////////////////////////////////////////////////////////////////
// MARK: -
// MARK: EGOContentView
/////////////////////////////////////////////////////////////////////////////

@implementation EGOContentView

@synthesize delegate=_delegate;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        
        self.userInteractionEnabled = NO;
        //self.layer.geometryFlipped = YES;
        //        self.backgroundColor = [UIColor whiteColor];
        
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self.delegate textChanged]; // reset layout on frame / orientation change
    //   [self.delegate selectionChanged];
    
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    [_delegate drawContentInRect:rect];
}

- (void)dealloc {
    
}

@end


/////////////////////////////////////////////////////////////////////////////
// MARK: -
// MARK: EGOCaretView
/////////////////////////////////////////////////////////////////////////////

@implementation EGOCaretView

static const NSTimeInterval kInitialBlinkDelay = 0.6f;
static const NSTimeInterval kBlinkRate = 1.0;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = [EGOTextView caretColor];
    }
    return self;
}

- (void)show {
    
    [self.layer removeAllAnimations];
    
}

- (void)didMoveToSuperview {
    
    if (self.superview) {
        
        [self delayBlink];
        
    } else {
        
        [self.layer removeAllAnimations];
        
    }
}

- (void)delayBlink {
    
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    animation.values = [NSArray arrayWithObjects:[NSNumber numberWithFloat:1.0f], [NSNumber numberWithFloat:1.0f], [NSNumber numberWithFloat:0.0f], [NSNumber numberWithFloat:0.0f], nil];
    animation.calculationMode = kCAAnimationCubic;
    animation.duration = kBlinkRate;
    animation.beginTime = CACurrentMediaTime() + kInitialBlinkDelay;
    animation.repeatCount = CGFLOAT_MAX;
    [self.layer addAnimation:animation forKey:@"BlinkAnimation"];
    
}

- (void)dealloc {
    
}

@end


/////////////////////////////////////////////////////////////////////////////
// MARK: -
// MARK: EGOLoupeView
/////////////////////////////////////////////////////////////////////////////

@implementation EGOLoupeView

- (id)init {
    if ((self = [super initWithFrame:CGRectMake(0.0f, 0.0f, 127.0f, 127.0f)])) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    [[UIImage imageNamed:@"loupe-lo.png"] drawInRect:rect];
    
    if ((_contentImage!=nil)) {
        
        CGContextSaveGState(ctx);
        CGContextClipToMask(ctx, rect, [UIImage imageNamed:@"loupe-mask.png"].CGImage);
        [_contentImage drawInRect:rect];
        CGContextRestoreGState(ctx);
        
    }
    
    [[UIImage imageNamed:@"loupe-hi.png"] drawInRect:rect];
    
}

- (void)setContentImage:(UIImage *)image {
    
    _contentImage = image;
    [self setNeedsDisplay];
    
}

- (void)dealloc {
    _contentImage=nil;
}

@end


/////////////////////////////////////////////////////////////////////////////
// MARK: -
// MARK: EGOTextWindow
/////////////////////////////////////////////////////////////////////////////

@implementation EGOTextWindow

@synthesize showing=_showing;
@synthesize selectionType=_selectionType;
@synthesize type=_type;

//static const CGFloat kLoupeScale = 1.2f;
//static const CGFloat kMagnifyScale = 1.0f;
static const NSTimeInterval kDefaultAnimationDuration = 0.15f;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = [UIColor clearColor];
        _type = EGOWindowLoupe;
    }
    return self;
}

- (NSInteger)selectionForRange:(NSRange)range {
    return range.location;
}



- (void)showFromView:(UIView*)view andRenderView:(UIView*)viewToRender rect:(CGRect)rect {
    
    CGPoint pos = CGPointMake(CGRectGetMinX(rect), CGRectGetMinY(rect));
    
    if (!_showing) {
        
        if (_view==nil) {
            UIView *view;
            if (_type==EGOWindowLoupe) {
                view = [[EGOLoupeView alloc] init];
            } else {
                view = [[EGOMagnifyView alloc] init];
            }
            [self addSubview:view];
            _view=view;
            
        }
        
        CGRect frame = _view.frame;
        frame.origin.x = floorf(pos.x - (_view.bounds.size.width/2));
        frame.origin.y = floorf(pos.y - _view.bounds.size.height);
        
        if (_type==EGOWindowMagnify) {
            
            frame.origin.y = MAX(frame.origin.y+8.0f, 0.0f);
            frame.origin.x += 2.0f;
            
            //            frame.origin = [s]
            
        } else {
            
            frame.origin.y = MAX(frame.origin.y-10.0f, -40.0f);
            
        }
        
        CGRect originFrame = frame;
        frame.origin.y += frame.size.height/2;
        _view.frame = frame;
        _view.transform = CGAffineTransformMakeScale(0.01f, 0.01f);
        _view.alpha = 0.01f;
        
        [UIView animateWithDuration:kDefaultAnimationDuration animations:^{
            
            _view.alpha = 1.0f;
            _view.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
            _view.frame = originFrame;
            
        } completion:^(BOOL finished) {
            
            _showing=YES;
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (0.0f*NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self renderWithContentView:viewToRender fromRect:rect];
            });
            
        }];
        
    }
    
}

- (void)showFromView:(UIView*)view rect:(CGRect)rect{
    [self showFromView:view andRenderView:view rect:rect];
}

- (void)hide:(BOOL)animated {
    
    if ((_view!=nil)) {
        
        [UIView animateWithDuration:kDefaultAnimationDuration animations:^{
            
            CGRect frame = _view.frame;
            CGPoint center = _view.center;
            frame.origin.x = floorf(center.x-(frame.size.width/2));
            frame.origin.y = center.y;
            _view.frame = frame;
            _view.transform = CGAffineTransformMakeScale(0.01f, 0.01f);
            
        } completion:^(BOOL finished) {
            
            _showing=NO;
            [_view removeFromSuperview];
            _view=nil;
            self.windowLevel = UIWindowLevelNormal;
            self.hidden = YES;
            
        }];
        
    }
    
}

//static UIImageView* testView = nil;

- (UIImage*)screenshotFromCaretFrame:(CGRect)rect inView:(UIView*)view scale:(BOOL)scale
{
    CGRect offsetRect = rect;
    offsetRect.origin.y -= scale ? 14 : 64.0;
    offsetRect.origin.x -= 64.0;
    
    
    //CGFloat magnifyScale = 1.0f;
    
    if (scale) {
        //CGFloat max = 24.0f;
        // magnifyScale = max/offsetRect.size.height;
        // NSLog(@"max %f scale %f", max, magnifyScale);
    } else if (rect.size.height < 22.0f) {
        //magnifyScale = 22.0f/offsetRect.size.height;
        //NSLog(@"cale %f", magnifyScale);
    }
    
    UIGraphicsBeginImageContextWithOptions(_view.bounds.size, YES, [[UIScreen mainScreen] scale]);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(ctx, [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0f].CGColor);
    UIRectFill(CGContextGetClipBoundingBox(ctx));
    
    CGContextSaveGState(ctx);
    
    //    CGContextConcatCTM(ctx, CGAffineTransformMakeScale(magnifyScale, magnifyScale));
    CGContextConcatCTM(ctx, CGAffineTransformMakeTranslation(-(offsetRect.origin.x), -(offsetRect.origin.y)));
    
    UIView *selectionView = nil;
    CGRect selectionFrame = CGRectZero;
    
    for (UIView *subview in view.subviews){
        if ([subview isKindOfClass:[EGOSelectionView class]]) {
            selectionView = subview;
        }
        if ([subview isKindOfClass:[EGOLoupeView class]]){
        }
    }
    
    if (selectionView!=nil) {
        selectionFrame = selectionView.frame;
        CGRect newFrame = selectionFrame;
        newFrame.origin.y = (selectionFrame.size.height - view.bounds.size.height) - ((selectionFrame.origin.y + selectionFrame.size.height) - view.bounds.size.height);
        selectionView.frame = newFrame;
    }
    
    [view.layer renderInContext:ctx];
    
    if (selectionView!=nil) {
        selectionView.frame = selectionFrame;
    }
    
    
    CGContextRestoreGState(ctx);
    UIImage *aImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return aImage;
    
}

- (void)renderWithContentView:(UIView*)view fromRect:(CGRect)rect {
    
    CGPoint pos = CGPointMake(CGRectGetMinX(rect), CGRectGetMinY(rect));
    
    if (_showing && _view!=nil) {
        
        CGRect frame = _view.frame;
        frame.origin.x = floorf((pos.x - (_view.bounds.size.width/2)) + (rect.size.width/2));
        frame.origin.y = floorf(pos.y - _view.bounds.size.height);
        
        if (_type==EGOWindowMagnify) {
            frame.origin.y = MAX(0.0f, frame.origin.y);
            rect = [self convertRect:rect toView:view];
        } else {
            frame.origin.y = MAX(frame.origin.y-10.0f, -40.0f);
            rect = [self convertRect:rect toView:view];
        }
        _view.frame = frame;
        
        UIImage *image = [self screenshotFromCaretFrame:rect inView:view scale:(_type==EGOWindowMagnify)];
        [(EGOLoupeView*)_view setContentImage:image];
        
    }
    
}

- (void)updateWindowTransform {
    
    self.frame = [[UIScreen mainScreen] bounds];
    switch ([[UIApplication sharedApplication] statusBarOrientation]) {
        case UIInterfaceOrientationPortrait:
            self.layer.transform = CATransform3DIdentity;
            break;
        case UIInterfaceOrientationLandscapeRight:
            self.layer.transform = CATransform3DMakeRotation((M_PI/180)*90, 0, 0, 1);
            break;
        case UIInterfaceOrientationLandscapeLeft:
            self.layer.transform = CATransform3DMakeRotation((M_PI/180)*-90, 0, 0, 1);
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            self.layer.transform = CATransform3DMakeRotation((M_PI/180)*180, 0, 0, 1);
            break;
        default:
            break;
    }
    
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self updateWindowTransform];
}

- (void)dealloc {
    _view=nil;
    
}

@end


/////////////////////////////////////////////////////////////////////////////
// MARK: -
// MARK: EGOMagnifyView
/////////////////////////////////////////////////////////////////////////////

@implementation EGOMagnifyView

- (id)init {
    if ((self = [super initWithFrame:CGRectMake(0.0f, 0.0f, 145.0f, 59.0f)])) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    [[UIImage imageNamed:@"magnifier-ranged-lo.png"] drawInRect:rect];
    
    if ((_contentImage!=nil)) {
        
        CGContextSaveGState(ctx);
        CGContextClipToMask(ctx, rect, [UIImage imageNamed:@"magnifier-ranged-mask.png"].CGImage);
        [_contentImage drawInRect:rect];
        CGContextRestoreGState(ctx);
        
    }
    
    [[UIImage imageNamed:@"magnifier-ranged-hi.png"] drawInRect:rect];
    
}

- (void)setContentImage:(UIImage *)image {
    
    
    _contentImage = image;
    [self setNeedsDisplay];
    
}

- (void)dealloc {
    _contentImage=nil;
    
}

@end


/////////////////////////////////////////////////////////////////////////////
// MARK: -
// MARK: EGOSelectionView
/////////////////////////////////////////////////////////////////////////////

@implementation EGOSelectionView
@synthesize dotsHidden;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
        //self.layer.geometryFlipped = YES;
        
        self.clipsToBounds = NO;
        
    }
    return self;
}

- (void)setDotsHidden:(BOOL)_dotsHidden{
    dotsHidden = _dotsHidden;
    _rightCaret.hidden = _leftCaret.hidden = _rightDot.hidden = _leftDot.hidden = dotsHidden;
}

- (void)setBeginCaret:(CGRect)begin endCaret:(CGRect)end {
    
    if(!self.superview) return;
    
    
    self.frame = CGRectMake(begin.origin.x, begin.origin.y + begin.size.height, end.origin.x - begin.origin.x, (end.origin.y-end.size.height)-begin.origin.y);
    
    begin = [self.superview convertRect:begin toView:self];
    end = [self.superview convertRect:end toView:self];
    
    
    if (_leftCaret==nil) {
        UIView *view = [[UIView alloc] initWithFrame:begin];
        view.backgroundColor = [EGOTextView caretColor];
        [self addSubview:view];
        _leftCaret= view;
        
    }
    
    if (_leftDot==nil) {
        UIImage *dotImage = [UIImage imageNamed:@"drag-dot.png"];
        UIImageView *view = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, dotImage.size.width, dotImage.size.height)];
        [view setImage:dotImage];
        [self addSubview:view];
        _leftDot = view;
        
    }
    
    CGFloat _dotShadowOffset = 5.0f;
    _leftCaret.frame = begin;
    _leftDot.frame = CGRectMake(floorf(_leftCaret.center.x - (_leftDot.bounds.size.width/2)), _leftCaret.frame.origin.y-(_leftDot.bounds.size.height-_dotShadowOffset), _leftDot.bounds.size.width, _leftDot.bounds.size.height);
    
    if (_rightCaret==nil) {
        UIView *view = [[UIView alloc] initWithFrame:end];
        view.backgroundColor = [EGOTextView caretColor];
        [self addSubview:view];
        _rightCaret = view;
    }
    
    if (_rightDot==nil) {
        UIImage *dotImage = [UIImage imageNamed:@"drag-dot.png"];
        UIImageView *view = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, dotImage.size.width, dotImage.size.height)];
        [view setImage:dotImage];
        [self addSubview:view];
        _rightDot = view;
    }
    
    _rightCaret.frame = end;
    _rightDot.frame = CGRectMake(floorf(_rightCaret.center.x - (_rightDot.bounds.size.width/2)), CGRectGetMaxY(_rightCaret.frame), _rightDot.bounds.size.width, _rightDot.bounds.size.height);
    
    _rightCaret.hidden = _leftCaret.hidden = _rightDot.hidden = _leftDot.hidden = dotsHidden;
    
}

- (void)dealloc {
    
    _leftCaret=nil;
    _rightCaret=nil;
    _rightDot=nil;
    _leftDot=nil;
    
}

@end

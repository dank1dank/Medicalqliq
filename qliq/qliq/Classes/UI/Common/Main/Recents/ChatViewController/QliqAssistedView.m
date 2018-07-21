//
//  QliqAssistedView.m
//  qliq
//
//  Created by Valerii Lider on 5/23/16.
//
//

#import "QliqAssistedView.h"
#import "ConversationTableViewCell.h"


#define kValueQliqAssistedTitleLableMargins 20.f
#define kValueQliqAssistedTitleLableTextFontSize 10.f
#define kValueQliqAssistedTitleLableTextAlignment NSTextAlignmentLeft
#define kQliqAssistedTitleLableText QliqLocalizedString(@"1954-TextQliqAssistedCallTipBox")

static CGFloat qliqAssistedTitleLableFontSize;
static UIFont *qliqAssistedTitleLableFont;
static NSTextAlignment *qliqAssistedTitleLableTextAlignment;

@interface QliqAssistedView () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UITapGestureRecognizer *tapRecognizer;

@property (nonatomic, assign) QliqAssistedViewState state;

@end

@implementation QliqAssistedView

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        
        self.tapRecognizer = [[UITapGestureRecognizer alloc] init];
        [self.tapRecognizer addTarget:self action:@selector(tapEvent:)];
        [self addGestureRecognizer:self.tapRecognizer];
        self.phoneNumbers = [NSMutableArray new];
        
        if (self.qliqAssistedTitleLabel) {
            qliqAssistedTitleLableFont = self.qliqAssistedTitleLabel.font;
            qliqAssistedTitleLableTextAlignment = self.qliqAssistedTitleLabel.textAlignment;
        }
    }
    return self;
}


#pragma mark - Public

+ (CGSize)getQliqAssistedViewSizeWithMarginsVertical:(CGFloat)verticalMargin
                                          horizontal:(CGFloat)horizontalMargin
                                        avatarOffset:(CGFloat)avatarOffset
{
    CGSize size = CGSizeZero;
    
    size = [QliqAssistedView getQliqAssistedTitleLableSizeWithMarginsVertical:verticalMargin
                                                                   horizontal:horizontalMargin
                                                                 avatarOffset:avatarOffset];
    size = CGSizeMake(size.width + (horizontalMargin * 2.0), size.height + (verticalMargin * 2.0));
    
    return size;
}

+ (CGSize)getQliqAssistedTitleLableSizeWithMarginsVertical:(CGFloat)verticalMargin
                                                horizontal:(CGFloat)horizontalMargin
                                              avatarOffset:(CGFloat)avatarOffset
{

    NSAttributedString *stringAtt = [QliqAssistedView getAttrString];
    
    CGFloat maxLableWidth = [ConversationTableViewCell getMaxWidthBubbleMessage] - (horizontalMargin * 2.0f) - avatarOffset;
    
    CTFramesetterRef frameSetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)(stringAtt));
    
    CGSize suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(frameSetter, CFRangeMake(0, stringAtt.length), NULL, CGSizeMake(maxLableWidth, CGFLOAT_MAX), NULL);
    
    if (frameSetter)
        CFRelease(frameSetter);
    
    CGSize returnSize = CGSizeMake(ceilf(suggestedSize.width), ceilf(suggestedSize.height));
    
    return returnSize;
}

+ (NSAttributedString *)getAttrString {

    NSString *text = kQliqAssistedTitleLableText;
    
    UIFont *font = [QliqAssistedView checkTitleLableFont];
    
    NSDictionary *attributes = @{NSForegroundColorAttributeName:RGBa(24, 122, 181, 1), NSFontAttributeName:font};
    NSAttributedString *stringAtt = [[NSAttributedString alloc] initWithString:text attributes:attributes];
    return stringAtt;
}

+ (NSArray *)isPhoneNumbersDetectedForChatMessage:(ChatMessage*)message {

    NSError *error;
    NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypePhoneNumber error:&error];
    NSString *text = [message.text stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    if (!text) {
        text = @"";
    }

    NSArray *matches = [detector matchesInString:text
                                         options:0
                                           range:NSMakeRange(0, [text length])];
    return matches;
}

- (BOOL)configureQliqAssistedViewWithMessage:(ChatMessage*)message
{
    BOOL hideQliqAssistedView = YES;
    
    self.state = QliqAssistedViewStateUnchecked;
    
    if (self.state != QliqAssistedViewStateChecked) {
        
        self.qliqAssistedTitleLabel.attributedText = [QliqAssistedView getAttrString];
        
        NSArray *matches = [QliqAssistedView isPhoneNumbersDetectedForChatMessage:message];
        
        if ([matches count] > 0 && self.state == QliqAssistedViewStateUnchecked)
        {
            hideQliqAssistedView = NO;
            
            [self.phoneNumbers removeAllObjects];
            
            for (NSTextCheckingResult *match in matches) {
                if ([match resultType] == NSTextCheckingTypePhoneNumber) {
                    NSString *phoneNumber = [match phoneNumber];
                    [self.phoneNumbers addObject:phoneNumber];
                }
            }
            
        } else {
            hideQliqAssistedView = YES;
        }

    } else {
        hideQliqAssistedView = YES;
    }
    return hideQliqAssistedView;
}

- (NSString *)getCorrectedPhoneNumberForPhoneUrl:(NSString *)phoneUrl {

    NSString *selectedPhoneUrl = [phoneUrl stringByReplacingOccurrencesOfString:@"%20" withString:@""];
    selectedPhoneUrl = [selectedPhoneUrl stringByReplacingOccurrencesOfString:@"tel:" withString:@""];
    NSString *correctedPhoneUrl = nil;
    for (NSString *phoneNumber in self.phoneNumbers) {

        @try {
            NSRange range = [phoneNumber rangeOfString:selectedPhoneUrl];
            if ([[phoneNumber substringWithRange:range] isEqualToString:selectedPhoneUrl]) {
                correctedPhoneUrl = phoneNumber;
            }
        } @catch (NSException *exception) {
            break;
        }
    }

    if (!correctedPhoneUrl) {
        correctedPhoneUrl = selectedPhoneUrl;
    }
    return correctedPhoneUrl;
}

+ (NSString *)getCorrectedPhoneNumberForMessage:(ChatMessage *)message {

    NSArray *matches = [QliqAssistedView isPhoneNumbersDetectedForChatMessage:message];
    NSString *correctedMessage = nil;
    if ([matches count] > 0)
    {
        for (NSTextCheckingResult *match in matches) {
            if ([match resultType] == NSTextCheckingTypePhoneNumber) {

                @try {

                    NSRange range = match.range;
                    NSString *textPhone = [message.text substringWithRange:match.range];
                    NSString *correctedPhoneNumber = nil;
                    NSRange corerctedRange = NSMakeRange(0, 0);
                    if ([textPhone containsString:@"("]) {
                        corerctedRange = [textPhone rangeOfString:@"("];
                        correctedPhoneNumber = [textPhone substringWithRange:NSMakeRange(corerctedRange.location, textPhone.length - 1)];
                    }
                    if ([textPhone containsString:@")"] && (corerctedRange.location != 0 || corerctedRange.length != 0)) {
                        correctedPhoneNumber = [textPhone substringWithRange:NSMakeRange([textPhone rangeOfString:@"("].location, match.range.length - [textPhone rangeOfString:@")"].location)];
                    }
                    else if ([textPhone containsString:@")"]) {
                        range = [textPhone rangeOfString:@")"];
                        correctedPhoneNumber = [textPhone substringWithRange:NSMakeRange(0, [textPhone rangeOfString:@")"].location)];
                    }

                    if (correctedPhoneNumber.length > 0) {

                        NSString *validPhone = [correctedPhoneNumber stringByReplacingOccurrencesOfString:@" " withString:@""];
                        NSString *validPhoneNumberMessage = [message.text stringByReplacingOccurrencesOfString:correctedPhoneNumber withString:validPhone];
                        correctedMessage = validPhoneNumberMessage;
                    }

                } @catch (NSException *exception) {
                    DDLogError(@"exception during correcting phone number: %@",[exception reason]);
                }
            }
        }
    }
    return correctedMessage;
}

#pragma mark - Private

+ (UIFont *)checkTitleLableFont {
    return [UIFont systemFontOfSize:kValueQliqAssistedTitleLableTextFontSize];
}

+ (NSTextAlignment)checkTitleLableTextAlignment {
    
    if (!qliqAssistedTitleLableTextAlignment) {
        qliqAssistedTitleLableFontSize = kValueQliqAssistedTitleLableTextAlignment;
    }
    
    return qliqAssistedTitleLableTextAlignment;
}

- (void)replaceQliqAssitedView
{
//    if (self.delegate && [self.delegate respondsToSelector:@selector(replaceQliqAssistedView:)]) {
//        [self.delegate replaceQliqAssistedView:self];
//    }
}

#pragma mark - GestureReconizersActions

- (void)tapEvent:(UITapGestureRecognizer *)sender
{
    CGPoint touch = [sender locationInView:self];
    if(CGRectContainsPoint(self.bounds, touch))
    {
        if (self.delegate && [self.delegate respondsToSelector:@selector(tapDetectedForQliqAssistedView:)]) {
            [self.delegate tapDetectedForQliqAssistedView:self];
        }
        
        [self replaceQliqAssitedView];
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    CGPoint touch = [gestureRecognizer locationInView:self];
    if(CGRectContainsPoint(self.bounds, touch))
        return YES;
    
    return NO;
}

@end

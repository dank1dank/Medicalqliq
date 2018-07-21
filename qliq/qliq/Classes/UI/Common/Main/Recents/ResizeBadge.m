//
//  ResizeBadge.m
//  qliq
//
//  Created by Valerii Lider on 10/07/16.
//
//

#import "ResizeBadge.h"

#define kBadgeMargin 2.f
#define kTextPadding 1.f
#define kMinBadgeWidth 14.f

//The flag if using the maximum width of two digit
#define kValueUnreadBadgeMoreThenTwoDigits 1

@implementation ResizeBadge

+ (void)resizeBadge:(UILabel *)badge
        totalFreeSpace:(CGFloat)totalFreeSpace
        canTextBeScaled:(BOOL)canTextBeScaled
            setBadgeWidthCompletion:(void(^)(CGFloat calculatedWidth))completion
{
    CGFloat calculatedWidthBadge = 0;
    NSString *replaceBadgeText = nil;
    
    /*
     If badge can contained maximum only two digit, we need to resize badge width,
     using the existing badge text, because text should be scaled in case of overflow.
     */
    replaceBadgeText = (kValueUnreadBadgeMoreThenTwoDigits != 1 && badge.text.length > 2) ? [NSString stringWithFormat:@"%@+", [badge.text substringFromIndex:badge.text.length - 2]] : canTextBeScaled ? badge.text : [NSString stringWithFormat:@"%@+", badge.text];
    
    NSUInteger  rangeLength = canTextBeScaled ? replaceBadgeText.length : replaceBadgeText.length - 1;
    
    CGFloat neededWidthText = [ResizeBadge calculatingNeededWidthForBadge:replaceBadgeText rangeLength:rangeLength font:badge.font];
    CGFloat maxWidthBadge = totalFreeSpace;
    
    if (neededWidthText > maxWidthBadge)
    {
        while (neededWidthText > maxWidthBadge)
        {
            /*
             The condition is used to correct display of badge in case, when it exceeds max allowable width.
             In this case we decrease count of significant digits, begins from the higher digits. And display badge as overflowed.
             
             If `canTextBeScaled` is true, `replaceBadgeText` contains string without `+`, otherwise with `+`. So, when we check minimum length of current `replaceBadgeText`, we should consider min length as 2, if `canTextBeScaled` is true, or - as 3, if `canTextBeScaled` is false, because we should not allow decreasing count of  significant digits less then two.
             */
            if (((!canTextBeScaled && replaceBadgeText.length > 3) || (canTextBeScaled && replaceBadgeText.length > 2)) && kValueUnreadBadgeMoreThenTwoDigits == 1)
            {
                replaceBadgeText = [ResizeBadge replaceBadgeText:replaceBadgeText rangeLength:replaceBadgeText.length font:badge.font];
                replaceBadgeText = [replaceBadgeText substringFromIndex:1];
                neededWidthText = [replaceBadgeText sizeWithAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:badge.font.pointSize]}].width;
            }
            else
            {
                break;
            }
        }
        
        if (!canTextBeScaled)
        {
            calculatedWidthBadge = neededWidthText;
            badge.text = replaceBadgeText;
        }
        else
        {   //`canTextBeScaled` is true, so we
            //need to setup width and shift of badge before setting of text
            if (completion)
                completion(maxWidthBadge);
            
            badge.adjustsFontSizeToFitWidth = YES;
            badge.text = kValueUnreadBadgeMoreThenTwoDigits != 1 ? replaceBadgeText : [NSString stringWithFormat:@"%@+", replaceBadgeText];
            return;
        }
    }
    //If neededWidthText < maxWidthBadge
    else
    {
        NSUInteger rangeLength = badge.text.length;
        
        if (kValueUnreadBadgeMoreThenTwoDigits != 1 && badge.text.length > 2)
        {
            badge.text = replaceBadgeText;
            rangeLength = badge.text.length - 1;
        } 
        
        //We don`t have overflow and needed count of digits can be displayed in bounds of max allowable width, so we
        //no need consider `+` while calculating needed width of current badge text, because it will be fit in any case.
        //We should calculate needed width for count of digits current badge text.
        neededWidthText = [ResizeBadge calculatingNeededWidthForBadge:badge.text rangeLength:rangeLength font:badge.font];
        calculatedWidthBadge = neededWidthText;
        
        //If badgeText have one digit, we need to set widthBadge with minBadgeWidth
        if (calculatedWidthBadge < kMinBadgeWidth)
            calculatedWidthBadge = kMinBadgeWidth;
    }
    
    //Adding the pixels for fixing the sizeWithAttributes textBadge
    if (replaceBadgeText.length > 1)
    {
        calculatedWidthBadge = calculatedWidthBadge + kTextPadding;
    }
    
    //Configuring of badge width and shift constraints
    if (completion)
        completion(calculatedWidthBadge);
}

+(CGFloat)calculatingNeededWidthForBadge:(NSString *)text rangeLength:(NSInteger)rangeLength font:(UIFont *)font
{
    NSString *replaceBadgeText = [ResizeBadge replaceBadgeText:text rangeLength:rangeLength font:font];
    
    CGSize neededSizeText = [replaceBadgeText sizeWithAttributes:@{NSFontAttributeName:font}];
    CGFloat neededWidthBadgeText = neededSizeText.width + 2.f;
    
    return neededWidthBadgeText;
}

+(NSString *)replaceBadgeText:(NSString *)badgeText rangeLength:(NSInteger)rangeLength font:(UIFont *)font
{
    NSError *error = nil;
    NSRegularExpression *regExBadgeText = [NSRegularExpression regularExpressionWithPattern:@"[0-8]"
                                                                                    options:NSRegularExpressionCaseInsensitive
                                                                                      error:&error];
    if (error != nil)
    {
        DDLogSupport(@"RegEx wasn't created with error: %@",[error localizedDescription]);
    }
    else
    {
        //Replace the text in the `9` to get the maximum width of the badgeText for current count of digits
        badgeText = [regExBadgeText stringByReplacingMatchesInString:badgeText
                                                        options:0
                                                          range:NSMakeRange(0, rangeLength)
                                                   withTemplate:@"9"];
    }
    return badgeText;
}

@end

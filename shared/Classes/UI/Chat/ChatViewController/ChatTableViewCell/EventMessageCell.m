//
//  EventMessageCell.m
//  qliq
//
//  Created by Aleksey Garbarev on 27.12.12.
//
//

#import "EventMessageCell.h"
#import "ChatEventHelper.h"
#import "NSDate+Format.h"

@implementation EventMessageCell{
    QliqLabel * textLabel;
    QliqLabel * dateLabel;
}

const CGFloat kMessageFontSize   = 14.0f;
const CGFloat kDateFontSize      = 12.0f;

const UIEdgeInsets backgroundInsets = { .top = 3, .bottom = 7, .left = 0,  .right = 0};
const UIEdgeInsets messageInsets    = { .top = 3, .bottom = 1, .left = 15, .right = 15};
const UIEdgeInsets dateInsets       = { .top = 1, .bottom = 3, .left = 0,  .right = 0};

#define kDateLabelLineHeight (kDateFontSize)

@synthesize message;

#define UIEdgeInsetGetWidth(inset)  (inset.left + inset.right)
#define UIEdgeInsetGetHeight(inset) (inset.top + inset.bottom)

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        /* Configure background view */
        CGRect backgroundFrame;
        backgroundFrame.origin = CGPointMake(backgroundInsets.left, backgroundInsets.top);
        backgroundFrame.size = CGSizeMake(self.width - UIEdgeInsetGetWidth(backgroundInsets), self.height - UIEdgeInsetGetHeight(backgroundInsets));
        
        UIView * backgroundView = [[UIView alloc] initWithFrame:backgroundFrame];
        
        backgroundView.autoresizingMask = UIViewAutoresizingAll;
        //        backgroundView.backgroundColor = [UIColor darkGrayColor];
        backgroundView.backgroundColor = [UIColor colorWithWhite:0.5 alpha:1.0f];
        // backgroundView.layer.cornerRadius =  5.0f;
        backgroundView.layer.shouldRasterize = YES;
        
        CGPathRef path = CGPathCreateWithRect(CGRectMake(0, 0, backgroundFrame.size.width, 2), NULL);
        if (path) {
            
            backgroundView.layer.shadowPath = path;
            CFRelease(path);
        }
        
        backgroundView.layer.shadowRadius = 0.3;
        backgroundView.layer.shadowColor  = [[UIColor blackColor] CGColor];
        backgroundView.layer.shadowOffset = CGSizeMake(0, 1);
        
        
        [self addSubview:backgroundView];
        
        /* Configure message label */
        CGRect labelFrame;
        labelFrame.origin = CGPointMake(messageInsets.left, messageInsets.top);
        labelFrame.size = CGSizeMake(backgroundView.width - UIEdgeInsetGetWidth(messageInsets), backgroundView.height - UIEdgeInsetGetHeight(messageInsets) - (UIEdgeInsetGetHeight(dateInsets) + kDateLabelLineHeight) );
        
        textLabel = [[QliqLabel alloc] initWithFrame:labelFrame style:QliqLabelStyleNormal];
        [textLabel setFontSize:kMessageFontSize];
        textLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        textLabel.numberOfLines = NSIntegerMax;
        textLabel.textColor = [UIColor whiteColor];
        // M: Rasterize the label to blurred text
        textLabel.layer.shouldRasterize = YES;
        textLabel.shadowOffset = CGSizeMake(0.2, 0.2);
        textLabel.shadowColor = [UIColor whiteColor];
        [backgroundView addSubview:textLabel];
        
        /* Configure date label */
        CGRect dateFrame;
        dateFrame.origin = CGPointMake(dateInsets.left, backgroundView.height - (dateInsets.bottom + kDateLabelLineHeight));
        dateFrame.size = CGSizeMake(backgroundView.width - UIEdgeInsetGetWidth(dateInsets), kDateLabelLineHeight);
        
        dateLabel = [[QliqLabel alloc] initWithFrame:dateFrame style:QliqLabelStyleNormal];
        dateLabel.textAlignment = NSTextAlignmentCenter;
        [dateLabel setFontSize:kDateFontSize];
        dateLabel.numberOfLines = 1;
        dateLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        dateLabel.textColor = [UIColor whiteColor];
        // M: Rasterize the label to blurred text
        dateLabel.layer.shouldRasterize = YES;
        [backgroundView addSubview:dateLabel];
        
        
    }
    return self;
}

- (void)setMessage:(ChatMessage *)_message
{    
    textLabel.text = [ChatEventHelper eventToString: _message.text];
    
    dateLabel.text = [[NSDate dateWithTimeIntervalSince1970:_message.timestamp] stringWithTimeAndDate];
    
    message = _message;
}

+ (CGSize) sizeForText:(NSString *) text{
    
    CGSize size = CGSizeZero;
    CGFloat width = 320 - (UIEdgeInsetGetWidth(messageInsets) + UIEdgeInsetGetWidth(backgroundInsets));
    
    if ([text respondsToSelector:@selector(boundingRectWithSize:options:attributes:context:)]) {
        
        size = [text boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX)
                                  options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:kMessageFontSize]} context:nil].size;
        
    }

    size.height += 4;
    return size;
}

+ (CGFloat) heightForRowWithMessage:(ChatMessage *) _message{
	
    NSString * text = [ChatEventHelper eventToString: _message.text];
    
    CGSize size = [self sizeForText:text];
        
    return size.height + UIEdgeInsetGetHeight(messageInsets) + UIEdgeInsetGetHeight(backgroundInsets) + UIEdgeInsetGetHeight(dateInsets) + kDateLabelLineHeight;
}

@end

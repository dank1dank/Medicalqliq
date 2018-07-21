//
//  UIViewControllers+Additions.m
//  CCiPhoneApp
//
//  Created by Marcin Zbijowski on 28/04/2011.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import "UIViewController+Additions.h"
#import "QliqModulesController.h"
#import "QliqModuleProtocol.h"
#import "QliqButton.h"

#import <objc/runtime.h>

@interface UIViewController (QliqAdditionsPrivate)

- (UIButton *)buttonWithImage:(UIImage *)image tag:(NSInteger)tag width:(CGFloat)width height:(CGFloat)height;

@end

@implementation UIViewController (QliqAdditions)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        
        //Swizzle viewWillApear:
        {
            SEL originalSelector = @selector(viewWillAppear:);
            SEL swizzledSelector = @selector(qliq_viewWillAppear:);
            
            Method originalMethod = class_getInstanceMethod(class, originalSelector);
            Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
            
            // When swizzling a class method, use the following:
            // Class class = object_getClass((id)self);
            // ...
            // Method originalMethod = class_getClassMethod(class, originalSelector);
            // Method swizzledMethod = class_getClassMethod(class, swizzledSelector);
            
            BOOL didAddMethod =
            class_addMethod(class,
                            originalSelector,
                            method_getImplementation(swizzledMethod),
                            method_getTypeEncoding(swizzledMethod));
            
            if (didAddMethod) {
                class_replaceMethod(class,
                                    swizzledSelector,
                                    method_getImplementation(originalMethod),
                                    method_getTypeEncoding(originalMethod));
            } else {
                method_exchangeImplementations(originalMethod, swizzledMethod);
            }
        }
        
        //Swizzle viewWillDisappear:
        {
            SEL originalSelector = @selector(viewWillDisappear:);
            SEL swizzledSelector = @selector(qliq_viewWillDisappear:);
            
            Method originalMethod = class_getInstanceMethod(class, originalSelector);
            Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);

            BOOL didAddMethod =
            class_addMethod(class,
                            originalSelector,
                            method_getImplementation(swizzledMethod),
                            method_getTypeEncoding(swizzledMethod));
            
            if (didAddMethod) {
                class_replaceMethod(class,
                                    swizzledSelector,
                                    method_getImplementation(originalMethod),
                                    method_getTypeEncoding(originalMethod));
            } else {
                method_exchangeImplementations(originalMethod, swizzledMethod);
            }
        }
    });
}

- (void)qliq_viewWillAppear:(BOOL)animated {
    DDLogSupport(@"viewWillAppear %@", NSStringFromClass([self class]) );
    
    [self qliq_viewWillAppear:animated];
}

- (void)qliq_viewWillDisappear:(BOOL)animated {
    DDLogSupport(@"viewWillDisappear %@", NSStringFromClass([self class]) );
    
    [self qliq_viewWillDisappear:animated];
}

- (void)setNavigationBarBackgroundImage:(UIImage*)image
{
    if([self.navigationController.navigationBar respondsToSelector:@selector(setBackgroundImage:forBarMetrics:)] ) 
    {
        //iOS 5 new UINavigationBar custom background
        [self.navigationController.navigationBar setBackgroundImage:image forBarMetrics: UIBarMetricsDefault];
        return;
    }
    
    BOOL isBgThere = NO;
    for (UIView *v in self.navigationController.navigationBar.subviews)
    {
        if ([v isKindOfClass:[UIImageView class]] && v.bounds.size.width > 200)
        {
            isBgThere = YES;
            UIImageView *bgView = (UIImageView *)v;
            bgView.image = image;
            [self.navigationController.navigationBar sendSubviewToBack:bgView];
            break;
        }
    }
    
    if (!isBgThere)
    {
        UIImageView *bgView = [[UIImageView alloc] initWithImage:image];
        [self.navigationController.navigationBar insertSubview:bgView atIndex:0];
        [bgView release];
    }
}

- (void)setNavigationBarBackgroundImage 
{
//    UIImage *image = [UIImage imageNamed:@"bgNavigationBar"];
    [self setNavigationBarBackgroundImage:nil];
}

- (void)setNavigationBarBackgroundOfflineImage
{
    /*
    UIImage *image = [UIImage imageNamed:@"bg_nav_offline.png"];
    [self setNavigationBarBackgroundImage:image];
     */
}

- (UIButton*)leftLogoButton
{
    UIButton* logoView = [UIButton buttonWithType: UIButtonTypeCustom];
    UIImage *logoImage = [[[QliqModulesController sharedInstance] getPresentedModule] moduleLogo];
    if(logoImage == nil)
    {
        logoImage = [UIImage imageNamed:@"qliq_logo"];
    }
    logoView.frame = CGRectMake(0.0, 0.0, logoImage.size.width, logoImage.size.height);
    [logoView setBackgroundImage: logoImage forState: UIControlStateNormal];
    [logoView addTarget:self action: @selector(presentSettings:) forControlEvents:UIControlEventTouchUpInside];
    return logoView;
}

- (UIBarButtonItem *)leftLogoItem
{
    UIBarButtonItem *leftButton=[[[UIBarButtonItem alloc] initWithCustomView:[self leftLogoButton]] autorelease];

    return leftButton;
}

- (UIBarButtonItem *) itemWithTitle:(NSString * ) title button:(QliqButton *) button{
    UIView * itemView = [[UIView alloc] init];
    
    UIFont * labelFont = [UIFont boldSystemFontOfSize:16.0f];
    
    CGSize sizeOriginal = [title sizeWithAttributes:@{NSFontAttributeName : labelFont}];
    CGSize labelSize = CGSizeMake(ceilf(sizeOriginal.width), ceilf(sizeOriginal.height));
    
    CGFloat labelWidth = labelSize.width;
    
    UILabel *titleLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0.0, 2, labelWidth, 40)] autorelease];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.text = title;
    titleLabel.textAlignment = NSTextAlignmentRight;
    titleLabel.textColor = [UIColor colorWithWhite:0.949 alpha:1.0f];
    titleLabel.font = labelFont;
    titleLabel.adjustsFontSizeToFitWidth = NO;
    
    [itemView addSubview:titleLabel];
    
    CGRect frame = button.frame;
    frame.origin.x = labelWidth + 5;
    frame.origin.y = (44 - frame.size.height)/2;
    button.frame = frame;
    
    [itemView addSubview:button];
    
    itemView.frame = CGRectMake(0, 0, CGRectGetMaxX(button.frame) + 5, 44);
    UIBarButtonItem * item = [[[UIBarButtonItem alloc] initWithCustomView:itemView] autorelease];
    [itemView release];
    
    return item;
    
}

- (UIBarButtonItem *) itemWithTitle:(NSString * )title subtitle:(NSString *)subtitle button:(QliqButton *)button leftView:(UIView *)leftView
{
    UIBarButtonItem *item = [self itemWithTitle:title subtitle:subtitle button:button];
    CGRect frame = leftView.frame;
    
    if (subtitle.length && title.length) {
        frame.origin.y -= frame.size.height / 5.f;
    } else {
        frame.origin.y = 0;
    }
    frame.origin.x = -leftView.frame.size.width;
    
    leftView.frame = frame;
    item.customView.clipsToBounds = NO;
    [item.customView addSubview:leftView];
    return item;
}

- (UIBarButtonItem *) itemWithTitle:(NSString * ) title subtitle:(NSString *) subtitle button:(QliqButton *) button{

    UIView * itemView = [[[UIView alloc] init] autorelease];
    
    QliqLabel * titleLabel = [[[QliqLabel alloc] initWithFrame:CGRectZero style:QliqLabelStyleBold] autorelease];
    [titleLabel setFontSize:13];
    [titleLabel setTextColor:[UIColor whiteColor]];
    titleLabel.text = title;
    titleLabel.adjustsFontSizeToFitWidth = NO;
    [titleLabel sizeToFit];
    [titleLabel setFrameOriginY:0];
    
    QliqLabel * subtitleLabel = [[[QliqLabel alloc] initWithFrame:CGRectZero style:QliqLabelStyleNormal] autorelease];
    [subtitleLabel setFontSize:13];
    [subtitleLabel setTextColor:[UIColor whiteColor]];
    subtitleLabel.text = subtitle;
    subtitleLabel.adjustsFontSizeToFitWidth = NO;
    [subtitleLabel sizeToFit];
    
    
    titleLabel.width = MIN(titleLabel.width, 110);
    titleLabel.x = 0;
    subtitleLabel.width = MIN(subtitleLabel.width, 110);
    subtitleLabel.x = 0;
    
    
    CGFloat heightForTitle = 44 - subtitleLabel.frame.size.height;
    CGFloat heightForSubtitle = 44 - titleLabel.frame.size.height;

    [titleLabel setFrameOriginY: CGRectGetMaxY(titleLabel.frame) + (heightForSubtitle - subtitleLabel.frame.size.height)/(int)2];
    [subtitleLabel setFrameOriginY: (heightForTitle - titleLabel.frame.size.height)/(int)2];

    
    
    CGFloat maxWidth = MAX(titleLabel.frame.size.width, subtitleLabel.frame.size.width);

    [itemView addSubview:titleLabel];
    [itemView addSubview:subtitleLabel];

    
    CGRect frame = button.frame;
    frame.origin.x = maxWidth + 5;
    frame.origin.y = (44 - frame.size.height)/2;
    button.frame = frame;
    
    [itemView addSubview:button];
    
    itemView.frame = CGRectMake(0, 0, CGRectGetMaxX(button.frame) + 5, 44);
    UIBarButtonItem * item = [[[UIBarButtonItem alloc] initWithCustomView:itemView] autorelease];
    
    return item;
    
}
/*
- (PatientHeaderView *)patientHeader:(Census_old *)censusObj dateOfService:(NSTimeInterval)dos delegate:(id<PatientHeaderViewDelegate>)delegate {
    PatientHeaderView *patientHeader = [[PatientHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, [UIScreen mainScreen].bounds.size.width, 46.0f)];
    patientHeader.censusObj = censusObj;
	patientHeader.delegate = delegate;
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MMM\ndd"];
    patientHeader.dateLabel.text = [formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:dos]];
    [formatter release];
    return [patientHeader autorelease];
}*/

- (UIButton *)icdCellChevronWithTag:(NSInteger)tag width:(CGFloat)width height:(CGFloat)height {
    UIImage *accessoryImage = [UIImage imageNamed:@"cell-chevron"];
    return [self buttonWithImage:accessoryImage tag:tag width:width height:height];
}

- (UIButton *)icdCellChevronWithTag:(NSInteger)tag {
    return [self icdCellChevronWithTag:tag width:0 height:0];
}

- (UIButton *)cptCellChevronWithTag:(NSInteger)tag width:(CGFloat)width height:(CGFloat)height {
    UIImage *accessoryImage = [UIImage imageNamed:@"white-chevron"];
    return [self buttonWithImage:accessoryImage tag:tag width:width height:height];
}

- (UIButton *)cptCellChevronWithTag:(NSInteger)tag {
    return [self cptCellChevronWithTag:tag width:0 height:0];
}



#pragma mark -
#pragma mark Private

- (UIButton *)buttonWithImage:(UIImage *)image tag:(NSInteger)tag width:(CGFloat)width height:(CGFloat)height {
    UIButton *accessoryButton = [UIButton buttonWithType:UIButtonTypeCustom];
    accessoryButton.tag = tag;
    CGRect frame = accessoryButton.frame;
    frame.size.width = image.size.width;
    frame.size.height = image.size.height;
    if (height > 0) {
        frame.size.height = height;
    }
    if (width > 0) {
        frame.size.width = width;
    }
    accessoryButton.frame = frame;
    [accessoryButton setImage:image forState:UIControlStateNormal];
    return accessoryButton;
}

@end

//
//  QliqBarButtonItem.h
//  qliq
//
//  Created by Aleksey Garbarev on 22.06.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kBarButtonHeight 51


@interface QliqBarButtonItem : UIBarButtonItem

@property (nonatomic) BOOL selected;
//@property (nonatomic) BOOL enabled;
@property (nonatomic) NSUInteger badgeValue;

@property (nonatomic, strong) NSString * targetIdentifier;

@property (nonatomic, readonly, strong) QliqButton * button;

- (id) initWithButtonImage:(UIImage *) image targetIdentifier:(NSString *) targetIdentifier actionBlock:(void(^)(QliqBarButtonItem * item))block;
- (id) initWithButtonImage:(UIImage *) image actionBlock:(void(^)(QliqBarButtonItem * item))block;
- (id) initWithTitle:(NSString *)title actionBlock:(void(^)(QliqBarButtonItem * item))block;

- (id) initWithFrame:(CGRect) frame buttonStyle:(QliqButtonStyle) style actionBlock:(void(^)(QliqBarButtonItem * item))block;

@end

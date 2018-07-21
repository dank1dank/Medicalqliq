//
//  StartView.h
//  qliq
//
//  Created by Aleksey Garbarev on 07.06.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StartView : UIView

typedef enum {StartViewTypeNone, StartViewTypeFirstLaunch, StartViewTypeWipe, StartViewTypeLock, StartViewTypeAttemptsLock} StartViewType;

@property (nonatomic) BOOL shouldHideStatusBar;

- (id) initWithType:(StartViewType) type andFrame:(CGRect)frame;
- (void) setType:(StartViewType) type animated:(BOOL)animated;
- (StartViewType) type;

- (void)removeFromSuperviewAnimationComplete:(void(^)(BOOL finished)) animationBlock;
- (void)removeFromSuperviewAnimation:(void(^)(void))animationBlock complete:(void(^)(BOOL finished)) completeBlock;

- (void) setDidDemoBlock:(void(^)(void))demoBlock;
- (void) setDidRegisterBlock:(void(^)(void))registerBlock;
- (void) setDidLoginBlock:(void(^)(void))loginBlock;
- (void) setUnlockBlock:(void(^)(void))_unlockBlock;


@end

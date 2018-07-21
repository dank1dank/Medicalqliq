//
//  WEPopoverController+LockScreenFix.h
//  qliq
//
//  Created by Developer on 22.11.13.
//
//

#import "WEPopoverController.h"

@interface WEPopoverController (LockScreenFix)

- (void)hidePopoverAnimated:(BOOL)animated;

- (void)showPopoverFromRect:(CGRect)rect
                     inView:(UIView *)view
   permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections
                   animated:(BOOL)animated;
    
@end

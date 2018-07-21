//
//  UIDevice+UUID.h
//  qliq
//
//  Created by Aleksey Garbarev on 24.09.13.
//
//

#import <UIKit/UIKit.h>

@interface UIDevice (UIDevice_UUID)

- (NSString *) qliqUUID;
- (BOOL) isAvailableInKeychain;


@end

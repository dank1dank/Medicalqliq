//
//  QliqAccess.h
//  qliq
//
//  Created by Valerii Lider on 30/07/15.
//
//

#import <Foundation/Foundation.h>

typedef void (^AccessBlock)(BOOL granted);

@interface QliqAccess : NSObject

+ (QliqAccess *)sharedInstance;

+ (void)hasMicrophoneAccess:(AccessBlock)accessBlock;
+ (void)hasCameraAccess:(AccessBlock)accessBlock;
+ (void)hasPhotoLibraryAccess:(AccessBlock)accessBlock;

@end

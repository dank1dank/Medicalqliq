//
//  QliqSign.h
//  QliqSign
//
//  Created by macb on 11/1/16.
//  Copyright © 2016 macb. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for QliqSign.
FOUNDATION_EXPORT double QliqSignVersionNumber;

//! Project version string for QliqSign.
FOUNDATION_EXPORT const unsigned char QliqSignVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <QliqSign/PublicHeader.h>

#import <QliqSign/QSCaptureSession.h>
#import <QliqSign/QSImagePickerController.h>
#import <QliqSign/QSPagesViewController.h>
#import <QliqSign/QSPDFPreviewController.h>
#import <QliqSign/QSNavigationController.h>
#import <QliqSign/QSPDFPreview.h>

@interface QliqSign : NSObject

//init
- (id)initWithName :(const char*)name company:(const char*)company mail:(const char*)mail serial:(const char*)serial;
//add document history
- (int)qliqsignAddAuditLog :(NSString *)pdfFile :(int)event :(NSDate *)date :(NSString *)message;

@end

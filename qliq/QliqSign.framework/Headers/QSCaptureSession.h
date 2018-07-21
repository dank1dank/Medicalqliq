//
//  QSCaptureSession.h
//  QliqSign
//
//  Created by macb on 9/20/16.
//  Copyright © 2016 macb. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface QSCaptureSession : NSObject
{
    BOOL flashOn;
}

@property (strong, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;
@property (strong, nonatomic) AVCaptureSession *captureSession;
@property (strong, nonatomic) AVCaptureStillImageOutput *stillImageOutput;
@property (strong, nonatomic) UIImage *stillImage;
    
- (void)addVideoPreviewLayer;
- (void)addStillImageOutput;
- (void)captureStillImage;
- (void)addVideoInputFromCamera;
    
- (void)setFlashOn:(BOOL)boolWantsFlash;
    
@end

//
//  AttachmentView.h
//  qliq
//
//  Created by Paul Bar on 4/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MessageAttachment;
@class AttachmentView;

@protocol AttachmentViewDelegate <NSObject>

-  (void) attachmentViewTaped:(AttachmentView*)attachmentView;

@end

@interface AttachmentView : UIView

@property (nonatomic, weak) id<AttachmentViewDelegate> delegate;

/**
 UI
 */
@property (nonatomic, strong) UIImageView *thumbnailView;
@property (nonatomic, strong) UIImageView * errorIcon;
@property (nonatomic, strong) UITapGestureRecognizer *tapRecognizer;
@property (nonatomic, strong) UIProgressView * progressBar;

/**
 Data
 */
@property (nonatomic, assign) BOOL isLeft;
@property (nonatomic, assign) NSInteger deliveryStatus;
@property (nonatomic, strong) MessageAttachment* attachment;

/**
 Methods
 */

- (void)setThumbnail:(UIImage*)thumbnail;
- (void)setShowError:(BOOL)isError;
- (void)setShowProgress:(BOOL)inProgress;
- (void)setProgress:(CGFloat)progress;
- (void)setAttachment:(MessageAttachment *)attachment;

- (void)updateStatus;

@end

//
//  AttachmentView.m
//  qliq
//
//  Created by Paul Bar on 4/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AttachmentView.h"
#import "MessageAttachment.h"
#import <QuartzCore/QuartzCore.h>
#import "MediaFileService.h"
#import "MessageAttachmentDBService.h"

@interface AttachmentView()

- (void)tapAction:(UITapGestureRecognizer*)tapRecognizer;

@end

@implementation AttachmentView

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [self initialization];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self initialization];
    }
    return self;
}

- (void)initialization
{
    // Initialization code
    {
        self.thumbnailView = [[UIImageView alloc] init];
        self.thumbnailView.contentMode =  UIViewContentModeScaleAspectFill;
        self.thumbnailView.clipsToBounds = YES;
        self.thumbnailView.opaque = NO;
        self.thumbnailView.backgroundColor  = [UIColor clearColor];
        [self addSubview:self.thumbnailView];
    }
    
    {
        self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
        [self addGestureRecognizer:self.tapRecognizer];
    }
    
    {
        self.progressBar = [[UIProgressView alloc] init];
        [self addSubview:self.progressBar];
    }
    
    {
        self.errorIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"exclamation_mark"]];
        self.errorIcon.contentMode = UIViewContentModeScaleToFill;
        [self addSubview:self.errorIcon];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.thumbnailView.frame = CGRectMake(0.0, 0.0, self.frame.size.width, self.frame.size.height);
    self.progressBar.frame   = CGRectMake(3, self.frame.size.height - 14, self.frame.size.width-9, 10);
    self.errorIcon.frame     = CGRectMake(self.frame.size.width - 25, -3, 25, 25);
}

#pragma mark - Public -

- (void)updateStatus
{
    BOOL isError = self.attachment.status == AttachmentStatusDownloadFailed || self.attachment.status == AttachmentStatusUploadFailed || self.attachment.status == AttachmentStatusDeclined;
    [self setShowError:isError];
}

#pragma mark * Set

- (void)setShowError:(BOOL)isError {
    self.errorIcon.hidden = !isError;
}

- (void)setShowProgress:(BOOL)inProgress {
    self.progressBar.hidden = !inProgress;
}

- (void)setProgress:(CGFloat)progress {
    [self.progressBar setProgress:progress];
}

- (void)setAttachment:(MessageAttachment *)attachment
{
    _attachment = attachment;
    _attachment.isReceived = self.isLeft;
    UIImage *thumbnail = [attachment thumbnailStyled:NO];
    
    [self updateStatus];
    [self setShowProgress:NO];
    [self setThumbnail:thumbnail];
}

- (void)setThumbnail:(UIImage *)thumbnail
{
    if(thumbnail)
    {
        self.thumbnailView.image = thumbnail;
        self.thumbnailView.backgroundColor = [UIColor clearColor];
    }
    else
    {
        self.thumbnailView.image = nil;
        self.thumbnailView.backgroundColor = [UIColor grayColor];
    }
}

#pragma mark - Private -

- (void)tapAction:(UITapGestureRecognizer *)tapRecognizer
{
    [self.delegate attachmentViewTaped:self];
}

@end

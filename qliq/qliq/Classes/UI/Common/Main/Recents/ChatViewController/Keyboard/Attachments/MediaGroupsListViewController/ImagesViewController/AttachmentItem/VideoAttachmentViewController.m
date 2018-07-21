//
//  VideoView.m
//  test
//
//  Created by Aleksey Garbarev on 24.05.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VideoAttachmentViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import "MediaFileDBService.h"
#import "MessageAttachment.h"
#import "ConversationViewController.h"
#import "MediaFileUploadDBService.h"
#import "UploadDetailView.h"
#import "UIDevice-Hardware.h"

#define kImageNamePlay  @"PlayVideoNormal"
#define kImageNamePause @"PauseVideoNormal"
#define kImageNameStop  @"StopVideoNormal"

#define kImageNamePlayBlack  @"PlayVideoNormalBlack"
#define kImageNamePauseBlack @"PauseVideoNormalBlack"
#define kImageNameStopBlack  @"StopVideoNormalBlack"

#define kImageNamePlayHighlighted   @"PlayVideoHighlighted"
#define kImageNamePauseHighlited    @"PauseVideoHighlited"
#define kImageNameStopHighlighted   @"StopVideoHighlighted"

#define kTopViewControlsViewConstraintiPhoneX  50

#define kValueDefaultDistance 20.f
#define kBlueColor RGBa(0, 120, 174, 1)

@interface VideoAttachmentViewController () <UIGestureRecognizerDelegate>

/**
 IBOutlet
 */
@property (nonatomic, weak) IBOutlet UIButton *backButton;
@property (nonatomic, weak) IBOutlet UIButton *removeButton;
@property (nonatomic, weak) IBOutlet UIButton *shareButton;

@property (nonatomic, weak) IBOutlet UIButton *pauseButton;
@property (nonatomic, weak) IBOutlet UIButton *stopButton;
@property (nonatomic, weak) IBOutlet UIButton *playButton;

@property (nonatomic, weak) IBOutlet UISlider *progressSlider;
@property (nonatomic, weak) IBOutlet UIView *controlsView;
@property (weak, nonatomic) IBOutlet UIView *detailView;
@property (weak, nonatomic) IBOutlet UIButton *uploadAgainButton;

//Constraints
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *detailViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *controlsViewBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *removeButtonXCenterConstraint;

/* Constraints for iPhoneX */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topControlsViewTopConstraint;

/**
 UI
 */
@property (nonatomic, strong) MPMoviePlayerController *mPlayer;
@property (nonatomic, strong) UploadDetailView *uploadDetailView;

/**
 Data
 */
@property (nonatomic, assign) BOOL isSeeking;

@property (nonatomic, strong) NSTimer *progressTimer;
@property (nonatomic, strong) NSString *filePath;

@end

@implementation VideoAttachmentViewController

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
    }
    return self;
}

- (void)dealloc
{
    self.removeButton = nil;
    self.backButton = nil;
    self.shareButton = nil;
    self.pauseButton = nil;
    self.playButton = nil;
    self.stopButton = nil;
    self.progressTimer = nil;
    self.progressSlider = nil;
    self.controlsView = nil;
    self.detailView = nil;
    self.uploadAgainButton = nil;
    self.uploadDetailView = nil;
    self.filePath = nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (nil != self.removeBlock) {
        self.removeBlock();
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    __block __weak typeof(self) weakSelf = self;
    dispatch_async_main(^{
        isIPhoneX {
            weakSelf.topControlsViewTopConstraint.constant = kTopViewControlsViewConstraintiPhoneX;
            [weakSelf.view layoutIfNeeded];
        }
    });
    [self addNotifications];
    [self setAudioSession];
    [self initialization];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self addNotifications];
    [self setAudioSession];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [self removeNotifications];
}

- (void)initialization
{
    //Self
    {
        self.navigationController.navigationBarHidden = YES;
    }
    
    //Buttons
    {
        if (self.shouldShowDeleteButton)
            self.removeButton.hidden = NO;
        else
            self.removeButton.hidden = YES;

        //Share Button
        self.shareButton.hidden = self.upload || self.viewMode == ViewModeForPresentAttachment;
        
        [self cofigureButton:self.shareButton withColor:[UIColor whiteColor] withBackgroundColor:YES];
        [self cofigureButton:self.backButton withColor:[UIColor whiteColor] withBackgroundColor:YES];
        [self cofigureButton:self.removeButton withColor:[UIColor whiteColor] withBackgroundColor:YES];


        //Upload Again button
        self.uploadAgainButton.hidden = ![self.upload isFailed];

        if (!self.uploadAgainButton.hidden) {
            //Configure uploadAgainButton
            [self.uploadAgainButton setTitle:QliqLocalizedString(@"2463-TitleUploadAgain") forState:UIControlStateNormal];
            [self.uploadAgainButton setTitleColor:kBlueColor forState:UIControlStateNormal];
            self.uploadAgainButton.clipsToBounds = YES;
            self.uploadAgainButton.layer.masksToBounds = YES;
            self.uploadAgainButton.layer.cornerRadius = 12.f;
            [[self.uploadAgainButton layer] setBorderWidth:1.5f];
            [[self.uploadAgainButton layer] setBorderColor:kBlueColor.CGColor];

            //Confogure center position remove button
            self.removeButtonXCenterConstraint.constant = self.removeButtonXCenterConstraint.constant - (2*kValueDefaultDistance - self.uploadAgainButton.frame.size.width - self.removeButton.frame.size.width)/4;
        }
        else {
            self.removeButtonXCenterConstraint.constant = 0.f;
        }

        //MPPlayer Buttons
        [self configureBackgroundImageMPPlayerButtons];
    }

    //Progress Slider
    {
        [self.progressSlider setThumbImage:[[UIImage  alloc] init] forState:UIControlStateNormal];
        [self.progressSlider setValue:0.f animated:NO];
        [self.progressSlider addTarget:self action:@selector(progressSliderTouched:) forControlEvents:UIControlEventTouchUpInside];
        [self.progressSlider addTarget:self action:@selector(startSeeking:) forControlEvents:UIControlEventTouchDown];
        self.progressSlider.maximumTrackTintColor =  self.upload ? [UIColor blackColor] : [UIColor whiteColor];
    }
    
    //MPMoviePlayerController
    {
        [self.mPlayer stop];
        self.mPlayer = nil;
        
        self.mPlayer = [[MPMoviePlayerController alloc] init];
        self.mPlayer.view.userInteractionEnabled   = YES;
        self.mPlayer.shouldAutoplay                = NO;
        self.mPlayer.controlStyle                  = MPMovieControlStyleNone;
        self.mPlayer.view.frame                    = self.view.bounds;
        self.mPlayer.view.autoresizingMask         = UIViewAutoresizingFlexibleHeight |
        UIViewAutoresizingFlexibleWidth;
        [self.mPlayer prepareToPlay];
        [self.view addSubview:self.mPlayer.view];
        [self.view sendSubviewToBack:self.mPlayer.view];
    }

    //Navigation View
    {
        self.view.backgroundColor = self.upload ? [UIColor whiteColor] : [UIColor blackColor];
    }
    
    //Gesture Reconizer
    {
        UITapGestureRecognizer *tapPlayerRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapMoviewController:)];
        tapPlayerRecognizer.delegate = self;
        [self.mPlayer.view addGestureRecognizer:tapPlayerRecognizer];
        
        UITapGestureRecognizer *tapViewRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapControlsView:)];
        [self.controlsView addGestureRecognizer:tapViewRecognizer];
    }
    
    //MediaFile
    {
        if ([self isAllowLoadingProgress])
        {
            if (self.mediaFile) {
                self.detailView.hidden = YES;
                self.detailViewHeightConstraint.constant = 0.f;
                [self.mediaFile decryptAsyncCompletitionBlock:^{

                    if ([self checkMediaFile:self.mediaFile])
                        [self setMediaFilePath:self.mediaFile.decryptedPath];
                }];
            }
            else if (self.upload) {
                [self configureUploadDetailView];
                [self attemptToOpen:self.upload.mediaFile];
            }
        }
        else
        {
            if (self.mediaFile) {

                self.detailView.hidden = YES;
                self.detailViewHeightConstraint.constant = 0.f;
                [self.mediaFile decrypt];

                if ([self checkMediaFile:self.mediaFile]) {
                    [self setMediaFilePath:self.mediaFile.decryptedPath];
                }
            }
            else if (self.upload) {
                [self configureUploadDetailView];
                [self attemptToOpen:self.upload.mediaFile];
            }
        }
    }
}

- (void)configureBackgroundImageMPPlayerButtons {

    //Play Button
    [self.playButton setBackgroundImage:[UIImage imageNamed:self.playButton.userInteractionEnabled ? self.upload ? kImageNamePlayBlack : kImageNamePlay : kImageNamePlayHighlighted] forState:UIControlStateNormal];
    //Pause Button
    [self.pauseButton setBackgroundImage:[UIImage imageNamed:self.pauseButton.userInteractionEnabled ? self.upload ? kImageNamePauseBlack : kImageNamePause : kImageNamePauseHighlited] forState:UIControlStateNormal];
    //Stop Button
    [self.stopButton setBackgroundImage:[UIImage imageNamed:self.stopButton.userInteractionEnabled ? self.upload ? kImageNameStopBlack : kImageNameStop : kImageNameStopHighlighted] forState:UIControlStateNormal];
}

#pragma mark - Notifications -

- (void)addNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playbackStatChanged:)
                                                 name:MPMoviePlayerPlaybackStateDidChangeNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playbackDidFinish:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:nil];
}

- (void)removeNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackStateDidChangeNotification object:nil];
}

- (void)playbackStatChanged:(id)sender
{
    [self updateButtons];
    
    MPMoviePlaybackState state = [self.mPlayer playbackState];
    
    switch (state)
    {
        case MPMoviePlaybackStatePlaying: {
            
            NSLog(@"PLAYING");
            [self startTimer];
            
            break;
        }
            
        case MPMoviePlaybackStatePaused: {
            
            NSLog(@"PAUSED");
            [self stopTimer];
            
            break;
        }
            
        case MPMoviePlaybackStateStopped: {
            
            NSLog(@"STOPPED");
            [self stopTimer];
            
            break;
        }
            
        default:
            break;
    }
}

- (void)playbackDidFinish:(id)sender
{
    NSLog(@"%@ did finish", self.mPlayer);
    
    @synchronized(self) {
        [self.mPlayer stop];
        [self.mPlayer prepareToPlay];
    }
    self.progressSlider.value = 0.0f;
}

#pragma mark - Private -

- (void)setAudioSession
{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
}

- (BOOL)isAllowLoadingProgress {
    return YES;
}

- (void)setMediaFilePath:(NSString *)path
{
    self.filePath = path;
    
    NSURL *movieURL = [NSURL fileURLWithPath:path];
    [self.mPlayer setContentURL:movieURL];
}


- (void)stopPlayer {
    
    [self stopTimer];
    
    @synchronized(self) {
        [self.mPlayer pause];
//        [self.mPlayer stop];
        [self.mPlayer prepareToPlay];
    }
    self.progressSlider.value = 0.0f;
    
//    [self updateButtons];
}

/*
 - (void) onApplicationDidEnterBackground
 {
 [self pausePlay];
 
 [self.presentingViewController dismissMoviePlayerViewControllerAnimated];
 
 double delayInSeconds = .35;
 dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
 dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
 
 [playerController.moviePlayer setControlStyle:MPMovieControlStyleNone];
 [playerController.moviePlayer setShouldAutoplay:NO];
 
 playerController.view.frame = self.view.bounds;
 [self.view addSubview:playerController.view];
 
 [self.view sendSubviewToBack:playerController.view];
 });
 }
 */

#pragma mark * UI

- (void)updateButtons
{
    MPMoviePlaybackState state = self.mPlayer.playbackState;
    
    DDLogSupport(@"Player State %ld", (long)state);
    
    BOOL playButtonEnabled  = YES;
    BOOL pauseButtonEnabled = YES;
    BOOL stopButtonEnabled  = YES;
    
    
    switch (state)
    {
        case MPMoviePlaybackStatePlaying: {
            
            playButtonEnabled = NO;
            
            break;
        }
            
        case MPMoviePlaybackStatePaused: {
            
            pauseButtonEnabled = NO;
            
            break;
        }
            
        case MPMoviePlaybackStateStopped: {
            
            stopButtonEnabled = NO;
            
            break;
        }
        default: {
            NSLog(@"Player State %ld", (long)state);
            break;
        }
    }
    
    self.playButton.userInteractionEnabled  = playButtonEnabled;
    self.pauseButton.userInteractionEnabled = pauseButtonEnabled;
    self.stopButton.userInteractionEnabled  = stopButtonEnabled;
    
    [self configureBackgroundImageMPPlayerButtons];
}

- (void)configureUploadDetailView {

    self.detailView.hidden = NO;

    self.uploadDetailView = [[UploadDetailView alloc] init];
    [self.uploadDetailView loadUploadEventsForUploadFile:self.upload];
    //Configure constraints
    self.detailViewHeightConstraint.constant = self.uploadDetailView.frame.size.height;

    self.uploadDetailView.upload = self.upload;
    [self.detailView addSubview:self.uploadDetailView];
    [self.detailView setFrame:self.uploadDetailView.bounds];
    self.detailView.backgroundColor = self.view.backgroundColor;
    [self.view layoutIfNeeded];
}

#pragma mark * Timer

- (void)startTimer
{
    if (!self.progressTimer)
    {
        self.progressTimer = [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(updateProgress:) userInfo:nil repeats:YES];
    }
}

- (void)stopTimer
{
    [self.progressTimer invalidate];
    self.progressTimer = nil;
}

- (void)updateProgress:(NSTimer *)timer
{
    if (!self.isSeeking)
    {
        CGFloat value = self.mPlayer.currentPlaybackTime/self.mPlayer.duration;
        if (value >= 0 && value <= 1)
            self.progressSlider.value = value;
    }
}

#pragma mark - Actions -

#pragma mark * IBAction

- (IBAction)didTapBackButton:(UIButton *)sender
{
    [self stopPlayer];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)didTapRemoveButton:(id)sender
{
    [self stopPlayer];
    [self removeMediaFileAndAttachment];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)didTapShareButton:(id)sender
{
    if (self.mPlayer.playbackState == MPMoviePlaybackStatePlaying) {
        [self stopPlayer];
    }
    
    [self shareFile];
}

- (IBAction)didPatUploadAgainButton:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:ReuploadMediaFileNotification object:self.upload];
    [self didTapBackButton:sender];
}

- (IBAction)play:(UIButton *)sender
{
    @synchronized(self) {
        [self.mPlayer play];
    }
}

- (IBAction)pause:(UIButton *)sender
{
    @synchronized(self) {
        [self.mPlayer pause];
    }
}

- (IBAction)stop:(UIButton *)sender
{
    [self stopPlayer];
}

#pragma mark * ProgressSlider Actions

- (void)progressSliderTouched:(UISlider *)sender
{
    self.isSeeking = NO;
    self.mPlayer.currentPlaybackTime = self.progressSlider.value * self.mPlayer.duration;
}

- (void)startSeeking:(id)sender {
    self.isSeeking = YES;
}

#pragma mark * Gesture Action

- (void)didTapMoviewController:(UITapGestureRecognizer *)sender
{
    self.controlsView.userInteractionEnabled = NO;
    
    [UIView animateWithDuration:0.5f animations:^{
        self.controlsView.alpha = 1.f;
    } completion:^(BOOL finished) {
        self.controlsView.userInteractionEnabled = YES;
    }];
}

- (void)didTapControlsView:(UITapGestureRecognizer *)sender
{
    self.controlsView.userInteractionEnabled = NO;
    
    [UIView animateWithDuration:0.5f animations:^{
        self.controlsView.alpha = 0.f;
    } completion:^(BOOL finished) {
        self.controlsView.userInteractionEnabled = YES;
    }];
}

#pragma mark - Delegates -

#pragma mark - Gesture Delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

@end

//
//  AudioView.m
//  test
//
//  Created by Aleksey Garbarev on 23.05.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AudioAttachmentViewController.h"

#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>

#import "MediaFileDBService.h"
#import "MessageAttachment.h"
#import "ConversationViewController.h"

#import "MediaFileUploadDBService.h"
#import "UploadDetailView.h"

#import "AlertController.h"

#define kToolbarHeight 44.0f
#define kBlueColor RGBa(0.f, 120.f, 174.f, 1.f)

#define kImageNamePlay  @"PlayVideoNormal"
#define kImageNamePause @"PauseVideoNormal"
#define kImageNameStop  @"StopVideoNormal"

#define kImageNamePlayBlack  @"PlayVideoNormalBlack"
#define kImageNamePauseBlack @"PauseVideoNormalBlack"
#define kImageNameStopBlack  @"StopVideoNormalBlack"

#define kImageNamePlayHighlighted   @"PlayVideoHighlighted"
#define kImageNamePauseHighlited    @"PauseVideoHighlited"
#define kImageNameStopHighlighted   @"StopVideoHighlighted"

#define kValueDefaultDistance 20.f

@interface AudioAttachmentViewController() <AVAudioPlayerDelegate>

/**
 IBOutlet
 */
@property (weak, nonatomic) IBOutlet UIButton *removeButton;
@property (weak, nonatomic) IBOutlet UIButton *shareButton;

@property (weak, nonatomic) IBOutlet UIButton *pauseButton;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIButton *stopButton;

@property (weak, nonatomic) IBOutlet UIImageView *imageAudio;

@property (weak, nonatomic) IBOutlet UISlider *progressSlider;

@property (weak, nonatomic) IBOutlet UIView *detailView;
@property (weak, nonatomic) IBOutlet UIButton *uploadAgainButton;
@property (weak, nonatomic) IBOutlet UIButton *backButton;

@property (weak, nonatomic) IBOutlet UIView *navigationView;

/**
 UI
 */
@property (nonatomic, strong) AVAudioPlayer *mPlayer;
@property (nonatomic, strong) UploadDetailView *uploadDetailView;

//Constraints
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *detailViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentViewBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *removeButtonXCenterConstraint;


/**
 Data
 */
@property (nonatomic, assign) BOOL isSeeking;
@property (nonatomic, assign) BOOL isCorruptedFile;

@property (nonatomic, strong) NSTimer *progressTimer;
@property (nonatomic, strong) NSString *filePath;

@end

@implementation AudioAttachmentViewController


- (void)dealloc {
    self.removeButton = nil;
    self.shareButton = nil;
    self.pauseButton = nil;
    self.playButton = nil;
    self.stopButton = nil;
    self.imageAudio = nil;
    self.progressSlider = nil;
    self.detailView = nil;
    self.uploadAgainButton = nil;
    self.backButton = nil;
    self.navigationView = nil;
    self.mPlayer = nil;
    self.uploadDetailView = nil;
    self.progressTimer = nil;
    self.filePath = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.isCorruptedFile = NO;
    [self setAudioSession];
    [self initialization];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setAudioSession];
}

- (void)initialization
{
    //Self
    {
        self.view.backgroundColor = [UIColor darkTextColor];
    }
    
    //Buttons
    {
        if (self.shouldShowDeleteButton)
            self.removeButton.hidden = NO;
        else
            self.removeButton.hidden = YES;

        [self cofigureButton:self.shareButton withColor:[UIColor whiteColor] withBackgroundColor:NO];
        [self cofigureButton:self.backButton withColor:[UIColor whiteColor] withBackgroundColor:NO];
        [self cofigureButton:self.removeButton withColor:[UIColor whiteColor] withBackgroundColor:NO];

        //Upload Again button
        self.uploadAgainButton.hidden = ![self.upload isFailed];
        self.shareButton.hidden = !self.uploadAgainButton.hidden;
        if (!self.shareButton.hidden) {
            self.shareButton.hidden = self.viewMode == ViewModeForPresentAttachment;
        }

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

    //Navigation View
    {
        self.view.backgroundColor = self.upload ? [UIColor whiteColor] : [UIColor blackColor];
        self.navigationView.backgroundColor = self.upload ? [UIColor whiteColor] : [UIColor blackColor];
    }

    //Image Audio View
    {
        [self.imageAudio setImage:[UIImage imageNamed: self.upload ? @"Audio-Playing-3-Black" : @"Audio-Playing-3"]];
    }
    
    //MediaFile
    {
        if ([self isAllowLoadingProgress])
        {
            if (self.mediaFile) {
                [self.mediaFile decryptAsyncCompletitionBlock:^{

                    if ([self checkMediaFile:self.mediaFile])
                        [self setMediaFilePath:self.mediaFile.decryptedPath];
                }];
                self.detailViewHeightConstraint.constant = 0.f;
                self.detailView.hidden = YES;
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

                if ([self checkMediaFile:self.mediaFile])
                    [self setMediaFilePath:self.mediaFile.decryptedPath];
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
    [self.playButton setBackgroundImage:[UIImage imageNamed:self.playButton.userInteractionEnabled ? (self.upload ? kImageNamePlayBlack:kImageNamePlay) : (self.upload ? kImageNamePlayBlack : kImageNamePlayHighlighted)] forState:UIControlStateNormal];
    //Pause Button
    [self.pauseButton setBackgroundImage:[UIImage imageNamed:self.pauseButton.userInteractionEnabled ? (self.upload ? kImageNamePauseBlack : kImageNamePause) : (self.upload ? kImageNamePauseBlack : kImageNamePauseHighlited)] forState:UIControlStateNormal];
    //Stop Button
    [self.stopButton setBackgroundImage:[UIImage imageNamed:self.stopButton.userInteractionEnabled ? (self.upload ? kImageNameStopBlack : kImageNameStop) : (self.upload ? kImageNameStopBlack : kImageNameStopHighlighted)] forState:UIControlStateNormal];
}

#pragma mark - Notifications -

- (void)playbackStatChanged
{
    if (self.mPlayer.isPlaying) {
        [self startTimer];
    }
    else {
        [self stopTimer];
    }
    
    [self updateButtons];
}

- (void)playbackDidFinish:(id)sender
{
    NSLog(@"%@ did finish", self.mPlayer);
    
    @synchronized(self) {
        [self.mPlayer stop];
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

- (void)setMediaFilePath:(NSString *)filePath
{
    self.filePath = filePath;
    
    if (!self.mPlayer)
    {
        if (self.filePath)
            [self playSong:self.filePath];
    }
}

- (void)playSong:(NSString *)path
{
    NSURL *songURL = [NSURL fileURLWithPath:path];
    
    self.progressSlider.value = 0.0f;
    
    @synchronized(self) {
        
        if (self.mPlayer) {
            [self stopPlayer];
        }
        NSError *error = nil;
        self.mPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:songURL error:&error];
        self.mPlayer.delegate = self;
        
        self.isCorruptedFile = error;
        if (!self.shareButton.hidden) {
            self.shareButton.hidden = error;
        }
        self.pauseButton.hidden = error;
        self.stopButton.hidden = error;
        self.playButton.hidden = error;
        self.progressSlider.hidden = error;
        
        if (!error) {
            [self.mPlayer play];
        } else {
            
            [AlertController showAlertWithTitle:QliqLocalizedString(@"1025-TextFileCorrupted")
                                        message:nil
                                    buttonTitle:nil
                              cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                     completion:nil];
        }
        [self playbackStatChanged];
    }
}

#pragma mark * UI

- (void)updateButtons
{
    BOOL playButtonEnabled  = YES;
    BOOL pauseButtonEnabled = YES;
    BOOL stopButtonEnabled  = YES;
    
    if (self.mPlayer.isPlaying) {
        playButtonEnabled = NO;
    }
    else if (self.mPlayer.currentTime > 0) {
        pauseButtonEnabled = NO;
    }
    else {
        stopButtonEnabled = NO;
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
        CGFloat value = self.mPlayer.currentTime/self.mPlayer.duration;
        if (value >= 0 && value <= 1)
            self.progressSlider.value = value;
    }
}

#pragma mark - Actions -

#pragma mark * IBAction

- (IBAction)didTapBackButton:(id)sender
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
    [self stopPlayer];
    [self shareFile];
}

- (IBAction)play:(id)sender
{
    [self.mPlayer play];
    [self playbackStatChanged];
}

- (IBAction)pause:(id)sender
{
    [self.mPlayer pause];
    [self playbackStatChanged];
}

- (IBAction)stop:(id)sender
{
    [self stopPlayer];
}

- (IBAction)didTapUploadAgainButton:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:ReuploadMediaFileNotification object:self.upload];
    [self didTapBackButton:sender];
}


#pragma mark * ProgressSlider Actions

- (void)progressSliderTouched:(UISlider *)sender
{
    self.isSeeking = NO;
    self.mPlayer.currentTime = self.progressSlider.value * self.mPlayer.duration;
}

- (void)startSeeking:(id)sender {
    self.isSeeking = YES;
}

#pragma mark - Delegates -

#pragma mark * AVAudioPlayer

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    [self stopPlayer];
}

- (void)stopPlayer
{
    @synchronized(self) {
        [self.mPlayer stop];
        [self stopTimer];
        self.mPlayer.currentTime = 0;
        self.progressSlider.value = 0.0f;
        [self updateButtons];
    }
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error
{
    DDLogError(@"Decode Error occurred: %@",error);
    [self playbackStatChanged];
}

@end

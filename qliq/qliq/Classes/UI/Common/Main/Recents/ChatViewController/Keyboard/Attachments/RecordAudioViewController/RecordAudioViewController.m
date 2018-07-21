//
//  RecordAudioViewController.m
//  qliq
//
//  Created by Aleksey Garbarev on 22.03.13.
//
//
#import <AVFoundation/AVFoundation.h>

#import "RecordAudioViewController.h"
#import "MediaFile.h"
#import "MediaFileService.h"
#import "MediaFile.h"
#import "UIViewController+Additions.h"
#import "DeviceInfo.h"
#import "ConversationViewController.h"
#import "MessageAttachment.h"
#import "AlertController.h"

typedef NS_ENUM (NSInteger, State) {
    StateNone,
    StateRecording,
    StatePlaying,
    StatePaused,
    StateDone
};

@interface RecordAudioViewController () <AVAudioPlayerDelegate, AVAudioRecorderDelegate>

/**
 IBOutlet
 */
@property (nonatomic, weak) IBOutlet UILabel *durationLabel;
@property (nonatomic, weak) IBOutlet UILabel *statusLabel;

@property (weak, nonatomic) IBOutlet UIButton *shareButton;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;

@property (nonatomic, weak) IBOutlet UIButton *stopButton;
@property (nonatomic, weak) IBOutlet UIButton *recordButton;
@property (nonatomic, weak) IBOutlet UIButton *playButton;

/**
 Data
 */
@property (nonatomic, assign) State currentState;

@property (nonatomic, strong) NSTimer *durationTimer;
@property (nonatomic, assign) NSTimeInterval recordedDuration;

@property (nonatomic, strong) AVAudioRecorder *audioRecorder;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;

@end

@implementation RecordAudioViewController

- (void)configureDefaultText {
    [self.saveButton setTitle:QliqLocalizedString(@"44-ButtonSave") forState:UIControlStateNormal];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureDefaultText];
    
    [self.navigationController setNavigationBarHidden:YES];
    
    //self.saveButton.hidden = self.isShowShareButton;
    //self.shareButton.hidden = !self.isShowShareButton;
    
    self.saveButton.hidden = YES;
    self.shareButton.hidden = NO;
    
    [self initControls];
    [self initRecorder];
    [self refreshView];
    [self setNavigationBarBackgroundImage];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

#pragma mark - Setters -

- (void)setCurrentState:(State)currentState {
    _currentState = currentState;
    [self refreshView];
}

#pragma mark - Private -

- (void) initSession
{
    NSError *sessionError;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&sessionError];
    if (sessionError) {
        DDLogError(@"Session error: %@",sessionError);
    }
}

- (void) initRecorder
{
    [self initSession];
    
    NSString *fileName = [MediaFile generateAudioFilename];
    NSString *directory = kDecryptedDirectory;
    
    NSError *error = nil;
    
    BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:&error];
    if (!success) {
        if (error) {
            DDLogError(@"%@", [error localizedDescription]);
        }
    } else {
        
        NSString *soundFilePath = [directory stringByAppendingPathComponent:fileName];
        
        [[NSFileManager defaultManager] removeItemAtPath:soundFilePath error:NULL];
        
        NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];
        
        NSMutableDictionary *recordSettings = [@{AVEncoderAudioQualityKey   : @(AVAudioQualityMedium)
//                                                 , AVEncoderBitRateKey      : @16
                                                 , AVNumberOfChannelsKey    : @2
                                                 , AVSampleRateKey          : @44100.0
                                                 , AVFormatIDKey            : [NSNumber numberWithInt:kAudioFormatMPEG4AAC]} mutableCopy];
        
        //#if TARGET_OS_IPHONE && !TARGET_IPHONE_SIMULATOR
        //        if ([DeviceInfo sharedInfo].CPUType == CPU_TYPE_ARM64) {
        //            //iOS devices that running on arm64 fails to create AVAudioRecorder with bitrate key-value
        //            [recordSettings removeObjectForKey:AVEncoderBitRateKey];
        //        }
        //#endif
        
        NSError *err = nil;
        
        self.audioRecorder = [[AVAudioRecorder alloc] initWithURL:soundFileURL settings:recordSettings error:&err];
        self.audioRecorder.delegate = self;
        if (err) {
            
            [self showError:err withTitle:NSLocalizedString(@"1183-TextCannotStartRecord", @"About audio record")];
            DDLogError(@"Audio recorder init error: %@", [err localizedDescription]);
        } else {
            [self.audioRecorder prepareToRecord];
        }
    }
}

- (void)initControls
{
    self.playButton.enabled = NO;
    self.stopButton.enabled = NO;
    self.recordedDuration = 0;
}

- (void) refreshView
{
    UIImage *recordImage = [UIImage imageNamed:@"RecordAudioRecStart"];
    UIImage *playImage = [UIImage imageNamed:@"RecordAudioPlayNoActiv"];
    self.statusLabel.textColor = RGBa(102.f,102.f, 102.f, 1.f);
    
    switch (self.currentState)
    {
        case StatePaused: {
            self.statusLabel.text = QliqLocalizedString(@"2130-TitlePaused");
            break;
        }
        case StatePlaying: {
            
            self.statusLabel.text = QliqLocalizedString(@"2131-TitlePlaying");
            self.statusLabel.textColor = RGBa(0.f,102.f, 174.f, 1.f);
            playImage = [UIImage imageNamed:@"RecordAudioRecNoActive"];
            recordImage = [UIImage imageNamed:@"RecordAudioRecGray"];
            
            break;
        }
        case StateRecording: {
            
            self.statusLabel.text = QliqLocalizedString(@"2129-TitleRecording");
            self.statusLabel.textColor = RGBa(0.f,102.f, 174.f, 1.f);
            recordImage = [UIImage imageNamed:@"RecordAudioPause"];
            
            break;
        }
        case StateDone: {
            self.statusLabel.text = QliqLocalizedString(@"2132-TitleReady");
            break;
        }
        case StateNone: {
            self.statusLabel.text = QliqLocalizedString(@"2133-TitleStartRecording");
            break;
        }
    }
    
    //self.shareButton.hidden = self.currentState == StateNone || !self.isShowShareButton;
    //self.saveButton.hidden = self.currentState == StateNone || self.isShowShareButton;
    
    self.shareButton.hidden = self.currentState == StateNone;
    self.stopButton.enabled = (self.currentState == StateRecording || self.currentState == StatePaused);
    self.playButton.enabled = (self.currentState == StateDone || self.currentState == StatePlaying);
    self.recordButton.enabled = (self.currentState == StatePaused || self.currentState == StateDone || self.currentState == StateRecording || self.currentState == StateNone);
    
    [self.recordButton setImage:recordImage forState:UIControlStateNormal];
    [self.playButton setImage:playImage forState:UIControlStateNormal];
    
    [self updateDuration:nil];
}

- (void)showError:(NSError *)error withTitle:(NSString *)title
{
    UIAlertView_Blocks *alert = [[UIAlertView_Blocks alloc] initWithTitle:title
                                                                  message:[error localizedDescription]
                                                                 delegate:nil
                                                        cancelButtonTitle:NSLocalizedString(@"1-ButtonOK", nil)
                                                        otherButtonTitles: nil];
    [alert showWithDissmissBlock:NULL];
}

- (void)updateDuration:(NSTimer *)timer
{
    NSTimeInterval currentTime;
    switch (self.currentState) {
        case StateRecording:
            currentTime = self.audioRecorder.currentTime;
            break;
        case StatePlaying:
            currentTime = self.audioPlayer.currentTime;
            break;
        default:
        case StateDone:
            currentTime = self.recordedDuration;
            break;
    }
    
    NSInteger minutes = (int)currentTime/60;
    NSInteger seconds = currentTime - (minutes * 60);
    self.durationLabel.text = [NSString stringWithFormat:@"%02ld:%02ld",(long)minutes, (long)seconds];
}

#pragma mark - Actions -

- (void)saveRecord
{
    MediaFile *mediaFile = [[MediaFile alloc] init];
    mediaFile.decryptedPath = [[self.audioRecorder url] path];
    mediaFile.fileName = [mediaFile.decryptedPath lastPathComponent];
    mediaFile.mimeType = [MediaFile audioRecordingMime];
    mediaFile.timestamp = [NSDate date].timeIntervalSince1970;
    [mediaFile encrypt];
    self.mediaFile = mediaFile;
    
    [self.delegate recordAudioController:self didRecordedMedaFile:mediaFile];
}

- (void)stopAll
{
    [self.audioPlayer stop];
    [self onStop:nil];
}

- (void)shareFile
{
    [AlertController showAlertWithTitle:nil
                                message:nil
                       withTitleButtons:@[QliqLocalizedString(@"42-ButtonAttachAndSend"), QliqLocalizedString(@"1110-TextUploadToEMR"), QliqLocalizedString(@"1222-TextUploadToKiteworks")]
                      cancelButtonTitle:QliqLocalizedString(@"4-ButtonCancel")
                             completion:^(NSUInteger buttonIndex) {
                                 switch (buttonIndex) {
                                     case 0:
                                         if (!self.mediaFile) {
                                             [self saveRecord];
                                         }
                                         [self createConversationWithAttachment];
                                         break;
                                     case 1:
                                     {
                                         if (!self.mediaFile) {
                                             [self saveRecord];
                                         }
                                         BOOL isEMRIntegrated = [UserSessionService currentUserSession].userSettings.userFeatureInfo.isEMRIntegated;
                                         if (isEMRIntegrated) {
                                             DDLogSupport(@"\n\nEMR Integration is Not Activated\n\n");
                                         } else {
                                             DDLogSupport(@"\n\nEMR Integration Not Activated...\n\n");
                                             
                                             [AlertController showAlertWithTitle:nil
                                                                         message:QliqLocalizedString(@"1111-TextEMRNotActivate")
                                                                     buttonTitle:nil
                                                               cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                                                      completion:nil];
                                         }
                                     }
                                         break;
                                     case 2:
                                     {
                                         if (!self.mediaFile) {
                                             [self saveRecord];
                                         }
                                         BOOL isKiteworksIntegrated = [UserSessionService currentUserSession].userSettings.userFeatureInfo.isKiteworksIntegrated;
                                         if (isKiteworksIntegrated) {
                                             DDLogSupport(@"\n\nKiteworks still not integrated...\n\n");
                                         } else {
                                             [AlertController showAlertWithTitle:nil
                                                                         message:QliqLocalizedString(@"1221-TextKiteworksConnectivityNotActivated")
                                                                     buttonTitle:nil
                                                               cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                                                      completion:nil];
                                         }
                                     }
                                         break;
                                     case 3:
                                         break;
                                         
                                     default:
                                         break;
                                 }
                             }];
}

#pragma mark * IBActions

- (IBAction)onCancel:(id)sender
{
    if (self.currentState != StateNone) {
        
        [self stopAll];
        
        if (!self.mediaFile) {
            [AlertController showAlertWithTitle:QliqLocalizedString(@"1184-TextAskSaveOrDiscard")
                                        message:nil
                                    buttonTitle:QliqLocalizedString(@"44-ButtonSave") cancelButtonTitle:QliqLocalizedString(@"43-ButtonDiscard")
                                     completion:^(NSUInteger buttonIndex) {
                                         if (buttonIndex ==0){
                                             [self saveRecord];
                                             [self.navigationController dismissViewControllerAnimated:YES completion:nil];
                                         } else {
                                             [self.navigationController dismissViewControllerAnimated:YES completion:nil];
                                         }
                                     }];
        } else {
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        }
    } else {
        [self.audioRecorder stop];
        [self.audioPlayer stop];
        
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }
}

- (IBAction)onTrash:(id)sender
{
    [self.durationTimer invalidate];
    [self.audioRecorder stop];
    [self.audioRecorder deleteRecording];
    self.currentState = StateNone;
    
    [self refreshView];
}

- (IBAction)onShare:(id)sender
{
    [self stopAll];
    
    if (self.isShowShareButton) {
        if (self.currentState != StateNone) {
            [self shareFile];
        }
    }
    else {
        [self saveRecord];
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }
}

- (IBAction)onSave:(id)sender {
    [self stopAll];
    [self saveRecord];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}


- (IBAction)onStop:(id)sender
{
    self.currentState = StateDone;
    
    self.recordedDuration = self.audioRecorder.currentTime;
    
    [self.audioRecorder stop];
    
    [self.durationTimer invalidate];
    
    [self refreshView];
}

- (IBAction)onRecordAudio:(id)sender
{
    __block __weak typeof(self) weakSelf = self;
    
    [QliqAccess hasMicrophoneAccess:^(BOOL granted) {
        
        __strong typeof(self) strongSelf = weakSelf;
        
        if (granted) {
            
            if (strongSelf.currentState == StateRecording)
            {
                strongSelf.recordedDuration = strongSelf.audioRecorder.currentTime;
                [strongSelf.durationTimer invalidate];
                
                [strongSelf.audioRecorder pause];
                strongSelf.currentState = StatePaused;
            }
            else
            {
                strongSelf.mediaFile = nil;
                
                /* Remove old recording if not resume */
                if (strongSelf.currentState != StatePaused) {
                    [strongSelf.audioRecorder stop];
                    [strongSelf.audioRecorder deleteRecording];
                }
                
                AVAudioSession *audioSession = [AVAudioSession sharedInstance];
                
                NSError *error;
                
                [audioSession setCategory:AVAudioSessionCategoryRecord error:&error];
                if(error) {
                    DDLogError(@"%@", [error localizedDescription]);
                }
                
                [audioSession setActive:YES error:&error];
                if(error) {
                    DDLogError(@"%@", [error localizedDescription]);
                }
                
                [strongSelf.audioRecorder record];
                
                strongSelf.durationTimer = [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(updateDuration:) userInfo:nil repeats:YES];
                
                strongSelf.currentState = StateRecording;
            }
            
            [strongSelf refreshView];
        }
    }];
}

- (IBAction)onPlayAudio:(id)sender
{
    if (self.currentState == StateDone)
    {
        if (self.audioPlayer) {
            self.audioPlayer = nil;
        }
        
        NSError *error;
        self.audioPlayer = [[AVAudioPlayer alloc]
                            initWithContentsOfURL:self.audioRecorder.url
                            error:&error];
        
        self.audioPlayer.delegate = self;
        if (error) {
            [self showError:error withTitle:NSLocalizedString(@"1185-TextCannotStartPlay", @"About audioPlayer") ];
            DDLogError(@"Audio player init error: %@", [error localizedDescription]);
        } else {
            
            AVAudioSession *audioSession = [AVAudioSession sharedInstance];
            [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
            if ([audioSession respondsToSelector:@selector(isInputGainSettable)] && audioSession.inputGainSettable) {
                [audioSession setInputGain:1.0f error:NULL];
            }
            [audioSession setActive:YES error:nil];
            
            [self.audioPlayer play];
            self.currentState = StatePlaying;
            self.durationTimer = [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(updateDuration:) userInfo:nil repeats:YES];
        }
    }
    else
    { //Playing state
        [self.audioPlayer stop];
        self.currentState = StateDone;
    }
    
    [self refreshView];
}

#pragma mark - Delegates -

#pragma mark * AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    self.currentState = StateDone;
    [self refreshView];
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error
{
    DDLogError(@"Decode Error occurred: %@",error);
    [self showError:error withTitle:NSLocalizedString(@"1186-TextAudioPayerError", nil)];
}

#pragma mark * AVAudioRecorderDelegate

- (void)audioRecorderBeginInterruption:(AVAudioRecorder *)recorder
{
    DDLogInfo(@"audioRecorderBeginInterruption");
}

- (void)audioRecorderEndInterruption:(AVAudioRecorder *)recorder
{
    DDLogInfo(@"audioRecorderEndInterruption");
}

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
    DDLogInfo(@"audioRecorderDidFinishRecording");
}

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error
{
    DDLogError(@"Encode Error occurred: %@",error);
    [self showError:error withTitle:NSLocalizedString(@"1187-TextAudioRecorderError", nil)];
}

@end

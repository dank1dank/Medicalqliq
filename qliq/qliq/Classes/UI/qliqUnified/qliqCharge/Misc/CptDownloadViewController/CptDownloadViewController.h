// Created by Developer Toy
//Page1.h

#import <UIKit/UIKit.h>
#import "AVFoundation/AVFoundation.h"
#import "CptUpdaterDelegate.h"
#import "Physician.h"
#import	"UserHeaderView.h"

@class CptUpdater;

@protocol CptDownloadViewControllerDelegate <NSObject>

-(void) cptDownloadViewControllerDidFinishOperations;

@end

@interface CptDownloadViewController : UIViewController<AVAudioPlayerDelegate,UITextFieldDelegate,CptUpdaterDelegate,UserHeaderViewDelegate>
{
	AVAudioPlayer *DevToyaudioPlayer;
	BOOL firstTimeLaunch;
	
	NSInteger lastCptCheck;
	NSInteger lastCptUpdate;
	NSDictionary *infoPlistDict;
	
	// Updates
	UILabel *lastCheckLabel;
	UILabel *lastUpdateLabel;
	UILabel *progressText;
	UIProgressView *progressView;
	CptUpdater *cptUpdater;
	Physician *physicianObj;
	UserHeaderView *_userView;
    
    UIButton* retryDownloadBtn;
}

@property (nonatomic, assign) BOOL firstTimeLaunch;
@property (nonatomic, assign) NSInteger lastCptCheck;
@property (nonatomic, assign) NSInteger lastCptUpdate;
@property (nonatomic, retain) NSDictionary *infoPlistDict;
@property (nonatomic, retain)  UILabel *lastCheckLabel;
@property (nonatomic, retain)  UILabel *lastUpdateLabel;
@property (nonatomic, retain)  UILabel *progressText;
@property (nonatomic, retain)  UIProgressView *progressView;
@property (nonatomic, retain) CptUpdater *cptUpdater;
@property (nonatomic, retain) Physician *physicianObj;
@property (nonatomic, assign) id<CptDownloadViewControllerDelegate> delegate;

- (void) setStatusMessage:(NSString *)message;
- (void) setProgress:(CGFloat) progress;
- (void) updateLabelsWithDateForLastCheck:(NSDate *)lastCheck lastUpdate:(NSDate *)lastUpdate;

- (void) alertViewWithTitle:(NSString *)title message:(NSString *)message cancelTitle:(NSString *)cancelTitle;
- (void) alertViewWithTitle:(NSString *)title message:(NSString *)message cancelTitle:(NSString *)cancelTitle otherTitle:(NSString *)otherTitle;
- (void) processCptLoad;
-(void) presentLandingPage;

@end
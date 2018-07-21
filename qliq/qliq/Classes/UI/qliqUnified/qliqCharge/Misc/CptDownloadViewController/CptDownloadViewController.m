// Created by Developer Toy
//Page1.m
#import "CptDownloadViewController.h"
#import "AVFoundation/AVFoundation.h"
#import "CptUpdater.h"
#import "Helper.h"
#import "Physician.h"
#import "LightGreyGlassGradientView.h"
#import "DBUtil.h"
#import "FMDatabase.h"
#import "UserSession.h"
#import "UserSessionService.h"
#import "QliqUser.h"
#import "GroupService.h"

@implementation CptDownloadViewController

@synthesize delegate;
@synthesize firstTimeLaunch;
@synthesize lastCptCheck;
@synthesize lastCptUpdate;
@synthesize infoPlistDict;
@synthesize lastCheckLabel;
@synthesize lastUpdateLabel;
@synthesize progressText;
@synthesize progressView;
@synthesize cptUpdater;
@synthesize physicianObj;

- (void)viewDidLoad {
	[self setStatusMessage:nil];
	self.view.backgroundColor=[UIColor colorWithRed:1.0/255.0 green:65.0/255.0 blue:111.0/255.0 alpha:1.0];
	
	_userView = [[[UserHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320, 60)] autorelease];
	[self.view addSubview:_userView];

    QliqUser *user = [UserSessionService currentUserSession].user;
    GroupService *gs = [[GroupService alloc] init];
    Group *group = nil;
    NSArray *userGroups = [gs getGroupsOfUser:user];
    if([userGroups count])
    {
        group = [userGroups objectAtIndex:0];
    }
    [_userView fillWithContact:user andGroup:group];
    [gs release];
    
    LightGreyGlassGradientView *bgView = [[LightGreyGlassGradientView alloc] initWithFrame:CGRectMake(0.0, 416-60, 320.0, 60.0)];
    [self.view addSubview:bgView];
    [bgView release];
    
    retryDownloadBtn = [[[UIButton alloc] initWithFrame:CGRectMake(80, 416-50, 160.0, 40.0)] autorelease];
    [retryDownloadBtn setBackgroundImage:[UIImage imageNamed:@"try_again_btn.png"] forState:UIControlStateNormal];
    retryDownloadBtn.enabled = NO;
    [retryDownloadBtn addTarget:self action:@selector(retryDownload:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:retryDownloadBtn];
    
    UILabel * messageDownloadingLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0.0, 110.0, 320.0, 100.0)] autorelease];
    messageDownloadingLabel.font = [UIFont boldSystemFontOfSize:18.0];
    messageDownloadingLabel.textColor = [UIColor whiteColor];
    messageDownloadingLabel.textAlignment = UITextAlignmentCenter;
    messageDownloadingLabel.numberOfLines = 3;
    messageDownloadingLabel.text = @"Downloading the current\nAmerican Medical Association\nCPT® code set";
    messageDownloadingLabel.backgroundColor = [UIColor clearColor];
    [self.view addSubview:messageDownloadingLabel];
    
	/*lastCheckLabel=[[UILabel alloc] initWithFrame:CGRectMake(33,23,151,57)];
	lastCheckLabel.text=@"Last Cpt Check";
	lastCheckLabel.font=[UIFont fontWithName:[[UIFont familyNames] objectAtIndex:27] size:17];
	lastCheckLabel.adjustsFontSizeToFitWidth=YES;
	lastCheckLabel.numberOfLines=0;
	lastCheckLabel.tag=0;
	lastCheckLabel.backgroundColor=[UIColor clearColor];
	[self.view addSubview:lastCheckLabel];
	[lastCheckLabel release];*/
	
	/*lastUpdateLabel=[[UILabel alloc] initWithFrame:CGRectMake(33,66,135,58)];
	lastUpdateLabel.text=@"Last Cpt Update";
	lastUpdateLabel.font=[UIFont fontWithName:[[UIFont familyNames] objectAtIndex:27] size:17];
	lastUpdateLabel.adjustsFontSizeToFitWidth=YES;
	lastUpdateLabel.numberOfLines=0;
	lastUpdateLabel.tag=0;
	lastUpdateLabel.backgroundColor=[UIColor clearColor];
	[self.view addSubview:lastUpdateLabel];
	[lastUpdateLabel release];*/
	
	
	UILabel *cptCheckTimeLabel=[[UILabel alloc] initWithFrame:CGRectMake(181,23,134,56)];
	cptCheckTimeLabel.text=@"";
	cptCheckTimeLabel.font=[UIFont fontWithName:[[UIFont familyNames] objectAtIndex:27] size:17];
	cptCheckTimeLabel.adjustsFontSizeToFitWidth=YES;
	cptCheckTimeLabel.numberOfLines=0;
	cptCheckTimeLabel.tag=0;
	cptCheckTimeLabel.backgroundColor=[UIColor clearColor];
	//[self.view addSubview:cptCheckTimeLabel];
	[cptCheckTimeLabel release];
	
	
	UILabel *cptUpdateTimeLabel=[[UILabel alloc] initWithFrame:CGRectMake(171,66,144,54)];
	cptUpdateTimeLabel.text=@"";
	cptUpdateTimeLabel.font=[UIFont fontWithName:[[UIFont familyNames] objectAtIndex:27] size:17];
	cptUpdateTimeLabel.adjustsFontSizeToFitWidth=YES;
	cptUpdateTimeLabel.numberOfLines=0;
	cptUpdateTimeLabel.tag=0;
	cptUpdateTimeLabel.backgroundColor=[UIColor clearColor];
	//[self.view addSubview:cptUpdateTimeLabel];
	[cptUpdateTimeLabel release];

	progressView=[[UIProgressView alloc] initWithFrame:CGRectMake(45,259,233,11)];
	progressView.progressViewStyle=1;
	progressView.progress=0.100000;
	progressView.tag=0;
	progressView.backgroundColor=[UIColor clearColor];
	[self.view addSubview:progressView];
	[progressView release];
	
	progressText=[[[UILabel alloc] initWithFrame:CGRectMake(0,190,320,50)] autorelease];
    progressText.numberOfLines = 2;
	progressText.text=@"This step is required\nand may take a several minutes";
	progressText.font=[UIFont systemFontOfSize:14.0];
    progressText.textColor = [UIColor whiteColor];
    progressText.textAlignment = UITextAlignmentCenter;
	progressText.backgroundColor=[UIColor clearColor];
    
	[self.view addSubview:progressText];
	
}

- (void)viewWillAppear:(BOOL)animated{
	self.navigationController.navigationBarHidden=NO;
	self.navigationController.navigationBar.translucent=NO;
	self.title=@"CPT Updater";
	self.navigationItem.hidesBackButton=YES;
}

- (void) viewDidAppear:(BOOL)animated
{
	if (firstTimeLaunch) {
		//NSString *title = @"First Launch";
		//NSString *message = @"Welcome to qliq!\nBefore using qliqCharge, the cpts must be dowmloaded and update cpt table.";
		
		//[self alertViewWithTitle:title message:message cancelTitle:@"OK"];		// maybe allow postponing first import?
		[self processCptLoad];
	}
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
	[textField resignFirstResponder];
	return YES;
}

- (void)viewDidUnload {
}
- (void)dealloc {
	self.infoPlistDict = nil;
	self.lastCheckLabel = nil;
	self.lastUpdateLabel = nil;
	self.progressText = nil;
	self.progressView = nil;
	
	[super dealloc];
	[DevToyaudioPlayer release];
	
}

- (void) setStatusMessage:(NSString *)message
{
	if (message) {
	//	progressText.textColor = [UIColor blackColor];
		progressText.text = message;
	}
	else {
	//	progressText.textColor = [UIColor grayColor];
		progressText.text = @"Ready";
	}
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
}

- (void) setProgress:(CGFloat)progress
{
	if (progress >= 0.0) {
		progressView.hidden = NO;
		progressView.progress = progress;
	}
	else {
		progressView.hidden = YES;
	}
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
}

#pragma mark Updater Delegate
- (void) updaterDidStartAction:(CptUpdater *)updater
{
//	[updater retain];
	[self setStatusMessage:updater.statusMessage];
//	[updater release];
    
    DDLogInfo(@"progress text %@", progressText.text);
}
- (void) updater:(CptUpdater *)updater didEndActionSuccessful:(BOOL)success
{
	//[updater retain];
	
	if (success) {
		// did check for updates
		if (1 == updater.updateAction) {
		}
		
		// did update cpts
		else {
			NSString *statusMessage;
			
			if (updater.numCptsParsed > 0) {
				statusMessage = [NSString stringWithFormat:@"Created %u cpts", updater.numCptsParsed];
				[self performSelectorOnMainThread:@selector(setStatusMessage:) withObject:statusMessage waitUntilDone:NO];
				// save state
				NSTimeInterval nowInEpoch = [[NSDate date] timeIntervalSince1970];
				
				NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
				[defaults setObject:[NSNumber numberWithInt:(NSInteger)nowInEpoch] forKey:@"lastCptUpdate"];
				[defaults synchronize];
				[self setProgress:1.0];
				
				FMDatabase *db = [DBUtil sharedDBConnection];
				[db executeUpdate:@"INSERT INTO cpt (code, short_description, long_description) VALUES (?,?,?)", 
				 @"VIEW",
				 @"View All Cpt Codes",
				 @"Select this option to load the cpt codes in a list, then these codes can be searched and add to favorites"];
				
				//[updater release];
				[self performSelector:@selector(presentLandingPage) withObject:nil afterDelay:2.0];
			}
			else {
				statusMessage = @"No cpts were created";
			}
 		}
	}
	// an error occurred
	else {
        retryDownloadBtn.enabled = YES;
//		if (updater.downloadFailed && updater.statusMessage) {
//			[self alertViewWithTitle:@"Download Failed" message:updater.statusMessage cancelTitle:@"OK"];
//		}
		[self performSelectorOnMainThread:@selector(setStatusMessage:) withObject:updater.statusMessage waitUntilDone:NO];
	}
   
}

- (void) updater:(CptUpdater *)updater progress:(CGFloat)progress
{
	[self setProgress:progress];
}

-(void)retryDownload:(id)sender
{
    [self performSelectorOnMainThread:@selector(processCptLoad) withObject:nil waitUntilDone:NO];
}

#pragma mark -

#pragma mark Alert View + Delegate
// alert with one button
- (void) alertViewWithTitle:(NSString *)title message:(NSString *)message cancelTitle:(NSString *)cancelTitle
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:cancelTitle otherButtonTitles:nil];
	[alert show];
	[alert release];
}

// alert with 2 buttons
- (void) alertViewWithTitle:(NSString *)title message:(NSString *)message cancelTitle:(NSString *)cancelTitle otherTitle:(NSString *)otherTitle
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:cancelTitle otherButtonTitles:otherTitle, nil];
	[alert show];
	[alert release];
}

- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger) buttonIndex
{
	// first import alert (can only be accepted at the moment)
	if (firstTimeLaunch) {
		//AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
		[self processCptLoad];
	}
}

#pragma mark Process CPT Load
- (void) processCptLoad{
    retryDownloadBtn.enabled = NO;
    [self setProgress:0.2];
	if(!cptUpdater){
		
		self.cptUpdater = [[[CptUpdater alloc] initWithDelegate:self] autorelease];
		cptUpdater.updateAction = 2;
	}
	[cptUpdater startUpdaterAction];
	// **** Data
	// connect to the database and load the cpt
	//BOOL databaseCreated = [cptUpdater connectToDBAndCreateIfNeeded];
}
-(void) presentLandingPage
{
    [self.delegate cptDownloadViewControllerDidFinishOperations];
	/*PatientListView *tempController=[[PatientListView alloc] init];
	[tempController setPhysicianObj:self.physicianObj];
	[self.navigationController pushViewController:tempController animated:YES];
	[tempController release];*/
	//AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	//[appDelegate UserLoggedInWithUsername:username];
}

@end

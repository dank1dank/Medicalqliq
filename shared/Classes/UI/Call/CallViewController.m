//
//  CallViewController.m
//  qliq
//
//  Created by Paul Bar on 1/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CallViewController.h"
#import "QliqSip.h"
#import "DeclineMessage.h"
#import "QliqConnectModule.h"
//#import "ComingSoonViewController.h"
#import <AudioToolbox/AudioToolbox.h>

#import "Call.h"
#import <AVFoundation/AVFoundation.h>

@interface CallViewController()

@property(nonatomic, retain) Call *activeCall;

-(void) declineCallWithMessage:(NSString*)messageText;
- (void)setSpeakerPhoneEnabled:(BOOL)enable;
- (void)setMute:(BOOL)enable;


//Buttons actions
- (void) muteButtonPressed:(BOOL) enable;
- (void) contactsButtonPressed;
- (void) addCallButtonPressed;
- (void) videoCallButtonPressed;
- (void) speakerButtobPressed:(BOOL) enable;

@end

@implementation CallViewController
@synthesize callInProgress;
@synthesize activeCall;
@synthesize delegate;


- (NSArray *) bulidToolbarActions{
    
    __block QliqBarButtonItem * muteButton = [[QliqBarButtonItem alloc] initWithButtonImage:[UIImage imageNamed:@"TabBarItemAdd"] actionBlock:^(QliqBarButtonItem *item) {
        muteButton.selected = !muteButton.selected;
        [self muteButtonPressed:muteButton.selected];
    }];
    QliqBarButtonItem * contactButton = [[QliqBarButtonItem alloc] initWithButtonImage:[UIImage imageNamed:@"tabBarButton_contacts.png"] targetIdentifier:QliqBarButtonIdContacts actionBlock:^(QliqBarButtonItem *item) {
        [self contactsButtonPressed];
    }];
    QliqBarButtonItem * addCallButton = [[QliqBarButtonItem alloc] initWithButtonImage:[UIImage imageNamed:@"TabBarItemAdd"] actionBlock:^(QliqBarButtonItem *item) {
        [self addCallButtonPressed];
    }];
    QliqBarButtonItem * videocallButton = [[QliqBarButtonItem alloc] initWithButtonImage:[UIImage imageNamed:@"TabBarItemAdd"] actionBlock:^(QliqBarButtonItem *item) {
        [self videoCallButtonPressed];
    }];
    __block QliqBarButtonItem * speakerButton = [[QliqBarButtonItem alloc] initWithButtonImage:[UIImage imageNamed:@"TabBarItemAdd"] actionBlock:^(QliqBarButtonItem *item) {
        speakerButton.selected = !speakerButton.selected;
        [self speakerButtobPressed:speakerButton.selected];
    }];
    
    return [NSArray arrayWithObjects:muteButton, contactButton, addCallButton, videocallButton,speakerButton, nil];
}




- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
        navBarChattingWithView = [[NavigationBarChattingWithView alloc] init];
        declineMessagesController = [[DeclineMessagesController alloc] init];
        declineMessagesController.delegate = self;
        forwardListController = [[ForwardListController alloc] init];
        self.previousControllerTitle = @"Back";
        
        self.shouldHidesToolbar = NO;
        self.tabbarItems = [self bulidToolbarActions];
    }
    return self;
}

-(void) dealloc
{
    [declineMessagesController release];
    [forwardListController release];
    [navBarChattingWithView release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle


// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    callView = [[CallView alloc] init];
    callView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    callView.autoresizesSubviews = YES;
    callView.delegate = self;
    self.view = callView;
}

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}
*/
-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:navBarChattingWithView] autorelease];
    navBarChattingWithView.frame = CGRectMake(navBarChattingWithView.frame.origin.x, 
                                              navBarChattingWithView.frame.origin.y,
                                              [UIScreen mainScreen].bounds.size.width / 2.0,
                                              self.navigationController.navigationBar.frame.size.height);

    //self.navigationItem.leftBarButtonItem = [self leftLogoItem];
    [(CallView*)self.view hideTable];
}

-(void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.delegate callViewControllerWillEnteredBackground:self];
}

-(void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    self.previousControllerTitle = @"Back";
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

AUTOROTATE_METHOD

-(void) initiatingCall:(Call *)call
{
//	[(CallView*)self.view resetTabBtns];
    [(CallView*)self.view presentState:CallViewStateCalling];
    navBarChattingWithView.recipientName = @"Calling";
    navBarChattingWithView.regardingText = [call.contact nameDescription];
    [callView updateRecipientName:call.contact];
    
    self.activeCall = call;
}

-(void) callStarted
{
    [(CallView*)self.view presentState:CallViewStateCallInProgress];
    navBarChattingWithView.recipientName = @"Call in progress";
}

-(void) incomingCall:(Call *)call
{
    [(CallView*)self.view presentState:CallViewStateIncomingCall];
//	[(CallView*)self.view resetTabBtns];
    navBarChattingWithView.recipientName = @"Incoming call";
    navBarChattingWithView.regardingText = [call.contact nameDescription];
    [callView updateRecipientName:call.contact];
    
    self.activeCall = call;
}

-(void) callFailedWithReason:(NSString *)reason
{
    [(CallView*)self.view presentState:CallViewStateCallFailed];
    navBarChattingWithView.recipientName = reason;
    [self setCustomBackItemWithTitle:NSLocalizedString(@"1902-TextClose", nil)];
}

-(void) answerCall
{
    [self answerButtonPressed];
}

- (void)presentSettings:(id)sender
{
    
}


#pragma mark -
#pragma mark CallViewDelegate

-(void) answerButtonPressed
{
    DDLogSupport(@"answer Button Pressed");
    [((CallView*)self.view) hideTable];
    [[[QliqSip instance] voiceCallsController] answerCall:self.activeCall];
}

-(void) declineButtonPressed
{
    DDLogSupport(@"decline Call  Button Pressed");
    [((CallView*)self.view) hideTable];    
    [[[QliqSip instance] voiceCallsController] declineCall:self.activeCall];
    self.callInProgress = NO;
    [self.navigationController popViewControllerAnimated:YES];
}

-(void) declineWithMessageButtonPressed
{
    DDLogSupport(@"decline Call with Button Pressed");
    declineMessagesController.tableView = callView.table;
    [declineMessagesController refreshData];
    callView.table.delegate = declineMessagesController;
    callView.table.dataSource = declineMessagesController;
    [callView.table reloadData];
    [callView showTable];
}

-(void) forwardButtonPressed
{
    [forwardListController refreshData];
    callView.table.delegate = forwardListController;
    callView.table.dataSource = forwardListController;
    [callView.table reloadData];
    [callView showTable];
}

-(void) endCallButtonPressed
{
    DDLogSupport(@"endCall Button Pressed");
//	[self setMute:NO];
	[self setSpeakerPhoneEnabled:NO];
    [[[QliqSip instance] voiceCallsController] endCall:self.activeCall];
}

-(void) tryAgainButtonPressed
{
    DDLogSupport(@"tryAgain Button Pressed");
    
    [[[QliqSip instance] voiceCallsController] callUser:self.activeCall.contact];
}

-(void) showComingSoonWithFeatureName:(NSString*)featureName
{
    /*
    ComingSoonViewController *csvc = [ComingSoonViewController comingSoonControllerForFeatureWithName:featureName];
    [self.navigationController pushViewController:csvc animated:YES];
     */
}

-(void) muteButtonPressed:(BOOL) enable
{
    DDLogSupport(@"mute Button Pressed");
	[self setMute:enable];
}

-(void) contactsButtonPressed
{
    /*
    QliqNavigationController * navController = (QliqNavigationController *) self.navigationController;
    [navController switchToViewControllerByClass:[ContactsGroupsListViewController class] animated:YES];
    */
    //[self.delegate presentContacts];

}

-(void) addCallButtonPressed
{
    [self showComingSoonWithFeatureName:@"Add call"];
}

-(void) videoCallButtonPressed
{
    [self showComingSoonWithFeatureName:@"Video call"];
}

-(void) speakerButtobPressed:(BOOL) enable
{
    DDLogSupport(@"speaker Button Pressed");
	[self setSpeakerPhoneEnabled:enable];
}


#pragma mark -
#pragma mark DeclineMessagesViewControllerDelegate

-(void) declineMessageSelected:(DeclineMessage *)declineMessage
{
    [self declineCallWithMessage:declineMessage.messageText];
}

#pragma mark -
#pragma mark Private

-(void) declineCallWithMessage:(NSString *)messageText
{
    [[QliqConnectModule sharedQliqConnectModule] sendMessage:messageText toUser:activeCall.contact subject:@"Call declined" ackRequired:NO priority:ChatMessagePriorityNormal type:ChatMessageTypeNormal];
    [self declineButtonPressed];
}

- (void)setSpeakerPhoneEnabled:(BOOL)enable
{
    
	UInt32 route;
	route = enable ? kAudioSessionOverrideAudioRoute_Speaker : 
	kAudioSessionOverrideAudioRoute_None;
	AudioSessionSetProperty (kAudioSessionProperty_OverrideAudioRoute, 
							 sizeof(route), &route);
    
     
    
    /*
    //get your app's audioSession singleton object
    AVAudioSession* session = [AVAudioSession sharedInstance];
    
    //error handling
    BOOL success;
    NSError* error;
    
    //set the audioSession category.
    //Needs to be Record or PlayAndRecord to use audioRouteOverride:
    
    success = [session setCategory: AVAudioSessionCategoryPlayAndRecord
                             error:&error];
    
    if (!success)  NSLog(@"AVAudioSession error setting category:%@",error);
    
    //set the audioSession override
    success = [session overrideOutputAudioPort:enable ? kAudioSessionOverrideAudioRoute_Speaker : kAudioSessionOverrideAudioRoute_None
                                         error:&error];
    if (!success)  NSLog(@"AVAudioSession error overrideOutputAudioPort:%@",error);
    
    //activate the audio session
    success = [session setActive:YES error:&error];
    if (!success) NSLog(@"AVAudioSession error activating: %@",error);
    else NSLog(@"audioSession active");
     8
     */
}

- (void)setMute:(BOOL)enable
{
	/* FIXME maybe I must look for conf_port */
	if (enable)
    {
        DDLogSupport(@"muting call_id: %d", self.activeCall.call_id);
		[[QliqSip instance] muteMicForCallWithId:self.activeCall.call_id];
    }
	else
    {
        DDLogSupport(@"Unmuting on call_id: %d", self.activeCall.call_id);
		[[QliqSip instance] unMuteMicForCallWithId:self.activeCall.call_id];
    }
}

@end

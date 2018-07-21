//
//  SettingsRingtoneViewController.h
//  qliq
//
//  Created by Valeriy Lider on 25.11.14.
//
//

#import <UIKit/UIKit.h>
#import "NotificationsSettings.h"
#import "Ringtone.h"

@interface SettingsRingtoneViewController : UIViewController

@property (nonatomic, strong) Ringtone *currentRingtone;
@property (nonatomic, strong) NotificationsSettings * notificationSettings;
@property (nonatomic, assign) BOOL *forCareChannel;
@property (nonatomic, assign) NSInteger *typeSound;
@property (nonatomic, assign) BOOL *otherSounds;

@end

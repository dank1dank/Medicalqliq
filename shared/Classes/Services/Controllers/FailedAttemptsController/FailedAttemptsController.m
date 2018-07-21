//
//  FailedAttempsController.m
//  qliq
//
//  Created by Aleksey Garbarev on 10/1/12.
//
//

#import "FailedAttemptsController.h"
#import "SetDeviceStatus.h"

#define kFailedAttempsKeyAttempts       @"login_failed_attempts"
#define kFailedAttempsKeyLockInterval   @"login_failed_lock_timeinterval"
#define kFailedAttempsKeyMaxAttempts    @"login_failed_max_attemps"
#define kFailedAttempsKeyUnlockDate     @"login_failed_unlockdate"

@interface FailedAttemptsController ()

@property (nonatomic, assign) BOOL isAddToPerformUnlockBlock;

@end

@implementation FailedAttemptsController
{
    NSTimer * countdownTimer;
    
    void(^lockBlock)(BOOL isLocked);
    void(^contdownBlock)(NSTimeInterval invervalToUnlock);
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.isAddToPerformUnlockBlock = NO;
    }
    return self;
}

- (void) setupDefaultsToFailedAttempts{
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:kFailedAttempsKeyAttempts];
    [[NSUserDefaults standardUserDefaults] setDouble:300 forKey:kFailedAttempsKeyLockInterval];
    [[NSUserDefaults standardUserDefaults] setInteger:5 forKey:kFailedAttempsKeyMaxAttempts];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL) isDefaultValuesEmpty{
    return [[NSUserDefaults standardUserDefaults] integerForKey:kFailedAttempsKeyMaxAttempts] == 0;
}

- (NSUInteger) maxAttempts{
    return [[NSUserDefaults standardUserDefaults] integerForKey:kFailedAttempsKeyMaxAttempts];
}

- (NSTimeInterval)lockInterval {
    return [[NSUserDefaults standardUserDefaults] doubleForKey:kFailedAttempsKeyLockInterval];
}

- (void) lock{
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:0 forKey:kFailedAttempsKeyAttempts];
    NSTimeInterval lockTime = [userDefaults doubleForKey:kFailedAttempsKeyLockInterval];
    [userDefaults setObject:[NSDate dateWithTimeInterval:lockTime sinceDate:[NSDate date]] forKey:kFailedAttempsKeyUnlockDate];
    [userDefaults synchronize];
    
    [[SetDeviceStatus sharedService] setDeviceStatusLock:@"locked" wipeState:@"none" onCompletion:nil];
    
    //Call callback
        if (lockBlock){
            if (!self.isAddToPerformUnlockBlock) {
               [self performSelector:@selector(unlock) withObject:nil afterDelay:[self timeIntervalToUnlock]];
                self.isAddToPerformUnlockBlock = YES;
            }
       }
}

- (void) unlock{
    [SVProgressHUD showWithStatus:QliqLocalizedString(@"1945-StatusUnlocking") maskType:SVProgressHUDMaskTypeBlack];
    [self clear];
    // First set the device as Unlocked
    // Then call get device status
    // Then call login block
    __weak __block typeof(self) weakSelf = self;
    [[SetDeviceStatus sharedService] setDeviceStatusLock:@"unlocked" wipeState:@"none" onCompletion:^(BOOL success, NSError *error){
        [appDelegate.currentDeviceStatusController refreshRemoteStatusWithCompletition:^(CompletitionStatus status, id result, NSError *error) {
            if (lockBlock) {
                lockBlock(NO);
            }
            weakSelf.isAddToPerformUnlockBlock = NO;
            [SVProgressHUD dismiss];
        }];
    }];
}

- (void) unlockWithCompletion:(void(^)(void))block {
    if (!self.isAddToPerformUnlockBlock) {
        if (![self isLocked]) {
            self.isAddToPerformUnlockBlock = YES;
            if (block && !lockBlock) {
                [self setDidLockBlock:^(BOOL isLocked) {
                    block();
                }];
            }
            [self unlock];
        }
    }
    else if (countdownTimer == nil){
        [self unlock];
    }
}

- (void) increment{
    
    if ([self isDefaultValuesEmpty]){
        [self setupDefaultsToFailedAttempts];
    }
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSUInteger failedAttempts = [userDefaults integerForKey:kFailedAttempsKeyAttempts];
    
    failedAttempts++;
    
    [userDefaults setInteger:failedAttempts forKey:kFailedAttempsKeyAttempts];
    [userDefaults synchronize];
}

- (NSInteger)countFailedAttempts {
    return [[NSUserDefaults standardUserDefaults] integerForKey:kFailedAttempsKeyAttempts];
}

- (BOOL) shouldLock
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSUInteger failedAttempts = [userDefaults integerForKey:kFailedAttempsKeyAttempts];
    NSUInteger maxFailedAttempts = [userDefaults integerForKey:kFailedAttempsKeyMaxAttempts];
    return (failedAttempts >= maxFailedAttempts);
    
}

- (void) clear{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:0 forKey:kFailedAttempsKeyAttempts];
    [userDefaults setObject:[NSDate date] forKey:kFailedAttempsKeyUnlockDate];
    [userDefaults synchronize];
}

- (NSDate *) unlockTime{
    return [[NSUserDefaults standardUserDefaults] objectForKey:kFailedAttempsKeyUnlockDate];
}

- (NSTimeInterval) timeIntervalToUnlock{
    return [[self unlockTime] timeIntervalSinceNow];
}

- (BOOL) isLocked{
    return [[self unlockTime] compare:[NSDate date]] == NSOrderedDescending;
}

#pragma mark - Callbacks

- (void) setDidLockBlock:(void(^)(BOOL isLocked)) _lockBlock{
    lockBlock = [_lockBlock copy];
    
    if ([self isLocked]){
        if (!self.isAddToPerformUnlockBlock) {
            [self performSelector:@selector(unlock) withObject:nil afterDelay:[self timeIntervalToUnlock]];
            self.isAddToPerformUnlockBlock = YES;
        }
    }
}

- (void) countdownTick:(NSTimer *) timer{
    
    NSTimeInterval timeInterval = [self timeIntervalToUnlock];
    if (timeInterval > -1){
        if (contdownBlock) contdownBlock(timeInterval);
    }else{
        [countdownTimer invalidate];
        countdownTimer = nil;
        if (contdownBlock) contdownBlock(timeInterval);
    }
}

- (void) setCountdownBlock:(void(^)(NSTimeInterval invervalToUnlock)) _countdownBlock{
    contdownBlock = [_countdownBlock copy];
    
    if (!countdownTimer){
        countdownTimer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(countdownTick:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:countdownTimer forMode:NSDefaultRunLoopMode];
        [countdownTimer fire];
    }
}

#pragma mark -

- (void)dealloc {
    [countdownTimer invalidate];
    countdownTimer = nil;
}

@end

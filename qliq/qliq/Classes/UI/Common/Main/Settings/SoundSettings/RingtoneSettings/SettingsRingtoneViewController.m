//
//  SettingsRingtoneViewController.m
//  qliq
//
//  Created by Valeriy Lider on 25.11.14.
//
//

#import "SettingsRingtoneViewController.h"
#import "SettingsRingtoneTableViewCell.h"

typedef NS_ENUM(NSInteger, IncomingMessages) {
    IncomingMessagesNormal,
    IncomingMessagesUrgent,
    IncomingMessagesAsap,
    IncomingMessagesFyi,
    IncomingMessagesCount
};

@interface SettingsRingtoneViewController () <UIPickerViewDataSource, UIPickerViewDelegate>

@property (weak, nonatomic) IBOutlet UIButton *navigationLeftButton;

@property (weak, nonatomic) IBOutlet UITextField *pickerTextField;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) UIPickerView *pickerView;
@property (strong, nonatomic) NSDictionary *reminderDictionary;
@property (strong, nonatomic) NSArray *reminderDictionaryKeys;
@property (assign, nonatomic) BOOL reminderCountPicking;

@end

@implementation SettingsRingtoneViewController

- (void)configureDefaultText {
    
    IncomingMessages currentIncomingMessages = self.typeSound;

    switch (currentIncomingMessages) {
            
        case IncomingMessagesNormal: {
            
            [self.navigationLeftButton
             setTitle:QliqFormatLocalizedString1(@"2029-TitleSetSound{type}", self.forCareChannel ? QliqLocalizedString(@"237666-TitleNormalCareChannel") : self.otherSounds ? @"Sent" : QliqLocalizedString(@"23766-TitleNormal"))
             forState:UIControlStateNormal];

            break;
        }
        case IncomingMessagesUrgent: {
            
            [self.navigationLeftButton
             setTitle:QliqFormatLocalizedString1(@"2029-TitleSetSound{type}", self.forCareChannel ? QliqLocalizedString(@"23799-TitleUrgentCareChannel") : self.otherSounds ? @"Acknowledged" : QliqLocalizedString(@"2379-TitleUrgent"))
             forState:UIControlStateNormal];

            break;
        }
        case IncomingMessagesAsap: {
            
            [self.navigationLeftButton
             setTitle:QliqFormatLocalizedString1(@"2029-TitleSetSound{type}", self.forCareChannel ? QliqLocalizedString(@"23788-TitleASAPCareChannel") : QliqLocalizedString(@"2378-TitleASAP"))
             forState:UIControlStateNormal];

            break;
        }
        case IncomingMessagesFyi: {
            
            [self.navigationLeftButton
             setTitle:QliqFormatLocalizedString1(@"2029-TitleSetSound{type}", self.forCareChannel ? QliqLocalizedString(@"23777-TitleFYICareChannel") : QliqLocalizedString(@"2377-TitleFYI"))
             forState:UIControlStateNormal];

            break;
        }
        default:
            break;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.reminderDictionary = @{
                                @0 : @"Do not Remind",
                                @1 : @"1 min",
                                @3 : @"3 min",
                                @5 : @"5 min",
                                @10 : @"10 min",
                                @15 : @"15 min",
                                @30 : @"30 min",
                                @45 : @"45 min",
                                @60 : @"1 hr",
                                @120 : @"2 hrs"};
    
    /* keep keys order */
    self.reminderDictionaryKeys = [[self.reminderDictionary allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 compare:obj2];
    }];
    
    self.pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 0, 320, 140)];
    self.pickerView.delegate = self;
    self.pickerView.dataSource = self;
    [self.pickerView setShowsSelectionIndicator:YES];
    NSInteger row = [self rowForChimeCount:self.notificationSettings.reminderChimeInterval];
    [self.pickerView selectRow:row inComponent:0 animated:NO];
    if ([self.pickerView respondsToSelector:@selector(setTintAdjustmentMode:)]) {
        
        [self.pickerView setTintAdjustmentMode:UIViewTintAdjustmentModeDimmed];
        [self.pickerView setBackgroundColor:[UIColor whiteColor]];
    }
    self.pickerTextField.inputView = self.pickerView;
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    [self configureDefaultText];
    [self.navigationController setNavigationBarHidden:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark UITableViewDataSource

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.currentRingtone.soundEnabled) {
        return 3;
    } else {
        return 1;
    }
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
        {
            return 4;
            break;
        }
        case 1:
        {
            NSArray *soundsArray = [Ringtone arrayOfSoundsDictionariesWithCategory:@"Default"];
            return soundsArray.count;
            break;
        }
        case 2:
        {
            NSArray *soundsArray = [Ringtone arrayOfSoundsDictionariesWithCategory:@"More..."];
            return soundsArray.count;
            break;
        }
        default:
            return 0;
            break;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [[UIView alloc] init];
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, 7, 300, 15)];
    headerLabel.backgroundColor = [UIColor clearColor];
    headerLabel.font = [UIFont fontWithName:@"HelveticaNeueLTStd-Bd" size:12];
    headerLabel.textColor = [UIColor colorWithRed:0.0f/255.0f green:120.0f/255.0f blue:174.0f/255.0f alpha:1.0f];
    headerView.backgroundColor = [UIColor colorWithRed:255/255.0f green:255/255.0f blue:255/255.0f alpha:0.7];
    [headerView addSubview:headerLabel];
    switch (section) {
        case 0:
            headerLabel.text = QliqLocalizedString(@"2030-TitleSettings");
            return headerView;
            break;
        case 1:
            headerLabel.text = QliqLocalizedString(@"2063-TitleQliqSounds");
            return headerView;
            break;
        case 2:
            headerLabel.text = QliqLocalizedString(@"2064-TitleSounds");
            return headerView;
            break;
        default:
            return nil;
            break;
    }
}

-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SettingsRingtoneTableViewCell *cell = nil;
    
    static NSString *reuseId1 = @"BASE_RINGTONE_SETTINGS_CELL_ID";
    static NSString *reuseId2 = @"RINGTONE_SETTINGS_CELL_ID";
    
    switch (indexPath.section) {
        case 0:
        {
            cell = [tableView dequeueReusableCellWithIdentifier:reuseId1];
            switch (indexPath.row) {
                case 0:
                {
                    cell.titleLabel.text = QliqLocalizedString(@"2065-TitleVibrate");
                    cell.switchOption.hidden = NO;
                    cell.volumeBar.hidden = YES;
                    cell.editButton.hidden = YES;
                    cell.timeLabel.hidden = YES;
                    cell.switchOption.tag = 1;
                    cell.switchOption.on = self.currentRingtone.vibrateEnabled;
                    [cell.switchOption addTarget:self action:@selector(didChangeValueInSwitch:) forControlEvents:UIControlEventValueChanged];
                    break;
                }
                case 1:
                {
                    cell.titleLabel.text = QliqLocalizedString(@"2066-TitleSound");
                    cell.switchOption.hidden = NO;
                    cell.volumeBar.hidden = YES;
                    cell.editButton.hidden = YES;
                    cell.timeLabel.hidden = YES;
                    cell.switchOption.tag = 2;
                    cell.switchOption.on = self.currentRingtone.soundEnabled;
                    [cell.switchOption addTarget:self action:@selector(didChangeValueInSwitch:) forControlEvents:UIControlEventValueChanged];
                    break;
                }
                case 2:
                {
                    cell.titleLabel.text = QliqLocalizedString(@"2067-TitleVolume");
                    cell.switchOption.hidden = YES;
                    cell.volumeBar.hidden = NO;
                    cell.editButton.hidden = YES;
                    cell.timeLabel.hidden = YES;
                    [cell.volumeBar addTarget:self action:@selector(didChangeVolume:) forControlEvents:UIControlEventValueChanged];
                    cell.volumeBar.selectedSegmentIndex = self.currentRingtone.volume;
                    break;
                }
                case 3:
                {
                    cell.titleLabel.text = QliqLocalizedString(@"2068-TitleRemindInterval");
                    cell.switchOption.hidden = YES;
                    cell.volumeBar.hidden = YES;
                    cell.editButton.hidden = NO;
                    cell.timeLabel.hidden = NO;
                    cell.timeLabel.text = [self pickerView:self.pickerView titleForRow:[self rowForChimeCount:self.notificationSettings.reminderChimeInterval] forComponent:0];
                    if (self.reminderCountPicking) {
                        [cell.editButton setTitle:QliqLocalizedString(@"38-ButtonDone") forState:UIControlStateNormal];
                    } else {
                        [cell.editButton setTitle:QliqLocalizedString(@"46-ButtonEdit") forState:UIControlStateNormal];
                    }
                    [cell.editButton addTarget:self action:@selector(editReminderDidTapped:) forControlEvents:UIControlEventTouchUpInside];
                    break;
                }
                default:
                    break;
            }
            break;
        }
        case 1:
        {
            cell = [tableView dequeueReusableCellWithIdentifier:reuseId2];
            NSArray *soundsArray = [Ringtone arrayOfSoundsDictionariesWithCategory:@"Default"];
            cell.ringtoneNameLabel.text = [soundsArray[indexPath.row] objectForKey:@"name"];
            break;
        }
        case 2:
        {
            cell = [tableView dequeueReusableCellWithIdentifier:reuseId2];
            NSArray *soundsArray = [Ringtone arrayOfSoundsDictionariesWithCategory:@"More..."];
            cell.ringtoneNameLabel.text = [soundsArray[indexPath.row] objectForKey:@"name"];
            break;
        }
        default:
            break;
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0:
            // Switch and button selectors used
            break;
        case 1:
        {
            NSArray *soundsArray = [Ringtone arrayOfSoundsDictionariesWithCategory:@"Default"];
            NSDictionary *soundDict = soundsArray[indexPath.row];
            [self.currentRingtone setRingtoneDictionary:soundDict];
            [self ringtoneChanged];
            [self.currentRingtone play];
            break;
        }
        case 2:
        {
            NSArray *soundsArray = [Ringtone arrayOfSoundsDictionariesWithCategory:@"More..."];
            NSDictionary *soundDict = soundsArray[indexPath.row];
            [self.currentRingtone setRingtoneDictionary:soundDict];
            [self ringtoneChanged];
            [self.currentRingtone play];
            break;
        }
        default:
            break;
    }
    
    [self.navigationController popViewControllerAnimated:YES]; // When choose a ringtone and back to previous settings
}

#pragma mark - Inner logic

- (void) ringtoneChanged {
    
    [[UserSessionService currentUserSession].userSettings write];
}

#pragma mark - Reminder methods

- (NSInteger) rowForChimeCount:(NSInteger) chimeCount{
    NSUInteger result = [self.reminderDictionaryKeys indexOfObject:[NSNumber numberWithUnsignedInteger:chimeCount]];
    if (result == NSNotFound)
        result = 0;
    return result;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    return [self.reminderDictionaryKeys count];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 1;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    return [self.reminderDictionary objectForKey:[self.reminderDictionaryKeys objectAtIndex:row]];
}

- (void) pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    
    self.notificationSettings.reminderChimeInterval = [[self.reminderDictionaryKeys objectAtIndex:row] unsignedIntegerValue];
    [self ringtoneChanged];
    [self.tableView reloadData];
}

#pragma mark - IBActions

- (IBAction)onBack:(id)sender {
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) editReminderDidTapped:(QliqButton *) button{

    self.reminderCountPicking = !self.reminderCountPicking;

    if (self.reminderCountPicking){
        [self.pickerTextField becomeFirstResponder];
    } else {
        [self.pickerTextField resignFirstResponder];
    }
    [self.tableView reloadData];
}

- (void)didChangeValueInSwitch:(UISwitch *)cellSwitch {
    
    switch (cellSwitch.tag) {
        case 1:
        {
            self.currentRingtone.vibrateEnabled = cellSwitch.on;
            [self ringtoneChanged];
            break;
        }
        case 2:
        {
            BOOL didSoundEnabled = self.currentRingtone.soundEnabled;
            self.currentRingtone.soundEnabled = cellSwitch.on;
            if (didSoundEnabled != self.currentRingtone.soundEnabled){
                [self ringtoneChanged];
            }
            break;
        }
        default:
            break;
    }
    [self.tableView reloadData];
}

- (void) didChangeVolume:(UISegmentedControl *)segmentedControlVolume {
    
    self.currentRingtone.volume = (RingtoneVolume)segmentedControlVolume.selectedSegmentIndex;
    [self ringtoneChanged];
    [self.currentRingtone play];
}

@end

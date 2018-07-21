//
//  SettingsGeneralViewController.m
//  qliq
//
//  Created by Valerii Lider on 05/23/2017.
//
//

#import "SettingsGeneralViewController.h"
#import "SettingsGeneralTableViewCell.h"

#define kDefaultCellHeight 44.f
#define kDefaultHeaderSectionHeight 20.f

typedef NS_ENUM(NSInteger, SettingsType) {
    SettingsTypeSnapAndSign,
    SettingsTypeCount
};

typedef NS_ENUM(NSInteger, SnapAndSignCell) {
    SnapAndSignCellUploadToQliqSTOR,
    SnapAndSignCellCount
};

typedef enum {
    SwitchUploadToQliqSTOR = 1,
} SwitchAction;

@interface SettingsGeneralViewController () <UITableViewDataSource, UITableViewDelegate>

//IBOutlets
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *navigationLeftTitleLabel;
//Constraints
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableViewTopConstraint;

//Data
@property (strong, nonatomic) NSMutableArray *snapAndSignItems;

@end

@implementation SettingsGeneralViewController

- (void)dealloc {
    self.navigationLeftTitleLabel = nil;
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    self.tableViewTopConstraint.constant = 0.f;
    [self.snapAndSignItems removeAllObjects];
    self.snapAndSignItems = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationController setNavigationBarHidden:NO];
    self.tableViewTopConstraint.constant = 0.f;
    self.navigationLeftTitleLabel.text = QliqLocalizedString(@"2464-TitleGeneral");

    self.snapAndSignItems = [[NSMutableArray alloc] init];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

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

#pragma mark - Private -

- (void)prepareSnapAndSignItems
{
    [self.snapAndSignItems removeAllObjects];

    [self.snapAndSignItems addObject:@(SnapAndSignCellUploadToQliqSTOR)];
}

#pragma mark - Actions -

- (IBAction)didTapOnBackButton:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didChangeValueInSwitch:(UISwitch *)cellSwitch
{
    switch (cellSwitch.tag)
    {
        case SwitchUploadToQliqSTOR:
        {
            DDLogSupport(@"The Upload to QliqSTOR settings is %d", cellSwitch.on);
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            [userDefaults setBool:cellSwitch.on forKey:kUploadToQliqSTORKey];
            break;
        }
        default:
            break;
    }
}

#pragma mark - Delegates -

#pragma mark * UITableViewDelegate/DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return SettingsTypeCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;

    switch ((SettingsType)section) {
        case SettingsTypeSnapAndSign: {

            [self prepareSnapAndSignItems];

            count = self.snapAndSignItems.count;

            break;
        }
        default:
            break;
    }
    return count;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return kDefaultCellHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return kDefaultCellHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return kDefaultHeaderSectionHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [[UIView alloc] init];
    headerView.backgroundColor = RGBa(255, 255, 255, 0.7f);

    NSString *titleHeader = @"";

    if (section == SettingsTypeSnapAndSign) {
        titleHeader = QliqLocalizedString(@"2465-TitleSnapAndSignSettings");
    }

    UIFont *titleHeaderFont    = [UIFont systemFontOfSize:14.f];
    CGFloat offset             = 60.f;

    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(offset/2, 0, tableView.bounds.size.width - offset, kDefaultHeaderSectionHeight)];
    headerLabel.text            = titleHeader;
    headerLabel.textColor       = RGBa(3, 120, 173, 1);
    headerLabel.backgroundColor = [UIColor clearColor];
    headerLabel.font            = titleHeaderFont;
    headerLabel.textAlignment   = NSTextAlignmentLeft;
    headerLabel.adjustsFontSizeToFitWidth = YES;

    [headerLabel setMinimumScaleFactor:8.f/[UIFont labelFontSize]];

    [headerView addSubview:headerLabel];

    return headerView;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch ((SettingsType)indexPath.section) {
        case SettingsTypeSnapAndSign: {

            static NSString *reuseIdentifire = @"GENERAL_SETTINGS_CELL_ID";
            SettingsGeneralTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifire];

            SnapAndSignCell cellType = [self.snapAndSignItems[indexPath.row] integerValue];
            switch (cellType)
            {
                case SnapAndSignCellUploadToQliqSTOR: {
                    cell.nameOptionLabel.text = QliqLocalizedString(@"1229-TitleUploadToQliqStor");

                    cell.switchOption.hidden = NO;
                    cell.switchOption.tag = SwitchUploadToQliqSTOR;

                    BOOL uploadToQliqSTOR = [[NSUserDefaults standardUserDefaults] boolForKey:kUploadToQliqSTORKey];
                    [cell.switchOption setOn:uploadToQliqSTOR animated:NO];
                    [cell.switchOption addTarget:self action:@selector(didChangeValueInSwitch:) forControlEvents:UIControlEventValueChanged];
                    break;
                }
                default:
                    break;
            }
            return cell;
            break;
        }
        default:
            return nil;
            break;
    }
}
@end

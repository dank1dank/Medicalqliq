//
//  SearchPatientsViewController.m
//  qliq
//
//  Created by Valerii Lider on 01/03/2017.
//
//

#import "SearchPatientsViewController.h"
#import "SearchPatientsTableViewCell.h"
#import "PatientsTableViewCell.h"

#import "QliqUser.h"
#import "ResizeBadge.h"
#import "ConversationDBService.h"
#import "MediaFile.h"
#import "MessageAttachment.h"

#import "SearchPatientsService.h"
#import "UploadToEmrService.h"

#import "EMRUploadViewController.h"
#import "AlertController.h"

#define kValueHeightForHeaderInSectionDefault   25.0f
#define kValueDefaultCellHeight   30.f
#define kValueHeightTextField   25.f
#define kValueMinBottomTextField  8.f
#define kValueTopTextField  10.f
#define kValueDefaultPatientsCellHeight   45.f

#define kKeySearchText  @"serchText"
#define kKeyTitleText  @"titleText"

typedef NS_ENUM(NSInteger, TableCellType) {
    TableCellTypeSearchPatients,
    TableCellTypePatients,
    TableCellTypeCount
};

typedef NS_ENUM(NSInteger, SearchTextFieldType ) {
    SearchTextFieldTypeLastName = 0,
    SearchTextFieldTypeFirstName,
    SearchTextFieldTypeDateOfBirth,
    SearchTextFieldTypeMRN,
    SearchTextFieldTypeCount
};

@interface SearchPatientsViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UploadToEmrService *uploadToEmrService;
@property (nonatomic, strong) SearchPatientsService *service;
@property (nonatomic, assign) NSInteger totalPatientCount;
@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, strong) NSString *emrSourceQliqId;
@property (nonatomic, strong) NSString *emrSourceDeviceUuid;
@property (nonatomic, strong) NSString *emrSourcePublicKey;

@property (nonatomic, strong) NSMutableArray *searchPatients;
@property (nonatomic, strong) NSMutableArray *totalPatients;
@property (nonatomic, strong) NSMutableArray *searchingResultsArray;

@property (nonatomic, strong) NSString *qliqSTORQliqId;

@property (nonatomic, assign) TableCellType cellType;
@property (nonatomic, assign) CGFloat heightHeaderSearching;
@property (nonatomic, assign) BOOL isSearch;
@property (nonatomic, assign) BOOL searchingResults;
@property (nonatomic, assign) BOOL isCareChannelMode;

//IBOutlets
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (strong, nonatomic) UIButton *loadResultsButton;

//Constraints
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableViewTopConstraint;

@end

@implementation SearchPatientsViewController

- (void)dealloc {
    
    self.searchPatients = nil;
    self.totalPatients = nil;
    self.searchingResultsArray = nil;
    self.conversation = nil;
    self.mediaFile = nil;
    self.backButton = nil;
    self.uploadToEmrService = nil;
    self.service = nil;
    self.totalPatientCount = nil;
    self.currentPage = nil;
    self.emrSourceQliqId = nil;
    self.emrSourceDeviceUuid = nil;
    self.emrSourcePublicKey = nil;
    self.qliqSTORQliqId = nil;
    self.tableView = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    if (self.uploadToEmrService == nil) {
        self.uploadToEmrService = [[UploadToEmrService alloc] init];
    }
    if (self.service == nil) {
        self.service = [[SearchPatientsService alloc] init];
    }
    
    if (self.searchPatients == nil) {
        self.searchPatients = [[NSMutableArray alloc] init];
    }
    
    if (self.totalPatients == nil) {
        self.totalPatients = [[NSMutableArray alloc] init];
    }

    if (self.searchingResultsArray == nil) {
        self.searchingResultsArray = [[NSMutableArray alloc] init];
    }
    
    self.totalPatientCount = 1;
    
    if (self.conversation.isCareChannel == 1) {
        self.isCareChannelMode = YES;
    }
    
    static NSString *searchPatientsCellID = @"SearchPatientsTableViewCell_ID";
    UINib *nib = [UINib nibWithNibName:@"SearchPatientsTableViewCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:searchPatientsCellID];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didChangeOrientationNotification:)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
    
    // No need show this alert, as this leads to a duplicate of display the alert when user has multiple qliqstors. This alert will shown after tap on button "Upload" if needed.
    // Valerii Lider 06/19/18
//    if ([QxQliqStorClient shouldShowQliqStorSelectionDialog] && [QxQliqStorClient qliqStors].count > 1) {
//        [self showMultipleQliqSTORsAlert];
//    } else {
        self.qliqSTORQliqId = [QxQliqStorClient defaultQliqStor].qliqStorQliqId;
        if (!self.qliqSTORQliqId.length) {
            DDLogSupport(@"Cannot find the QliqSTOR group with qliqSTORQliqId = %@", self.qliqSTORQliqId);
            
            [AlertController showAlertWithTitle:nil
                                        message:QliqLocalizedString(@"3040-QliqSTORisNotActivated")
                                    buttonTitle:nil
                              cancelButtonTitle:QliqLocalizedString(@"1-ButtonOk")
                                     completion:^(NSUInteger buttonIndex) {
                                         if (buttonIndex==1) {
                                             [self onBackAction:nil];
                                         }
                                     }];
        };
//    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)didChangeOrientationNotification:(NSNotification *)notification {
    
    [self configFooterView];
    [self.tableView reloadData];
}

#pragma mark - Public -

- (void)uploadCareChannelConversation:(Conversation *)conversation {
    
    if (conversation.isCareChannel == 1) {
        self.isCareChannelMode = YES;
    }
    [self uploadConversation:conversation messages:nil patient:conversation.encounter.patient];
}

#pragma mark - Private -

- (void)configureHeightForHeaderSearching {
    
    CGFloat topDistanceColumn = 10.f;
    CGFloat resultsLabelHeight = 25.f;
    CGFloat resultsLabelBottom = 8.f;
    CGFloat minColumnHeight = resultsLabelHeight + resultsLabelBottom;
    
    if (self.searchingResults) {
        if (self.searchingResultsArray.count <= 2) {
            self.heightHeaderSearching = topDistanceColumn + minColumnHeight + kValueHeightForHeaderInSectionDefault + resultsLabelBottom;
        }
        else {
            self.heightHeaderSearching = topDistanceColumn + 2 * minColumnHeight + kValueHeightForHeaderInSectionDefault + resultsLabelBottom;
        }
    }
    else {
        self.heightHeaderSearching = kValueHeightForHeaderInSectionDefault;
    }
}

- (void)getSearchPatientsServiceResultWithPage:(int)page {
    
    SearchPatientsTableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    
    NSString *lastName = cell.lastNameTextField.text;
    NSString *firstName = cell.firstNameTextField.text;
    NSString *dateOfBirth = cell.dateOfBirthTextField.text;
    NSString *mrn = cell.mrnTextField.text;
    
    lastName = [lastName stringByReplacingOccurrencesOfString:@" " withString:@""];
    firstName = [firstName stringByReplacingOccurrencesOfString:@" " withString:@""];
    dateOfBirth = [dateOfBirth stringByReplacingOccurrencesOfString:@" " withString:@""];
    mrn = [mrn stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    
    NSDateFormatter *dateFormater = [[NSDateFormatter alloc] init];
    [dateFormater setDateFormat:@"MM/dd/yyyy"];
    
    NSDate *date = [dateFormater dateFromString:dateOfBirth];
    [dateFormater setDateFormat:@"yyyy-MM-dd"];
    dateOfBirth =[dateFormater stringFromDate:date];
    
    SearchPatientsServiceQuery *query = [[SearchPatientsServiceQuery alloc] init];
    query.qliqStorQliqId = self.qliqSTORQliqId;
    query.searchUuid = [[NSUUID UUID] UUIDString];
    query.firstName = firstName;
    query.lastName = lastName;
    query.dob = dateOfBirth; // must be: yyyy-MM-dd
    query.mrn = mrn;
    
    dispatch_async_main(^{
        [SVProgressHUD showWithStatus:@"Searching"];
    });

    __weak SearchPatientsViewController *weakSelf = self;
    [self.service call:query page:page perPage:20 withCompletition:^(CompletitionStatus status, id resultArg, NSError *error) {
        
        dispatch_async_main(^{
            [SVProgressHUD dismiss];
        });
        
        if (status == CompletitionStatusSuccess) {
            weakSelf.isSearch = YES;
            SearchPatientsServiceResult *result = (SearchPatientsServiceResult *)resultArg;
            weakSelf.totalPatientCount = result.totalCount;
            weakSelf.emrSourceQliqId = result.emrSourceQliqId;
            weakSelf.emrSourceDeviceUuid = result.emrSourceDeviceUuid;
            weakSelf.emrSourcePublicKey = result.emrSourcePublicKey;
            
            for (NSUInteger i = 0; i < result.patients.count; ++i) {
                FhirPatient *patient = [result.patients objectAtIndex:i];
                NSLog(@"patient: %@ %@", patient.firstName, patient.lastName);
                [weakSelf.totalPatients addObject:patient];
            }
            
        } else {
            // Error
            [AlertController showAlertWithTitle:QliqLocalizedString(@"1072-TextWarning")
                                        message:error.localizedDescription
                                    buttonTitle:nil
                              cancelButtonTitle:QliqLocalizedString(@"1-ButtonOk")
                                     completion:nil];
            
            weakSelf.isSearch = NO;
            cell.searchButton.hidden = NO;
            [weakSelf.searchPatients removeAllObjects];
            weakSelf.emrSourceQliqId = nil;
            weakSelf.emrSourceDeviceUuid = nil;
            weakSelf.emrSourcePublicKey = nil;
            [weakSelf.tableView endEditing:YES];
        }
        [weakSelf configFooterView];
        [weakSelf.tableView reloadData];
    } withIsCancelled:^BOOL{
        // Cancel response processing if the view controller is already destroyed
//        SearchPatientsViewController *strongSelf = weakSelf;
        return (weakSelf == nil);
    }];
}

- (UIView *)configureHeaderView {
    
    UIView *headerView = [[UIView alloc] init];
    headerView.backgroundColor = [UIColor whiteColor];
    
    __weak __block typeof(self) welf = self;
    VoidBlock configureHeaderLabel = ^{
        
        UILabel *headerLabel = [[UILabel alloc] init];
        headerLabel.frame = CGRectMake(0.f, 0.f, welf.tableView.frame.size.width, kValueHeightForHeaderInSectionDefault);
        headerLabel.textAlignment = NSTextAlignmentCenter;
        headerLabel.layer.backgroundColor = RGBa(235, 235, 235, 0.7f).CGColor;
        headerView.frame = CGRectMake(0.f, 0.f, CGRectGetWidth([UIScreen mainScreen].bounds),CGRectGetMaxY(headerLabel.frame));
        
        NSString *titleHeader = [NSString stringWithFormat:@"Found: %lu Patients of %lu Total", (unsigned long)welf.totalPatients.count, (long)welf.totalPatientCount];
        headerLabel.font            = [UIFont systemFontOfSize:14.f];
        headerLabel.textColor       = RGBa(3, 120, 173, 1);
        headerLabel.text            = titleHeader;
        [headerView addSubview:headerLabel];
    };
    
    
    if (self.totalPatients.count > 0) {
        UIView *searchView = [[UIView alloc] init];
        UILabel *headerLabel = [[UILabel alloc] init];
        
        CGFloat positionColumn = 10.f;
        CGFloat refineSearchWidth = 75.f;
        
        if (self.searchingResults) {
            
            CGFloat resultsLabelHeight = 25.f;
            CGFloat resultsLabelBottom = 8.f;
            CGFloat minDistance = 4.f;
            CGFloat minColumnHeight = resultsLabelHeight + resultsLabelBottom;
            
            for (int index = 0; index < self.searchingResultsArray.count; index++) {
                
                UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(positionColumn, positionColumn, self.tableView.frame.size.width/2 - positionColumn, resultsLabelHeight)];
                imageView.image = [UIImage imageNamed:@"SettingsFrame"];
                imageView.layer.borderColor = RGBa(95, 95, 95, 1).CGColor;
                
                UIFont *font = [UIFont systemFontOfSize:14.f];
                NSMutableDictionary *searchingDict = self.searchingResultsArray[index];
                NSString *searchText = [NSString stringWithFormat:@"  %@", searchingDict[kKeySearchText]];
                
                if (index % 2 == 0) {
                    
                    if (index == 0) {
                        imageView.frame = CGRectMake(imageView.frame.origin.x, imageView.frame.origin.y, imageView.frame.size.width + minDistance, imageView.frame.size.height);
                    }
                    else {
                        imageView.frame = CGRectMake(imageView.frame.origin.x, imageView.frame.origin.y + imageView.frame.size.height + resultsLabelBottom, imageView.frame.size.width + minDistance, imageView.frame.size.height);
                    }
                }
                else {
                    
                    imageView.frame = CGRectMake(imageView.frame.origin.x + imageView.frame.size.width + positionColumn, imageView.frame.origin.y, imageView.frame.size.width - positionColumn, imageView.frame.size.height);
                    
                    if (index > 1) {
                        imageView.frame = CGRectMake(imageView.frame.origin.x, imageView.frame.origin.y + imageView.frame.size.height + resultsLabelBottom, imageView.frame.size.width, imageView.frame.size.height);
                    }
                }
                
                UILabel *resultsLabel = [[UILabel alloc] initWithFrame:CGRectMake(imageView.frame.origin.x, imageView.frame.origin.y, imageView.frame.size.width, imageView.frame.size.height)];
                
                resultsLabel.font = font;
                resultsLabel.text = searchText;
                resultsLabel.textColor = RGBa(95, 95, 95, 1);
                CGFloat neededWidthResultsLabel = [ResizeBadge calculatingNeededWidthForBadge:searchText rangeLength:searchText.length font:font];
                
                UILabel *titleLabel = [[UILabel alloc] init];
                titleLabel.font = [UIFont systemFontOfSize:12.f];
                titleLabel.text = searchingDict[kKeyTitleText];
                titleLabel.textColor = RGBa(3, 120, 173, 1);
                CGFloat neededWidthTitleLabel = [ResizeBadge calculatingNeededWidthForBadge:titleLabel.text rangeLength:titleLabel.text.length font:titleLabel.font];
                
                if (neededWidthResultsLabel > (imageView.frame.size.width - neededWidthTitleLabel + 3.f)) {
                    [resultsLabel setFrame:CGRectMake(imageView.frame.origin.x, imageView.frame.origin.y, imageView.frame.size.width - neededWidthTitleLabel - 3.f, imageView.frame.size.height)];
                }
                else {
                    [resultsLabel setFrame:CGRectMake(imageView.frame.origin.x, imageView.frame.origin.y, neededWidthResultsLabel, imageView.frame.size.height)];
                }
                
                [titleLabel setFrame:CGRectMake(imageView.frame.origin.x + (imageView.frame.size.width - neededWidthTitleLabel - 2.f), imageView.frame.origin.y, neededWidthTitleLabel + 2.f, imageView.frame.size.height)];
                
                [searchView addSubview:resultsLabel];
                [searchView addSubview:titleLabel];
                [searchView addSubview:imageView];
            }
            [headerView addSubview:searchView];
            
            //Configure Total View
            UIView *totalView = [[UIView alloc] init];
            totalView.backgroundColor = RGBa(235, 235, 235, 0.7f);
            [headerView addSubview:totalView];
            
            
            if (self.searchingResultsArray.count <= 2) {
                headerLabel.frame = CGRectMake(5.f, positionColumn + minColumnHeight, self.tableView.frame.size.width - refineSearchWidth - positionColumn, kValueHeightForHeaderInSectionDefault);
            }
            else {
                headerLabel.frame = CGRectMake(5.f, positionColumn + 2 * minColumnHeight, self.tableView.frame.size.width - refineSearchWidth - positionColumn, kValueHeightForHeaderInSectionDefault);
            }
            
            //Configure Refine Search Button
            UIButton *refineSearchButton = [[UIButton alloc] initWithFrame:CGRectMake(self.tableView.frame.size.width - refineSearchWidth - 5.f, headerLabel.frame.origin.y, refineSearchWidth, 30.f)];
            refineSearchButton.layer.masksToBounds = YES;
            refineSearchButton.clipsToBounds = YES;
            refineSearchButton.layer.cornerRadius = 10.f;
            refineSearchButton.layer.borderWidth = 1.f;
            refineSearchButton.layer.borderColor = [kColorDarkBlue CGColor];
            refineSearchButton.layer.backgroundColor = [UIColor whiteColor].CGColor;
            [refineSearchButton setTitleColor:RGBa(3, 120, 173, 1) forState:UIControlStateNormal];
            refineSearchButton.titleLabel.font = [UIFont systemFontOfSize:10.f];
            [refineSearchButton setTitle:QliqLocalizedString(@"2429-TitleRefineSearch") forState:UIControlStateNormal];
            [refineSearchButton addTarget:self action:@selector(onRefineSearchAction:) forControlEvents:UIControlEventTouchUpInside];
            
            //Configure Total View frame
            totalView.frame = CGRectMake(0.f, headerLabel.frame.origin.y, CGRectGetWidth([UIScreen mainScreen].bounds), refineSearchButton.frame.size.height + 10.f);
            
            //Configure Header Label frame
            [headerLabel setFrame:CGRectMake(headerLabel.frame.origin.x, totalView.frame.origin.y + (totalView.frame.size.height - headerLabel.frame.size.height)/2, headerLabel.frame.size.width, headerLabel.frame.size.height)];
            [refineSearchButton setFrame:CGRectMake(refineSearchButton.frame.origin.x, totalView.frame.origin.y + (totalView.frame.size.height - refineSearchButton.frame.size.height)/2, refineSearchButton.frame.size.width, refineSearchButton.frame.size.height)];
            
            [headerView addSubview:refineSearchButton];
            
            //Configure Header Label
            headerLabel.textAlignment = NSTextAlignmentLeft;
            headerLabel.layer.backgroundColor = [UIColor clearColor].CGColor;
            
            //Configure Header View frame
            CGFloat maxHeaderHeight = CGRectGetMaxY(totalView.frame);
            maxHeaderHeight += totalView.frame.size.height;
            headerView.frame = CGRectMake(0.f, 0.f, CGRectGetWidth([UIScreen mainScreen].bounds),maxHeaderHeight);
        } else {
            //Configure Header Label
            headerLabel.frame = CGRectMake(0.f, 0.f, self.tableView.frame.size.width, kValueHeightForHeaderInSectionDefault);
            headerLabel.textAlignment = NSTextAlignmentCenter;
            headerLabel.layer.backgroundColor = RGBa(235, 235, 235, 0.7f).CGColor;
            
            //Configure Header View frame
            headerView.frame = CGRectMake(0.f, 0.f, CGRectGetWidth([UIScreen mainScreen].bounds),CGRectGetMaxY(headerLabel.frame));
        }
        
        //Configure Header Label
        NSString *titleHeader = [NSString stringWithFormat:@"Found: %lu Patients of %lu Total", (unsigned long)self.totalPatients.count, (long)self.totalPatientCount];
        headerLabel.font            = [UIFont systemFontOfSize:14.f];
        headerLabel.textColor       = RGBa(3, 120, 173, 1);
        headerLabel.text            = titleHeader;
        [headerView addSubview:headerLabel];
    } else {
        if (self.totalPatientCount == 0) {
            configureHeaderLabel();
        }
        self.totalPatientCount = 0;
    }
    
    if (self.totalPatientCount > self.totalPatients.count) {
        
        UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, self.tableView.frame.size.width, 80.f)];
        
        CGFloat buttonWidth = 140.f;
        CGFloat buttonHeight = 30.f;
        
        UIButton *loadResultsButton = [[UIButton alloc] initWithFrame:CGRectMake(footerView.center.x - buttonWidth/2, footerView.center.y - buttonHeight/2, buttonWidth, buttonHeight)];
        
        loadResultsButton.layer.backgroundColor = RGBa(24, 122, 181, 1).CGColor;
        [loadResultsButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        loadResultsButton.titleLabel.font = [UIFont systemFontOfSize:15.f];
        [loadResultsButton setTitle:QliqLocalizedString(@"2430-TitleLoadMoreResults") forState:UIControlStateNormal];
        [loadResultsButton addTarget:self action:@selector(onMoreResults:) forControlEvents:UIControlEventTouchUpInside];
        
        [footerView addSubview:loadResultsButton];
        self.tableView.tableFooterView = footerView;
    }
    
    return headerView;
}

//- (void)showUploadOptionsForPatient:(FhirPatient *)patient {
//
//    //property .conversation - current conversation
//
//    [AlertController showAlertWithTitle:nil
//                                message:nil
//                       withTitleButtons:@[QliqLocalizedString(@"2433-TitleUploadAllMessages"), QliqLocalizedString(@"2434-TitleUploadParticularMessages")]
//                      cancelButtonTitle:QliqLocalizedString(@"4-ButtonCancel")
//                             completion:^(NSUInteger buttonIndex) {
//                                 switch (buttonIndex) {
//                                     case 0:
//                                         break;
//                                     case 1:
//                                         break;
//                                     case 2:{
//                                         if (self.isCareChannelMode) {
//                                             [self dismissViewControllerAnimated:YES completion:nil];
//                                             [self onBackAction:self.backButton];
//                                         }
//                                     }
//                                         break;
//
//                                     default:
//                                         break;
//                                 }
//                             }];
//
////    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
////
////    UIAlertAction *allMessages = [UIAlertAction actionWithTitle:NSLocalizedString(@"2433-TitleUploadAllMessages", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
////
////    }];
////
////    UIAlertAction *particularMessages = [UIAlertAction actionWithTitle:NSLocalizedString(@"2434-TitleUploadParticularMessages", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
////
////    }];
////
////    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"4-ButtonCancel", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
////        if (self.isCareChannelMode) {
////            [self dismissViewControllerAnimated:YES completion:nil];
////            [self onBackAction:self.backButton];
////        }
////    }];
////
////    [alert addAction:allMessages];
////    [alert addAction:particularMessages];
//////    [alert addAction:media];
////    [alert addAction:cancel];
////
////    alert.preferredContentSize = CGSizeMake(450, 350);
////    alert.popoverPresentationController.sourceView =self.view;
////    alert.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMaxY(self.view.bounds)-50, 0, 0);
////    alert.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
////
////    [self presentViewController:alert animated:YES completion:nil];
//}


- (void)showMultipleQliqSTORsAlert {

    QliqAlertView *multipleQliqSTORsAlert = [[QliqAlertView alloc] initWithInverseColor:NO];
    multipleQliqSTORsAlert.useMultipleQliqSTORsAvialable = YES;
    [multipleQliqSTORsAlert setContainerViewWithImage:[UIImage imageNamed:@""]
                                            withTitle:QliqLocalizedString(@"1110-TextUploadToEMR")
                                             withText:QliqLocalizedString(@"3037-TextMultipleQliqSTORsAvilable")
                                         withDelegate:nil
                                     useMotionEffects:YES];
    [multipleQliqSTORsAlert setButtonTitles:[NSMutableArray arrayWithObjects:QliqLocalizedString(@"4-ButtonCancel"), QliqLocalizedString(@"44-ButtonSave"), nil]];

    [multipleQliqSTORsAlert setOnButtonTouchUpInside:^(QliqAlertView *alertView, int buttonIndex) {
        if (buttonIndex != 0)
        {
            QliqStorPerGroup *selectedQliqSTORGroup = alertView.selectedTypeQliqSTORGroup;

            BOOL isSaveAsDefault = [alertView isSaveDefaultOption];

            if (selectedQliqSTORGroup && isSaveAsDefault) {
                [QxQliqStorClient setDefaultQliqStor:selectedQliqSTORGroup.qliqStorQliqId groupQliqId:selectedQliqSTORGroup.groupQliqId];
            }

            if ([selectedQliqSTORGroup qliqStorQliqId].length > 0 && alertView.destinationGroupTextField.text.length > 0) {
                self.qliqSTORQliqId = selectedQliqSTORGroup.qliqStorQliqId;
            } else if (!alertView.destinationGroupTextField.text.length) {

                [AlertController showAlertWithTitle:QliqLocalizedString(@"1072-TextWarning")
                                            message:QliqLocalizedString(@"2451-TitleSelectTypeField")
                                        buttonTitle:nil
                                  cancelButtonTitle:QliqLocalizedString(@"1-ButtonOk")
                                         completion:^(NSUInteger buttonIndex) {
                                      [alertView show];
                                  }];
            } else if (!selectedQliqSTORGroup) {
                DDLogSupport(@"Can't to find QliqSTOR Group");
            }
        } else {
            [self onBackAction:nil];
        }
    }];
    
    performBlockInMainThreadSync(^{
        [multipleQliqSTORsAlert show];
    });
}

#pragma mark - Actions -

- (IBAction)onBackAction:(id)sender {
    
    DDLogSupport(@"Back from SearchPatientsViewController");
    if (self.navigationController.presentingViewController && [[self.navigationController viewControllers].firstObject isEqual:self]) {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)onSearchAction:(UIButton *)button {
    
    self.isSearch = NO;
    
    SearchPatientsTableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    
    NSString *lastName = cell.lastNameTextField.text;
    NSString *firstName = cell.firstNameTextField.text;
    NSString *dateOfBirth = cell.dateOfBirthTextField.text;
    NSString *mrn = cell.mrnTextField.text;
    
    lastName = [lastName stringByReplacingOccurrencesOfString:@" " withString:@""];
    firstName = [firstName stringByReplacingOccurrencesOfString:@" " withString:@""];
    dateOfBirth = [dateOfBirth stringByReplacingOccurrencesOfString:@" " withString:@""];
    mrn = [mrn stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    BOOL validSearch = YES;
    self.searchingResults = NO;
    
    
    if (!cell.lastNameTextField.hidden && !cell.firstNameTextField.hidden && !cell.dateOfBirthTextField.hidden && !cell.mrnTextField.hidden) {
        
        if ((lastName == nil || [lastName isEqualToString:@""]) && (firstName == nil || [firstName isEqualToString:@""]) && (dateOfBirth == nil || [dateOfBirth isEqualToString:@""]) && (mrn == nil || [mrn isEqualToString:@""])) {
            
            validSearch = NO;

            [AlertController showAlertWithTitle:QliqLocalizedString(@"1072-TextWarning")
                                        message:QliqLocalizedString(@"3034-TextSearchFieldsNotBeEmpty")
                                    buttonTitle:nil
                              cancelButtonTitle:QliqLocalizedString(@"1-ButtonOk")
                                     completion:nil];
            
            [self.searchPatients removeAllObjects];
            [self.tableView endEditing:YES];
        } else {
            
            dispatch_async_main(^{
                [SVProgressHUD showWithStatus:@"Loading"];
            });
            
            cell.searchButton.hidden = YES;
            
            if (self.searchingResultsArray.count > 0) {
                [self.searchingResultsArray removeAllObjects];
            }
            
            void(^createSearchingDict)(NSString *searchText, NSString *titleText) = ^(NSString *searchText, NSString *titleText) {
                
                NSMutableDictionary *serchingDict = [[NSMutableDictionary alloc] init];
                [serchingDict setObject:searchText forKey:kKeySearchText];
                [serchingDict setObject:titleText forKey:kKeyTitleText];
                [self.searchingResultsArray addObject:serchingDict];
            };
            
            BOOL isFillLastName = [cell isFillSearchTextFieldWithTag:cell.lastNameTextField.tag];
            BOOL isFillFirstName = [cell isFillSearchTextFieldWithTag:cell.firstNameTextField.tag];
            BOOL isFillDateOfBirth = [cell isFillSearchTextFieldWithTag:cell.dateOfBirthTextField.tag];
            BOOL isFillMRN = [cell isFillSearchTextFieldWithTag:cell.mrnTextField.tag];
            
            if (isFillLastName) {
                createSearchingDict(lastName, @"Last Name");
            }
            if (isFillFirstName) {
                createSearchingDict(firstName, @"First Name");
            }
            if (isFillDateOfBirth) {
                createSearchingDict(dateOfBirth, @"DOB");
            }
            if (isFillMRN) {
                createSearchingDict(mrn, @"MRN");
            }
            
            self.searchingResults = validSearch;
            [self configureHeightForHeaderSearching];
            
            NSDateFormatter *dateFormater = [[NSDateFormatter alloc] init];
            [dateFormater setDateFormat:@"MM/dd/yyyy"];
            
            NSDate *date = [dateFormater dateFromString:dateOfBirth];
            [dateFormater setDateFormat:@"yyyy-MM-dd"];
            dateOfBirth =[dateFormater stringFromDate:date];
            
            SearchPatientsServiceQuery *query = [[SearchPatientsServiceQuery alloc] init];
            query.qliqStorQliqId = self.qliqSTORQliqId;
            query.searchUuid = [[NSUUID UUID] UUIDString];
            query.firstName = firstName;
            query.lastName = lastName;
            query.dob = dateOfBirth; // must be: yyyy-MM-dd
            query.mrn = mrn;
            
            __weak SearchPatientsViewController *weakSelf = self;
            [self.service call:query page:1 perPage:20 withCompletition:^(CompletitionStatus status, id resultArg, NSError *error) {
                
                dispatch_async_main(^{
                    [SVProgressHUD dismiss];
                });
                
                if (status == CompletitionStatusSuccess) {
                    
                    self.isSearch = YES;
                    
                    [self.totalPatients removeAllObjects];
                    
                    SearchPatientsServiceResult *result = (SearchPatientsServiceResult *)resultArg;
                    
                    if (result.patients.count != 0) {
    
                        for (NSUInteger i = 0; i < result.patients.count; ++i) {
                            FhirPatient *patient = [result.patients objectAtIndex:i];
                            NSLog(@"patient: %@ %@", patient.firstName, patient.lastName);
                            [self.totalPatients addObject:patient];
                            
                            if (i <= 19 ) {
                                [self.searchPatients addObject:patient];
                            }
                        }
                        cell.searchButton.hidden = YES;
                    }
                    else {
                        self.isSearch = NO;
                        cell.searchButton.hidden = NO;
                        self.searchingResults = NO;
                        [self.tableView endEditing:YES];
                    }

                    self.totalPatientCount = result.totalCount;
                    self.emrSourceQliqId = result.emrSourceQliqId;
                    self.emrSourceDeviceUuid = result.emrSourceDeviceUuid;
                    self.emrSourcePublicKey = result.emrSourcePublicKey;
                    
                    [weakSelf configFooterView];
                    [weakSelf.tableView reloadData];
                } else {
                    // Error
                    
                    [AlertController showAlertWithTitle:QliqLocalizedString(@"1072-TextWarning")
                                                message:error.localizedDescription
                                            buttonTitle:nil
                                      cancelButtonTitle:QliqLocalizedString(@"1-ButtonOk")
                                             completion:nil];
                    
                    self.isSearch = NO;
                    cell.searchButton.hidden = NO;
                    [self.searchPatients removeAllObjects];
                    self.emrSourceQliqId = nil;
                    self.emrSourceDeviceUuid = nil;
                    self.emrSourcePublicKey = nil;
                    [self.tableView endEditing:YES];
                }
            } withIsCancelled:^BOOL{
                // Cancel response processing if the view controller is already destroyed
                SearchPatientsViewController *strongSelf = weakSelf;
                return (strongSelf == nil);
            }];
        }
    }
}

- (void)onMoreResults:(UIButton *)button {
    
    if (self.totalPatientCount > self.totalPatients.count) {
        
        if (self.totalPatientCount > 20) {
            [self getSearchPatientsServiceResultWithPage:2];
        }
        else if (self.totalPatientCount > 40) {
            [self getSearchPatientsServiceResultWithPage:3];
        }
        
        [self configFooterView];
        [self.tableView reloadData];
    }
}

- (void)onRefineSearchAction:(UIButton *)button {
    
    self.isSearch = NO;
    self.searchingResults = NO;
    SearchPatientsTableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    cell.searchButton.hidden = NO;
    [self configFooterView];
    [self.tableView reloadData];
}


#pragma mark - Delegate Methods -
#pragma mark * TableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return TableCellTypeCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;
    
    switch (section) {
        case TableCellTypeSearchPatients: {
            count = 1;
            break;
        }
        case TableCellTypePatients: {
            if (self.totalPatients.count != 0) {
                count = self.totalPatients.count;
            }
            break;
        }
        default:
            break;
    }
    return count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat cellHeight = kValueDefaultCellHeight;
    
    switch (indexPath.section)
    {
        case TableCellTypeSearchPatients: {
            if (self.isSearch) {
                cellHeight = 0.f;
            }
            else {
                cellHeight = 4 * (kValueHeightTextField + kValueTopTextField) + 3 * kValueMinBottomTextField + kValueDefaultCellHeight;
            }
            break;
        }
        case TableCellTypePatients: {
            if (self.totalPatients.count > 0) {
                cellHeight = kValueDefaultPatientsCellHeight;
            }
            break;
        }
        default:
            break;
    }
    
    return cellHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat height = 0;
        
        switch (section)
        {
            case TableCellTypeSearchPatients: {
                if (self.isSearch) {
                    height = 0.f;
                }
                break;
            }
            case TableCellTypePatients: {
                if (self.searchingResults) {
                    height = self.heightHeaderSearching;
                }
                else {
                    height = kValueHeightForHeaderInSectionDefault;
                }
                break;
            }
            default:
                break;
        }
    
    return height;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [self configureHeaderView];
    return headerView;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell respondsToSelector:@selector(setSeparatorInset:)])
        [cell setSeparatorInset:UIEdgeInsetsZero];
    
    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)])
        [cell setPreservesSuperviewLayoutMargins:NO];
    
    if ([cell respondsToSelector:@selector(setLayoutMargins:)])
        [cell setLayoutMargins:UIEdgeInsetsZero];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case TableCellTypeSearchPatients: {
            
            static NSString *searchPatientsCellID = @"SearchPatientsTableViewCell_ID";
            
            SearchPatientsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:searchPatientsCellID];
            
            if(!cell) {
                cell = [tableView dequeueReusableCellWithIdentifier:searchPatientsCellID];
            }
            
            [cell.searchButton addTarget:self action:@selector(onSearchAction:) forControlEvents:UIControlEventTouchUpInside];

            cell.lastNameTextField.hidden = self.isSearch;
            cell.firstNameTextField.hidden = self.isSearch;
            cell.dateOfBirthTextField.hidden = self.isSearch;
            cell.mrnTextField.hidden = self.isSearch;
            cell.searchFieldImageFrameHeightConstraint.constant = self.isSearch ? 0.f : 27.f;

            return cell;
            break;
        }
        case TableCellTypePatients: {
            
            static NSString *patientsCellID = @"PatientsTableViewCell_ID";
            
            PatientsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:patientsCellID];
            
            if (self.totalPatients.count != 0) {
                FhirPatient *patient = [self.totalPatients objectAtIndex:indexPath.row];
                cell.patientInfoLabel.text = patient.displayName;
            }
            return cell;
            break;
        }
            
        default: {
            
            static NSString *searchPatientsCellID = @"SearchPatientsTableViewCell_ID";
            
            SearchPatientsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:searchPatientsCellID];
            
            if(!cell) {
                UINib *nib = [UINib nibWithNibName:@"SearchPatientsTableViewCell" bundle:nil];
                
                [tableView registerNib:nib forCellReuseIdentifier:searchPatientsCellID];
                
                cell = [tableView dequeueReusableCellWithIdentifier:searchPatientsCellID];
            }
            
            return cell;
            break;
        }
    }
}

- (void) configFooterView {
    
    CGFloat buttonWidth = 200.f;
    CGFloat buttonHeight = 30.f;
    if (self.loadResultsButton == nil) {
        
        self.loadResultsButton = [[UIButton alloc] init];
        self.loadResultsButton.layer.backgroundColor = RGBa(24, 122, 181, 1).CGColor;
        [self.loadResultsButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.loadResultsButton.titleLabel.font = [UIFont systemFontOfSize:15.f];
        [self.loadResultsButton setTitle:QliqLocalizedString(@"2430-TitleLoadMoreResults") forState:UIControlStateNormal];
        [self.loadResultsButton addTarget:self action:@selector(onMoreResults:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    if (self.totalPatientCount > self.totalPatients.count)
    {
        self.loadResultsButton.frame = CGRectMake(0.f + (self.tableView.frame.size.width - buttonWidth/2), 0.f + (50.f - buttonHeight/2), buttonWidth, buttonHeight);
        [self.tableView.tableFooterView addSubview:self.loadResultsButton];
    }
}

- (void) handleUploadToEmrCompleted:(CompletitionStatus) status error:(NSError *)error
{
    dispatch_async_main(^{
        [SVProgressHUD dismiss];
    });
    
    if (error) {
        [AlertController showAlertWithTitle:QliqLocalizedString(@"1072-TextWarning")
                                    message:error.localizedDescription
                                buttonTitle:nil
                          cancelButtonTitle:QliqLocalizedString(@"1-ButtonOk")
                                 completion:^(NSUInteger buttonIndex) {
                                     [self onBackAction:nil];
                                 }];
    } else {
        [AlertController showAlertWithTitle:@"Info"
                                    message:@"The upload was sent to server"
                                buttonTitle:nil
                          cancelButtonTitle:QliqLocalizedString(@"1-ButtonOk")
                                 completion:^(NSUInteger buttonIndex) {
                                     [self onBackAction:nil];
                                 }];
    }
}

- (void) uploadConversation:(Conversation *)conversation messages:(NSArray *)messages patient:(FhirPatient *)patient
{
    // This method is expected to be called on UI thread
    dispatch_async_main(^{
        [SVProgressHUD showWithStatus:@"Uploading"];
    });
    
    EmrUploadParams *uploadTarget = [UploadToEmrService uploadParamsForPatient:patient];
    if (self.uploadToEmrService == nil) {
        self.uploadToEmrService = [[UploadToEmrService alloc] init];
    }
    if (self.emrSourceQliqId.length > 0) {
        uploadTarget.qliqStorQliqId = self.emrSourceQliqId;
    }
    if (self.emrSourceDeviceUuid.length > 0) {
        uploadTarget.qliqStorDeviceUuid = self.emrSourceDeviceUuid;
    }
    [self.uploadToEmrService uploadConversation:conversation.uuid to:uploadTarget publicKey:self.emrSourcePublicKey withCompletition:^(CompletitionStatus status, id result, NSError *error) {
        [self handleUploadToEmrCompleted:status error:error];
    } withIsCancelled:nil];
}

- (void) uploadMediaFile:(MediaFile *)mediaFile patient:(FhirPatient *)patient
{
    // This method is expected to be called on UI thread
    dispatch_async_main(^{
        [SVProgressHUD showWithStatus:@"Uploading"];
    });
    
    EmrUploadParams *uploadTarget = [UploadToEmrService uploadParamsForPatient:patient];
    if (self.emrSourceQliqId.length > 0) {
        uploadTarget.qliqStorQliqId = self.emrSourceQliqId;
    }
    if (self.emrSourceDeviceUuid.length > 0) {
        uploadTarget.qliqStorDeviceUuid = self.emrSourceDeviceUuid;
    }
    NSString *thumbnail = [mediaFile base64EncodedThumbnail];
    
    [self.uploadToEmrService uploadFile:mediaFile.decryptedPath displayFileName:mediaFile.fileName thumbnail:thumbnail to:uploadTarget publicKey:self.emrSourcePublicKey withCompletition:^(CompletitionStatus status, id result, NSError *error) {
        [self handleUploadToEmrCompleted:status error:error];
    } withIsCancelled:nil];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case TableCellTypePatients: {
            if (self.totalPatients.count > 0) {
                FhirPatient *patient = [self.totalPatients objectAtIndex:indexPath.row];
                
                if (self.conversation) {
                    // Since the UI to select messages is not ready yet, we always upload complete conversation
                    // [self showUploadOptionsForPatient:patient];
                    [self uploadConversation:self.conversation messages:nil patient:patient];
                }
                else if (self.mediaFile) {
                    EMRUploadViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([EMRUploadViewController class])];
                    controller.patient = patient;
                    controller.mediaFile = self.mediaFile;
                    controller.emrTargetQliqId = self.qliqSTORQliqId;
//                    controller.emrTargetQliqId = self.emrSourceQliqId;
                    controller.emrTargetDeviceUuid = self.emrSourceDeviceUuid;
                    controller.emrTargetPublicKey = self.emrSourcePublicKey;
                    [self.navigationController pushViewController:controller animated:YES];
                }
            }
        }
    }
}

@end

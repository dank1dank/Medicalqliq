//
//  UploadDetailView.m
//  qliq
//
//  Created by Valerii Lider on 04/26/2017.
//
//

#import "UploadDetailView.h"
#import "UploadDetailTableViewCell.h"

#import "MediaFileUploadDBService.h"
#import "UIDevice-Hardware.h"

#define kValueDefaultHeaderHeight 24.f
#define kValueDefaultCellHeight   36.f
#define kValueDefaultViewHeight   135.f

@interface UploadDetailView () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *events;

@end

@implementation UploadDetailView

@synthesize tableView;

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect {
 // Drawing code

 }
 */

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code
        self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0.f, 0.f, [UIScreen mainScreen].bounds.size.width, kValueDefaultViewHeight)];
        self.tableView.showsVerticalScrollIndicator = YES;
        self.tableView.showsHorizontalScrollIndicator = YES;
        self.tableView.bounces = YES;
        self.tableView.backgroundColor = [UIColor whiteColor];
        self.tableView.dataSource = self;
        self.tableView.delegate = self;
        self.tableView.scrollEnabled = YES;
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        self.backgroundColor = [UIColor whiteColor];
        [self addSubview:self.tableView];
        [self setFrame:self.tableView.bounds];
        [self setUserInteractionEnabled:YES];

        static NSString* kMessageHistoryCell = @"UploadDetailCell_ID";
        UINib *nib = [UINib nibWithNibName:@"UploadDetailTableViewCell" bundle:nil];
        [self.tableView registerNib:nib forCellReuseIdentifier:kMessageHistoryCell];

        self.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (BOOL)uploadHasEvents {

    BOOL isEvents = NO;
    self.events = [MediaFileUploadEventDBService getWithUploadId:self.upload.databaseId];
    if (self.events.count > 0) {
        isEvents = YES;
    }
    return isEvents;
}

#pragma mark - Private -

- (void)loadUploadEventsForUploadFile:(MediaFileUpload *)upload {

    self.upload = upload;
    self.events = [MediaFileUploadEventDBService getWithUploadId:self.upload.databaseId];
//    [self.events sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]]];

    [self.events sortUsingComparator:^NSComparisonResult(MediaFileUploadEvent *obj1, MediaFileUploadEvent *obj2) {
        NSNumber *time1 = [NSNumber numberWithInteger:obj1.timestamp];
        NSNumber *time2 = [NSNumber numberWithInteger:obj2.timestamp];

        NSString *eventText1 = obj1.eventString;
        NSString *eventText2 = obj2.eventString;

        NSComparisonResult result = [time2 compare:time1];
        switch (result) {
            case NSOrderedSame:
                result = [eventText2 compare:eventText1];
                break;
            case NSOrderedAscending:
                result = [time2 compare:time1];
                break;
            case NSOrderedDescending:
                result = [time2 compare:time1];
                break;
            default:
                break;
        }
        return result;
    }];

//        return [obj2.mediaFile.timestampToUiText compare:obj1.mediaFile.timestampToUiText];
}

- (UIViewController *)currentTopViewController
{
    UIViewController * controller = [[appDelegate window] rootViewController];
    while (controller.presentedViewController) {
        controller = controller.presentedViewController;
    }

    if ([controller isKindOfClass:[UINavigationController class]])
    {
        controller = ((UINavigationController *)controller).viewControllers.lastObject;
    }

    return controller;
}

- (void)showAlertWithStatusOfMessage:(NSString *)statusMessage {

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:QliqLocalizedString(@"1202-TextInfo") message:statusMessage preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"1-ButtonOk", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [alert viewDidDisappear:YES];
    }];

    [alert addAction:ok];
    [[self currentTopViewController] presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Delegates -

#pragma mark * UITabelView Delegate/DataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.events.count;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* kMessageHistoryCell = @"UploadDetailCell_ID";
    UploadDetailTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kMessageHistoryCell];

    if(!cell) {
        cell = [[UploadDetailTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:kMessageHistoryCell];
    }

    MediaFileUploadEvent *event = [self.events objectAtIndex:indexPath.row];
    if (event) {
        NSString *evenTypeStr = [MediaFileUploadEvent typeToString:event.type forShareType:self.upload.shareType];
        [cell setCellWithMessage:event.message withEvent:evenTypeStr withTime:event.timestamp];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MediaFileUploadEvent *event = [self.events objectAtIndex:indexPath.row];
    if (event.message && event.message.length > 0) {
        [self showAlertWithStatusOfMessage:event.message];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat height = kValueDefaultHeaderHeight;
    return height;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat cellHeight = kValueDefaultCellHeight;
    return cellHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [[UIView alloc] init];
    headerView.backgroundColor = RGBa(103, 103, 103, 1.0f);

    //Add Content HeaderView
    {
        NSString *titleHeader      = @"";
        NSString *description      = @"";
        NSString *fullHeaderTittle = @"";

        titleHeader      = QliqLocalizedString(@"2457-TitleFileName:");
        description      = self.upload.mediaFile.fileName;
        fullHeaderTittle = [NSString stringWithFormat:@"%@ %@", titleHeader, description];

        UIFont *titleHeaderFont    = [UIFont systemFontOfSize:14.f];
        UIFont *descriptionFont    = [UIFont systemFontOfSize:16.f];
        CGFloat offset             = 20.f;
        
        //Need to add offset for 'File name' label for iPhoneX in landscape orientation
        isIPhoneX{
            if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
                offset = 114.f;
            }
        }

        UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(offset/2, 0, self.tableView.bounds.size.width - offset, kValueDefaultHeaderHeight)];
        headerLabel.text            = fullHeaderTittle;
        headerLabel.textColor       = [UIColor whiteColor];
        headerLabel.backgroundColor = [UIColor clearColor];
        headerLabel.font            = titleHeaderFont;
        headerLabel.adjustsFontSizeToFitWidth = YES;

        NSRange range = NSMakeRange( [titleHeader length], [fullHeaderTittle length] - [titleHeader length]);
        NSMutableAttributedString *attributeString = [[NSMutableAttributedString alloc] initWithAttributedString:headerLabel.attributedText];
        [attributeString addAttribute:NSFontAttributeName value:descriptionFont range:range];

        headerLabel.attributedText  = attributeString;

        [headerLabel setMinimumScaleFactor:8.f/[UIFont labelFontSize]];
        [headerView addSubview:headerLabel];
    }
    return headerView;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableView setSeparatorInset:UIEdgeInsetsZero];
    }

    if ([self.tableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.tableView setLayoutMargins:UIEdgeInsetsZero];
    }

    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

@end

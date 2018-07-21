//
//  DetailOnCallTableViewCell.m
//  qliq
//
//  Created by Valerii Lider on 07/09/15.
//
//

#import "DetailOnCallTableViewCell.h"
#import "StatusView.h"
#import "OnCallGroup.h"

#define kProfessionLabelHeight 14.f
#define kPresenceLabelHeight 14.f
#define kPresenceLableTralling 2.f
#define kProfessionLableTralling 2.f

@interface DetailOnCallTableViewCell ()

@property (weak, nonatomic) IBOutlet UILabel *startDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *overnightLabel;
@property (weak, nonatomic) IBOutlet UILabel *endDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *typeLabel;
@property (weak, nonatomic) IBOutlet UIView *timeView;
@property (weak, nonatomic) IBOutlet UIView *separateView;
@property (weak, nonatomic) IBOutlet UIView *detailContentView;

@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UIImageView *arrowImageView;

@property (weak, nonatomic) IBOutlet StatusView *statusView;

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *professionLabel;
@property (weak, nonatomic) IBOutlet UILabel *presenceLabel;
@property (weak, nonatomic) IBOutlet UILabel *onCallLabel;

@property (weak, nonatomic) IBOutlet UIButton *notesButton;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *professionLabelHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *presenceLabelHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *separateViewWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *timeViewWidthConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *notesButtonWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *presenceLabelTrallingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *professionLabelTrallingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *startDateBottomConstraint;

@end

@implementation DetailOnCallTableViewCell

- (void)dealloc
{
    self.startDateLabel = nil;
    self.endDateLabel = nil;
    self.typeLabel = nil;
    self.avatarImageView = nil;
    self.statusView = nil;
    self.nameLabel = nil;
    self.professionLabel = nil;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self layoutIfNeeded];
        
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.avatarImageView.layer.cornerRadius = self.avatarImageView.frame.size.width/2.f;
    self.avatarImageView.layer.masksToBounds = YES;
    
    self.startDateLabel.numberOfLines = 1;
    self.startDateLabel.minimumScaleFactor = 11.f / self.startDateLabel.font.pointSize;
    self.startDateLabel.adjustsFontSizeToFitWidth = YES;
    
    self.endDateLabel.numberOfLines = 1;
    self.endDateLabel.minimumScaleFactor = 11.f / self.endDateLabel.font.pointSize;
    self.endDateLabel.adjustsFontSizeToFitWidth = YES;
    
    [self prepareForReuse];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.timeView.backgroundColor = [UIColor whiteColor];
    self.separateView.hidden = NO;
    
    self.startDateLabel.text = @"";
    self.startDateLabel.textColor = [UIColor darkGrayColor];
    
    self.overnightLabel.text = @"-";
    self.overnightLabel.textColor = [UIColor darkGrayColor];
    
    self.endDateLabel.text = @"";
    self.endDateLabel.textColor = [UIColor darkGrayColor];
    
    self.typeLabel.text = @"";
    self.typeLabel.textColor = [UIColor darkGrayColor];
    
    self.nameLabel.text = @"";
    
    self.professionLabel.text = @"";
    
    self.presenceLabel.text = @"";
    self.presenceLabel.textColor = [UIColor lightGrayColor];
    
    self.avatarImageView.image = nil;
    
//    self.professionLabelHeightConstraint.constant = 0;
//    self.presenceLabelHeightConstraint.constant = 0;
    
    self.notesButton.hidden = YES;
    self.notesButton.layer.masksToBounds = YES;
    self.notesButton.clipsToBounds = YES;
    self.notesButton.layer.cornerRadius = 10.f;
    self.notesButton.layer.borderWidth = 1.f;
    self.notesButton.layer.borderColor = [kColorDarkBlue CGColor];
    [self.notesButton setTitle:QliqLocalizedString(@"2354-TitleNotes") forState:UIControlStateNormal];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - Public

- (void)configureCellWithQliqUserWithHours:(QliqUserWithOnCallHours *)uh withTodayDate:(NSDate *)todayDate withSelectedDate:(NSDate *)selectedDate withNotes:(OnCallMemberNotes *)notes isOnCallUsersWithHours:(BOOL)isOnCallUsersWithHours
{
    QliqUser *user = uh.user;
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd "];

    NSDate *nowTime = [NSDate date];

    BOOL isToday = [self date:todayDate
             isTheSameDayThan:selectedDate];

    NSArray *hours = [user.specialty componentsSeparatedByString:@"-"];
    self.startDateLabel.text = hours[0];
    self.endDateLabel.text = hours[1];
    
    if (uh.isFullDay) {
        self.overnightLabel.text = @"fullday";
    } else if (uh.isOvernight) {
        self.overnightLabel.text = @"overnight";
    }

    //Its work time
    if (uh && isToday && [uh isActiveOnDate:todayDate]) {
        
        UIColor *color = [UIColor whiteColor];
        
        self.startDateLabel.textColor = color;
        self.overnightLabel.textColor = color;
        self.endDateLabel.textColor = color;
        self.typeLabel.textColor = color;
        self.timeView.backgroundColor = kColorDarkBlue;
        
        
        self.separateView.hidden = YES;
        self.presenceLabel.hidden = NO;
        self.nameLabel.hidden = NO;
    }
    
    if (user) {
        
        //Primary/backup //When get "shiftForDate:" put type (primary/backup) to taxonomyCode
        self.typeLabel.text = user.taxonomyCode;
        
        //UserName
        self.nameLabel.textColor = [UIColor blackColor];
        self.nameLabel.text = [user nameDescription];
        
        //UserProffesion
        self.professionLabel.text = user.profession;
        //    if (self.professionLabel.text.length > 0) {
        //        self.professionLabelHeightConstraint.constant = kProfessionLabelHeight;
        //    }
        
        if ([user.qliqId isEqualToString:[UserSessionService currentUserSession].user.qliqId]) {
            user = [UserSessionService currentUserSession].user;
            user.presenceStatus = [QliqUser presenceStatusFromString:[UserSessionService currentUserSession].userSettings.presenceSettings.currentPresenceType];
            user.presenceMessage = [[QliqAvatar sharedInstance] getSelfPresenceMessage];
        }
        
        
        //UserPresence
        self.presenceLabel.text = [[QliqAvatar sharedInstance] getPrecenseStatusMessage:user];
        self.presenceLabel.textColor = [[QliqAvatar sharedInstance] colorShadowForPresenceStatus:user.presenceStatus];
        //    if (self.presenceLabel.text.length > 0) {
        //        self.presenceLabelHeightConstraint.constant = kPresenceLabelHeight;
        //    }
        
        
        //Avatar
        self.avatarImageView.hidden = NO;
        self.avatarImageView.image = [[QliqAvatar sharedInstance] getAvatarForItem:user withTitle:nil];
        
        //User Status indicator
        self.statusView.hidden = NO;
        self.statusView.statusColorView.backgroundColor = [[QliqAvatar sharedInstance] colorForPresenceStatus:user.presenceStatus];
        
        //Notes
        if (notes) {
            self.notesButton.hidden = NO;
        }
        
        if (self.notesButton.hidden) {
            self.presenceLabelTrallingConstraint.constant = - self.notesButtonWidthConstraint.constant;
            self.professionLabelTrallingConstraint.constant = - self.notesButtonWidthConstraint.constant;
        } else {
            self.presenceLabelTrallingConstraint.constant = kPresenceLableTralling;
            self.professionLabelTrallingConstraint.constant = kProfessionLableTralling;
        }
        
        self.arrowImageView.hidden = NO;
        self.nameLabel.hidden = NO;
        self.onCallLabel.hidden = YES;
        
        //Configure constraint for startDateLabel
        self.startDateBottomConstraint.constant = - 2.f;
    }
    else {
       
        self.startDateLabel.textColor = [UIColor whiteColor];
        self.onCallLabel.textColor = [UIColor redColor];
        self.timeView.backgroundColor = kColorDarkBlue;
        
        self.onCallLabel.hidden = NO;
        if (isOnCallUsersWithHours) {
            formatter.timeStyle = NSDateFormatterShortStyle;
            formatter.doesRelativeDateFormatting    = YES;
            self.startDateLabel.text = [formatter stringFromDate:nowTime];
        }
        else {
            self.startDateLabel.text = @"24 hours";
        }
        self.onCallLabel.text = QliqLocalizedString(@"2424-TitleNoOneOnCall");
        
        self.nameLabel.hidden = YES;
        self.separateView.hidden = YES;
        self.avatarImageView.hidden = YES;
        self.presenceLabel.hidden = YES;
        self.statusView.hidden = YES;
        self.arrowImageView.hidden = YES;
        
        //Configure constraints
        self.startDateBottomConstraint.constant = - 20.f;
    }
    
    [self layoutIfNeeded];
}


#pragma mark - Private

- (IBAction)onNotesButton:(id)sender {
     DDLogSupport(@"\nNotesButton ptressed\n");
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(onNotesButtonPressedInCell:)]) {
        [self.delegate onNotesButtonPressedInCell:self];
    }
}

- (BOOL)date:(NSDate *)dateA isTheSameDayThan:(NSDate *)dateB
{
    NSCalendar *calendar;
#ifdef __IPHONE_8_0
    calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
#else
    calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
#endif
    calendar.timeZone = [NSTimeZone localTimeZone];
    calendar.locale = [NSLocale currentLocale];


    NSDateComponents *componentsA = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:dateA];
    NSDateComponents *componentsB = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:dateB];
    
    return componentsA.year == componentsB.year && componentsA.month == componentsB.month && componentsA.day == componentsB.day;
}

@end

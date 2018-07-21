//
//  DetailNotesTableViewCell.m
//  qliq
//
//  Created by Valerii Lider on 6/29/16.
//
//

#import "DetailNotesTableViewCell.h"

// Notes Box View Constraints
#define kValueNotesBoxViewTop                           5.f
#define kValueNotesBoxViewBot                           5.f
#define kValueNotesBoxViewLeading                       20.f
#define kValueNotesBoxViewTralling                      20.f
// Notes Box View Layer
#define kValueNotesBoxViewBorderWidth                   0.75f
#define kValueNotesBoxViewCornerRadius                  5.f

// Notes TextView Constraints
#define kValueNotesTextViewTop                          10.f
#define kValueNotesTextViewBot                          0.f
#define kValueNotesTextViewLeading                      10.f
#define kValueNotesTextViewTralling                     10.f
// Notes TextView text content insets
#define kValueNotesTextViewTopEdgeInset                 10.f
#define kValueNotesTextViewBotEdgeInset                 10.f
#define kValueNotesTextViewLeftEdgeInset                10.f
#define kValueNotesTextViewRightEdgeInset               10.f

// Notes Title Lable
#define kValueNotesTitleLableBot                        2.f
#define kValueNotesTitleLableHeight                     18.f



@implementation DetailNotesTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    {
        {
            // Notes Box View Properties Set Up
            {
                self.noteBoxView.layer.borderWidth = kValueNotesBoxViewBorderWidth;
                self.noteBoxView.layer.borderColor = [RGBa(3.f, 120.f, 173.f, 1.f) CGColor];
                self.noteBoxView.layer.cornerRadius = kValueNotesBoxViewCornerRadius;
            }
        }
        {
            // Notes TextView Properties Set Up
            {
                UIFont *font =[UIFont systemFontOfSize:16.0];
                [self.notesTextView setFont:font];
                [self.notesTextView setTextColor:[UIColor blackColor]];
                
            }
            
            [self.notesTextView setTextContainerInset:UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0)];
            [self.notesTextView setScrollEnabled:NO];
        }
        
        // Notes Box View Constraints
        {
            self.noteBoxViewTopConstraint.constant = kValueNotesBoxViewTop;
            self.noteBoxViewBotConstraint.constant = kValueNotesBoxViewBot;
            self.noteBoxViewLeadingConstraint.constant = kValueNotesBoxViewLeading;
            self.noteBoxViewTrallingConstraint.constant = kValueNotesBoxViewLeading;
        }
        // Notes TextView Constraints
        {
            self.notesTextViewTopConstraint.constant = kValueNotesTextViewTop;
            self.notesTextViewBotConstraint.constant = kValueNotesTextViewBot;
            self.notesTextViewLeadingConstraint.constant = kValueNotesTextViewLeading;
            self.notesTextViewTrallingConstraint.constant = kValueNotesTextViewLeading;
        }
        // Notes Title Lable
        {
//            self.titleLableHeightConstraint.constant = kValueNotesTitleLableHeight;
            self.titleLableHeightConstraint.constant = 0;
//            self.titleLableBotConstraint.constant = kValueNotesTitleLableBot;
            self.titleLableBotConstraint.constant = 0;
        }
        
        [self layoutSubviews];
    }
    [self prepareForReuse];
}

- (void)prepareForReuse {
    [super prepareForReuse];

    {
//        self.title.text = @"";
//        self.title.hidden = YES;

        self.notesTextView.hidden = YES;
        self.notesTextView.text = @"";
        self.notesTextView.attributedText = [DetailNotesTableViewCell getAttrStringWithText:@""];
    }
}

+ (CGFloat)getHeightForNotesCellWithContent:(NSArray *)content
{
    CGFloat height = 0.0;
    
    CGFloat maxNotesTextViewWidth = [DetailNotesTableViewCell getMaxWidthForNotesTextView];
    
        NSString *text = content[1];
    
        CGRect suggestedRect = [text boundingRectWithSize:CGSizeMake(maxNotesTextViewWidth, CGFLOAT_MAX)
                                                  options:(NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin)
                                               attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:16.0]}
                                                  context:nil];
    
        CGSize returnSize = CGSizeMake(ceilf(CGRectGetWidth(suggestedRect)), ceilf(CGRectGetHeight(suggestedRect)));
    
    height = kValueNotesBoxViewTop +
    kValueNotesBoxViewBorderWidth +
    kValueNotesTextViewTop +
    returnSize.height +
    kValueNotesTextViewBot +
//    kValueNotesTitleLableHeight +
//    kValueNotesTitleLableBot +
    kValueNotesBoxViewBorderWidth +
    kValueNotesBoxViewBot + 10.f;
    
    return height;
}

+ (CGFloat)getMaxWidthForNotesTextView
{
    CGRect rect = CGRectZero;
    CGRect bounds = [UIScreen mainScreen].bounds;
    CGFloat maxWidthBubbleMessage = 0.0;
    
    if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        rect = CGRectMake(0, 0, MAX(bounds.size.height, bounds.size.width), MIN(bounds.size.height, bounds.size.width));
    }
    if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation))
    {
        rect = CGRectMake(0, 0, MIN(bounds.size.height, bounds.size.width), MAX(bounds.size.height, bounds.size.width));
    }
    
    maxWidthBubbleMessage = CGRectGetWidth(rect) -
    kValueNotesBoxViewLeading -
    kValueNotesBoxViewBorderWidth -
    kValueNotesTextViewLeading -
    kValueNotesTextViewTralling -
    kValueNotesBoxViewBorderWidth -
    kValueNotesBoxViewTralling - 10.f;
    
    return maxWidthBubbleMessage;
}

+ (NSAttributedString *)getAttrStringWithText:(NSString *)text {
    
    UIFont *font =[UIFont systemFontOfSize:16.0];
    
    NSMutableParagraphStyle *style =  [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    style.alignment = NSTextAlignmentLeft;
    
    NSAttributedString *attrText = [[NSAttributedString alloc] initWithString:text attributes:@{NSFontAttributeName : font,
                                                                                                NSParagraphStyleAttributeName : style}];
    
    return attrText;
}

- (void)configureNotesCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath withContent:(NSArray *)content
{
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
//    self.title.text         = content[0];
//    self.title.hidden = NO;
    
    self.notesTextView.text = content[1];
    self.notesTextView.hidden = NO;
}


@end

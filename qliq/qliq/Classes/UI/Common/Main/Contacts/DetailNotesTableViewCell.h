//
//  DetailNotesTableViewCell.h
//  qliq
//
//  Created by Valerii Lider on 6/29/16.
//
//

#import <UIKit/UIKit.h>


@interface DetailNotesTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIView *noteBoxView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *noteBoxViewBotConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *noteBoxViewTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *noteBoxViewLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *noteBoxViewTrallingConstraint;

@property (weak, nonatomic) IBOutlet UITextView *notesTextView;
@property (weak, nonatomic) IBOutlet UILabel *title;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *notesTextViewBotConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *notesTextViewTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *notesTextViewLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *notesTextViewTrallingConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *titleLableHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *titleLableBotConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *titleLableLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *titleLableTrallingConstraint;

+ (CGFloat)getHeightForNotesCellWithContent:(NSArray *)content;
- (void)configureNotesCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath withContent:(NSArray *)content;

@end

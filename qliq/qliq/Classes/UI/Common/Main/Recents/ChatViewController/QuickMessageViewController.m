//
//  QuickMessageViewController.m
//  qliq
//
//  Created by Valerii Lider on 9/26/14.
//
//

#import "QuickMessageViewController.h"

#import "QuickMessage.h"
#import "QuickMessageCell.h"
#import "EditableQuickMessageCell.h"

#define kAddQuickMessageCellSection 0

#define kValueDefaultCellHeight 50.f
#define kDefaultCellLabelFont [UIFont boldSystemFontOfSize:15.0];

@interface QuickMessageViewController ()
<
UISearchBarDelegate,
UITextFieldDelegate,
UITableViewDelegate,
UITableViewDataSource,
EditableQuickMessageCellDelegate
>

/**
 IBOutlet
 */
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *editButton;

/* Constraints */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomTableConstraint;

/**
 UI
 */
@property (nonatomic, strong) EditableQuickMessageCell *currentEditCell;

/**
 Data
 */
@property (nonatomic,assign) BOOL isContentInset;
@property (nonatomic,assign) BOOL isSearching;

@property (nonatomic,strong) QuickMessage *selectedQuickMessageObj;
@property (nonatomic,strong) NSMutableArray *quickMessageArray;
@property (nonatomic,strong) NSMutableArray *searchArray;

@end

@implementation QuickMessageViewController

- (void)configureDefaultText {
    [self.editButton setTitle:QliqLocalizedString(@"46-ButtonEdit") forState:UIControlStateNormal];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureDefaultText];
    
    //get the data to display
    self.quickMessageArray = [QuickMessage getQuickMessages];
    
    //SearchBar
    {
        self.searchArray = [[NSMutableArray alloc] initWithCapacity:self.quickMessageArray.count];
        self.searchBar.barStyle                 = 0;
        self.searchBar.translucent              = NO;
        self.searchBar.autocapitalizationType   = 0;
        self.searchBar.showsScopeBar            = NO;
        self.searchBar.tag                      = 2;
        self.searchBar.delegate                 = self;
    }
        
    //TableView
    {
        self.tableView.allowsSelectionDuringEditing = YES;
        self.tableView.delegate                     = self;
        self.tableView.dataSource                   = self;
        self.tableView.tag                          = 1;
        self.tableView.clipsToBounds                = YES;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    
    [self addKeyboardNotifications];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self removeKeyboardNotifications];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    self.navigationController.navigationBarHidden = NO;
}

#pragma mark - Notifications -

- (void)removeNotificationObserver
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)addKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeShown:) name:@"UIKeyboardWillShowNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:@"UIKeyboardWillHideNotification" object:nil];
}

- (void)removeKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIKeyboardWillShowNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIKeyboardWillHideNotification" object:nil];
}

- (void)keyboardWillBeShown:(NSNotification*)notification
{
    UIViewAnimationCurve curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue];
    UIViewAnimationOptions options = (curve << 16) | UIViewAnimationOptionBeginFromCurrentState;
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    CGSize keyboardSize = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    
    [UIView animateWithDuration:duration delay:0.0 options:options animations:^{
        
        CGFloat offset = keyboardSize.height;
        if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation))
            offset = keyboardSize.height;
        
        self.bottomTableConstraint.constant = offset;
        [self.view layoutIfNeeded];
        
    } completion:nil];
}

- (void)keyboardWillBeHidden:(NSNotification*)notification
{
    UIViewAnimationCurve curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue];
    UIViewAnimationOptions options = (curve << 16) | UIViewAnimationOptionBeginFromCurrentState;
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    [UIView animateWithDuration:duration delay:0.0 options:options  animations:^{
        
        self.bottomTableConstraint.constant = 0.f;
        [self.view layoutIfNeeded];
        
    } completion:nil];
}

#pragma mark - Private -

- (void)saveNewQuickMessage
{
    BOOL hasEditCell        = self.currentEditCell != nil;
    BOOL isEditCellEditing  = self.currentEditCell.editing;
    BOOL hasText            = self.currentEditCell.textField.text.length > 0;
    
    if (hasEditCell && isEditCellEditing && hasText)
    {
        self.currentEditCell.editing = NO;
        NSString *string = self.currentEditCell.textField.text;
        self.currentEditCell = nil;
        
        //save quick message;
        QuickMessage *newQuickMsg = [[QuickMessage alloc] init];
        newQuickMsg.message = string;
        newQuickMsg.displayOrder = 1 ;
        [QuickMessage addQuickMessage:newQuickMsg];
        
        for (QuickMessage* message in self.quickMessageArray)
        {
            message.displayOrder++;
            [QuickMessage updateQuickMessageOrder:message];
        }
        [self.quickMessageArray insertObject:newQuickMsg atIndex:0];
        //    [quickMessageArray removeAllObjects];
        //    [quickMessageArray addObjectsFromArray:[QuickMessage getQuickMessages]];
        [self.tableView reloadData];
    }
}

- (void)clickSelectQuickMessageDone:(id)sender
{
    NSIndexPath *indexPath = (NSIndexPath*)sender;
    QuickMessage *msg = nil;
    
    if(self.isSearching)
        msg = [self.searchArray objectAtIndex:indexPath.row];
    else
        msg = [self.quickMessageArray objectAtIndex:indexPath.row];
    
    [self.delegate quickMessageSelected:msg.message];
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (QuickMessage*)getQuickMessageAtIndexPath:(NSIndexPath*)indexPath
{
    QuickMessage *quickMessageObj = nil;
    
    if (self.isSearching)
        quickMessageObj = [self.searchArray objectAtIndex:indexPath.row];
    else
        quickMessageObj = [self.quickMessageArray objectAtIndex:indexPath.row];
    
    return quickMessageObj;
}

#pragma mark - Actions

#pragma mark  - * IBActions

- (IBAction)onBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onEdit:(id)sender
{
    [self.editButton setTitle:QliqLocalizedString(@"38-ButtonDone") forState:UIControlStateNormal];
    BOOL currenltyEditing = self.tableView.editing;
    
    [self.tableView setEditing:!currenltyEditing animated:NO];
    
    if (currenltyEditing){
        [self saveNewQuickMessage];
        [self.editButton setTitle:QliqLocalizedString(@"46-ButtonEdit") forState:UIControlStateNormal];
    }
    [self.tableView reloadData];
}

#pragma mark - Delegates -

#pragma mark * TableView Delegate

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kAddQuickMessageCellSection)
        return NO;
    
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL can = NO;
    
    if (tableView.editing)
    {
        if (indexPath.section != kAddQuickMessageCellSection)
            can = YES;
    }
    
    return can;
}

- (NSIndexPath*)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
    if( sourceIndexPath.section != proposedDestinationIndexPath.section )
    {
        return sourceIndexPath;
    }
    else
    {
        return proposedDestinationIndexPath;
    }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    NSUInteger fromRow = fromIndexPath.row;
    NSUInteger toRow = toIndexPath.row;
    QuickMessage *fromMessage = nil;
    //    QuickMessage *toMessage = nil;
    fromMessage = [self.quickMessageArray objectAtIndex:fromRow];
    //    toMessage = [quickMessageArray objectAtIndex:toRow];
    [self.quickMessageArray removeObjectAtIndex:fromRow];
    [self.quickMessageArray insertObject:fromMessage atIndex:toRow];
    
    /*
     NSInteger start = fromRow;
     NSInteger end = toRow;
     NSInteger i = 0;
     QuickMessage *message = nil;
     
     if (toRow < start)
     start = toRow;
     if (fromRow > end)
     end = fromRow;
     
     for (i = start; i <= end; i++) {
     message = [quickMessageArray objectAtIndex:i];
     if (i == fromRow)       // it's our initial cell, just set it to our final destination
     {
     message.displayOrder = message.displayOrder + toRow;
     }
     else if (fromRow < toRow)  // it moved forward, shift back
     {
     message.displayOrder = i;
     }
     else  // it moved backward, shift forward
     {
     message.displayOrder = i+2;
     }
     
     [QuickMessage updateQuickMessageOrder:message];
     }*/
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCellEditingStyle style = UITableViewCellEditingStyleNone;
    
    if (tableView.editing && indexPath.section != kAddQuickMessageCellSection)
        style = UITableViewCellEditingStyleDelete;
    
    return style;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        QuickMessage * message = [self.quickMessageArray objectAtIndex:indexPath.row];
        [QuickMessage deleteQuickMessage:message];
        
        for (NSInteger i=indexPath.row+1; i<[self.quickMessageArray count]; i++)
        {
            QuickMessage * nextMsg = [self.quickMessageArray objectAtIndex:i];
            nextMsg.displayOrder--;
            [QuickMessage updateQuickMessageOrder:nextMsg];
        }
        
        [self.quickMessageArray removeAllObjects];
        [self.quickMessageArray addObjectsFromArray:[QuickMessage getQuickMessages]];
        
        [self.tableView reloadData];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger count = 1;
    
    if (tableView.editing)
        count = 2;
    
    return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count =  0;
    
    if (tableView.editing && section == kAddQuickMessageCellSection)
    {
        count = 1;
    }
    else
    {
        if (self.isSearching)
            count = [self.searchArray count];
        else
            count = [self.quickMessageArray count];
    }
    
    return count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = kValueDefaultCellHeight;

    if ( !(tableView.editing && indexPath.section == kAddQuickMessageCellSection) )
    {
        QuickMessage *quickMessage = [self getQuickMessageAtIndexPath:indexPath];
        UIFont *font =kDefaultCellLabelFont;
        CGFloat heightOfText = [QuickMessageCell heightOfText:quickMessage.message withFont:font];
        height = MAX(kValueDefaultCellHeight, heightOfText + 30.f);
    }
    
    return height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"QUICK_MESSAGE_CELL";

    if (tableView.editing && indexPath.section == kAddQuickMessageCellSection)
    {
        EditableQuickMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:@"editableQuickMessageCell"];
        
        if(cell == nil)
        {
            cell = [[EditableQuickMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"editableQuickMessageCell"];
            cell.delegate = self;
            cell.textLabel.font = [UIFont boldSystemFontOfSize:15.0];
        }
        
        cell.textLabel.text     = QliqLocalizedString(@"2198-TitleAddQuickMessage");
        cell.accessibilityLabel = @"AddQuickMessage";
        cell.imageView.image    = [UIImage imageNamed:@"btn-add-blue.png"];
        self.currentEditCell    = cell;
        
        return cell;
    }
    
    
    QuickMessageCell *cell = (QuickMessageCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil)
    {
        cell = [[QuickMessageCell alloc] initWithStyle:3 reuseIdentifier:CellIdentifier];
    }
    cell.quickMessageLabel.font = kDefaultCellLabelFont

    QuickMessage *quickMessageObj = [self getQuickMessageAtIndexPath:indexPath];
    if (quickMessageObj)
    {
        cell.quickMessageLabel.text         = quickMessageObj.message;
        cell.quickMessageLabel.numberOfLines = NSIntegerMax;
        cell.quickMessageLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        cell.accessibilityLabel     = quickMessageObj.message;
        cell.accessoryType          = 0;
        cell.editingAccessoryType   = 0;
        cell.selectionStyle         = 1;
    }
    
    if (tableView.editing)
        cell.showsReorderControl = YES;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (tableView.editing)
    {
        if (indexPath.section == kAddQuickMessageCellSection)
        {
            EditableQuickMessageCell *cell = (EditableQuickMessageCell*)[tableView cellForRowAtIndexPath:indexPath];
            cell.editing = YES;
            [cell.textField becomeFirstResponder];
            [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];
        }
        return;
    }
    
    self.selectedQuickMessageObj = [self.quickMessageArray objectAtIndex:indexPath.row];
    [self clickSelectQuickMessageDone:indexPath];
    
}

#pragma mark * UISearchBarField Delegate

- (void)doSearch:(NSString *)searchText
{
    if ([searchText length] > 0)
    {
        self.isSearching = YES;
        [self.searchArray removeAllObjects];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"message contains [c] %@ ", searchText, searchText, searchText];
        [self.searchArray addObjectsFromArray:self.quickMessageArray];
        [self.searchArray filterUsingPredicate:predicate];
    }
    else
    {
        self.isSearching = NO;
    }
    
    [self.tableView reloadData];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self doSearch:searchText];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self doSearch:searchBar.text];
    [searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

#pragma mark * EditableQuickMessageCell Delegate

- (void)EditableQuickMessageCell:(EditableQuickMessageCell *)cell didEndEditingWithResultString:(NSString *)string {
    [self saveNewQuickMessage];
}

@end

//
//  AddToListViewController.m
//  qliq
//
//  Created by Vita on 7/18/12.
//  Copyright (c) 2012 Al Digit. All rights reserved.
//

#import "AddToListViewController.h"

#import "QliqListService.h"
#import "ContactList.h"
#import "CreateListViewController.h"

@interface AddToListViewController ()

@property (weak, nonatomic) IBOutlet UILabel *navigationRightTitleLabel;
@property (weak, nonatomic) IBOutlet UIButton *createNewListButton;


@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSMutableArray * lists;
@property (nonatomic, strong) NSMutableArray * userLists;

@end

@implementation AddToListViewController

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self)
    {
        self.tableView.accessibilityLabel = @"CustomListTableView";
        self.writeUsersToDB = YES;
    }
    return self;
}

- (void)configureDefaultText {
    self.navigationRightTitleLabel.text = QliqLocalizedString(@"2178-TitleYourContactLists");
    [self.createNewListButton setTitle:QliqLocalizedString(@"2179-TitleCreateNewList") forState:UIControlStateNormal];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureDefaultText];
    
    [self.navigationController setNavigationBarHidden:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO];
    
    self.lists      = [NSMutableArray arrayWithArray:[[QliqListService sharedService] getLists]];
    self.userLists  = [NSMutableArray arrayWithArray:[[QliqListService sharedService] getListsOfUser:self.contactId]];
    
    [self.tableView reloadData];
}

AUTOROTATE_METHOD

#pragma mark IBActions

- (IBAction)onBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onCreateNewListButton:(id)sender {
    CreateListViewController *addToListVC = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([CreateListViewController class])];
    addToListVC.shouldShowContactsToAdd = YES;
    [self.navigationController pushViewController:addToListVC animated:YES];
}

#pragma mark - UITableViewDataSource/Delegate

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        ContactList * list = [self.lists objectAtIndex:indexPath.row];
        [[QliqListService sharedService] removeList:list];
        [self.lists removeObject:list];
        [self.userLists removeObject:list];
        
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationMiddle];
    }
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.lists count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 40.0;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"CustomCellIdentifier";
    CustomListTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell)
    {
        cell = [[CustomListTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        cell.delegate = self;
    }
    
    ContactList *list = [self.lists objectAtIndex:indexPath.row];
    
    cell.checkmarkButton.userInteractionEnabled = NO;
    cell.checked = [self.userLists containsObject:list];
    [cell setListTitle:list.name];
      
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self checkedButtonPressed: (CustomListTableViewCell*)[tableView cellForRowAtIndexPath:indexPath]];
}

#pragma mark - CustomListCell Delegate

- (void)checkedButtonPressed:(CustomListTableViewCell *)cell 
{
    cell.checked = !cell.checked;
    
    ContactList *list = [self.lists objectAtIndex:[self.tableView indexPathForCell:cell].row];
    
    if (self.writeUsersToDB)
    {
        if (cell.checked)
        {
            [[QliqListService sharedService] addUserWithContactId:self.contactId toList:list];
            [self.userLists addObject:list];
        }
        else
        {
            [[QliqListService sharedService] removeUserWithContactId:self.contactId fromList:list];
            [self.userLists removeObject:list];
        }
    }
    else
    {
        if (cell.checked)
        {
            [self.delegate addToListViewController:self didCheckedList:list];
        }
        else
        {
            [self.delegate addToListViewController:self didUncheckedList:list];
        }
    }
}

@end

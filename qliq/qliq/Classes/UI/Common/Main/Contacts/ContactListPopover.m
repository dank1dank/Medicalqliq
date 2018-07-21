//
//  ContactListPopover.m
//  qliq
//
//  Created by Valerii Lider on 10/20/14.
//
//

#import "ContactListPopoverCell.h"
#import "ContactListPopover.h"

#define kCellIdentifierContactSortOption @"CONTACT_SORT_OPTION";
#define kValueRowHeight 30.f

@implementation ContactListPopover

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        
        self.currentContactList = ContactListOnlyQliq;

        self.heightForRow = kValueRowHeight;
        [self setTableContent];
    }
    return self;
}

#pragma mark - Private

- (void)setTableContent
{
    self.content = nil;
    self.content = [NSMutableArray new];
    
//    [self.content addObject:@(ContactListAll)];
    [self.content addObject:@(ContactListOnlyQliq)];
    [self.content addObject:@(ContactListAvialable)];
    [self.content addObject:@(ContactListDoNotDistrub)];
    [self.content addObject:@(ContactListAway)];
    [self.content addObject:@(ContactListIphoneContact)];
}

#pragma mark - Actions -


#pragma mark - Delegates -

#pragma mark - UITableviewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.heightForRow;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;
    if (self.content)
        count = self.content.count;
    
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"CONTACT_SORT_OPTION";
    ContactListPopoverCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    ContactLists contactList = [[self.content objectAtIndex:indexPath.row] integerValue];
    switch (contactList)
    {
        case ContactListAll:
            cell.nameSortOption.text = QliqLocalizedString(@"2114-TitleAll");
            break;
        case ContactListOnlyQliq:
            cell.nameSortOption.text = QliqLocalizedString(@"2118-TitleMyQliqNetwork");
            break;
        case ContactListAvialable:
            cell.nameSortOption.text = QliqLocalizedString(@"2115-TitleAvailable");
            break;
        case ContactListDoNotDistrub:
            cell.nameSortOption.text = QliqLocalizedString(@"2116-TitleDND");
            break;
        case ContactListAway:
            cell.nameSortOption.text = QliqLocalizedString(@"2117-TitleAway");
            break;
        case ContactListIphoneContact:
            cell.nameSortOption.text = QliqLocalizedString(@"2119-TitleiPhoneContacts");
            break;
        default:
            cell.nameSortOption.text = QliqLocalizedString(@"2125-TitleContacts");
            break;
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < self.content.count)
    {
        ContactLists contactList = [[self.content objectAtIndex:indexPath.row] integerValue];
        self.currentContactList = contactList;
        if ([self.delegate respondsToSelector:@selector(pressedSortOption:)])
            [self.delegate pressedSortOption:contactList];
    }
    
    [tableView reloadData];
}
    
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end

//
//  CareTeamMemberDetailsViewController.m
//  CCiPhoneApp
//
//  Created by Paul Bar on 11/18/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import "CareTeamMemberDetailsViewController.h"

@implementation CareTeamMemberDetailsViewController
@synthesize careTeamMember;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle


// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    careTeamMemberDetailsView = [[CareTeamMemberDetailsView alloc] init];
    careTeamMemberDetailsView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    careTeamMemberDetailsView.autoresizesSubviews = YES;
    careTeamMemberDetailsView.providerName = self.careTeamMember.name;
    careTeamMemberDetailsView.infoTable.delegate = self;
    careTeamMemberDetailsView.infoTable.dataSource = self;
    self.view = careTeamMemberDetailsView;
}



-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationItem.rightBarButtonItem = [self rightItemWithTitle:@"Provider Details" buttonImage:nil buttonAction:nil];
}
/*
 // Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
 - (void)viewDidLoad
 {
 [super viewDidLoad];
 }
 */

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -
#pragma mark UITableViewDataSource

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}
-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(section == 0)
    {
        return 4;
    }
    if(section == 1)
    {
        return 3;
    }
    return 0;
}

-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 35.0;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseId = @"infoTableViewCell";
    CareTeamMemberDetailsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseId];
    if(cell == nil)
    {
        cell = [[[CareTeamMemberDetailsTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseId]autorelease];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
	
	if(indexPath.section==0){
		switch (indexPath.row) 
		{
			case 0: cell.textLabel.text = @"Mobile"; cell.detailTextLabel.text = self.careTeamMember.mobile; 
				cell.accessoryView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"phone_gray.png"]] autorelease];
				break;
			case 1: cell.textLabel.text = @"Phone"; cell.detailTextLabel.text = self.careTeamMember.phone; 
				cell.accessoryView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"phone_gray.png"]] autorelease];
				break;
			case 2: cell.textLabel.text = @"qliqChat"; cell.detailTextLabel.text = @""; 
				cell.accessoryView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"chat_gray.png"]] autorelease];
				break;
			case 3: cell.textLabel.text = @"Email"; cell.detailTextLabel.text = self.careTeamMember.email; 
				cell.accessoryView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"email_gray.png"]] autorelease];
				break;
			default:
				break;
		}
	} else if (indexPath.section==1){
		switch (indexPath.row) 
		{
			case 0: cell.textLabel.text = @"NPI"; cell.detailTextLabel.text = self.careTeamMember.memberId; break;
			case 1: cell.textLabel.text = @"Specialty"; cell.detailTextLabel.text = self.careTeamMember.specialty; break;
			case 2:
				if([self.careTeamMember.memberType isEqualToString:@"Nurse"]){
					cell.textLabel.text = @"Hospital"; cell.detailTextLabel.text = self.careTeamMember.facilityName;
					cell.accessoryView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cell-chevron.png"]] autorelease];
				}else{
					cell.textLabel.text = @"Group"; cell.detailTextLabel.text = self.careTeamMember.groupName;
					cell.accessoryView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cell-chevron.png"]] autorelease];
				}
				break;
			default:
				break;
		}
	}
	
    
    return cell;
}

#pragma mark -
#pragma mark UITableViewDelegate

-(CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 25.0;
}

-(UIView*) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    TableSectionHeaderWithLabel *header = [[TableSectionHeaderWithLabel alloc] init];
    header.sectionIndex = section;
    header.backgroundColor = [UIColor colorWithWhite:0.2039f alpha:1.0f];
    header.textLabel.backgroundColor = [UIColor clearColor];
    header.textLabel.textColor = [UIColor whiteColor];
    header.textLabel.font = [UIFont boldSystemFontOfSize:10.0];
    
    switch (section) 
    {
        case 0: header.textLabel.text = @"Provider Contact"; break;
        case 1: header.textLabel.text = @"Provider Details"; break;
        default:
            break;
    }
    return [header autorelease];
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}
@end

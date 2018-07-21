//
//  GenericListViewController.m
//  CCiPhoneApp
//
//  Created by Marcin Zbijowski on 20/05/2011.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import "GenericListViewController.h"
#import "GenericTableViewCell.h"

NSInteger const kGenericListElementHeight = 35;

@implementation GenericListViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
	[_elements release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithWhite:0.2078 alpha:1.0f];
    
    CGFloat height = MIN(416, _elements.count * kGenericListElementHeight);
    
	_tableView=[[UITableView alloc] initWithFrame:CGRectMake(0,0,320,height) style:UITableViewStylePlain];
	_tableView.editing=NO;
	_tableView.delegate = self;
	_tableView.dataSource = self;
	_tableView.separatorColor=[UIColor lightGrayColor];
	_tableView.separatorStyle=1;
	_tableView.tag=0;
	_tableView.backgroundColor=[UIColor clearColor];
	_tableView.clipsToBounds=YES;
	[self.view addSubview:_tableView];
    
    self.navigationItem.rightBarButtonItem = [self rightItemWithTitle:_rightTitle
                                                          buttonImage:nil buttonAction:nil];
}

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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_elements != nil) {
        return [_elements count];
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *CellIdentifier = @"GenericCell";
	GenericTableViewCell *cell = (GenericTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[GenericTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    cell.textLabel.text = [_elements objectAtIndex:indexPath.row];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
	return kGenericListElementHeight;
}

@end

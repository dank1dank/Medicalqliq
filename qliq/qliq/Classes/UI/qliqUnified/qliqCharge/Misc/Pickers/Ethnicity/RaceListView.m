// Created by Developer Toy
//RaceListView.m
#import "RaceListView.h"
#import "RoundViewController.h"
#import "GenericTableViewCell.h"

@implementation RaceListView

- (void)loadView {
    [super loadView];
    _elements = [[NSArray alloc] initWithObjects:
                 @"White",
                 @"Alaska Native",
                 @"American Indian",
                 @"Asian",
                 @"Black or African American",
                 @"Multiracial",
                 @"Native Hawaiian",
                 nil];
    _rightTitle = NSLocalizedString(@"Ethnicity", @"Ethnicity");
	self.view.backgroundColor = [UIColor colorWithWhite:0.2078 alpha:1.0f];
}

-(IBAction)clickDoneSelectIRace:(NSIndexPath *)indexPath {
	NSArray *controllers =self.navigationController.viewControllers;
	int level=[controllers count]-2;
    
	if (level>=0) {
		UIViewController *last=(UIViewController *)[controllers objectAtIndex:level];
        if ([last isKindOfClass:[RoundViewController class]]) {
            ((RoundViewController *)last).selectedEthnicity = [_elements objectAtIndex:indexPath.row];
        }
		[last.navigationController popViewControllerAnimated:YES];
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self clickDoneSelectIRace:indexPath];
}

- (void)viewDidUnload {
}

- (void)dealloc {
	[super dealloc];
}

@end

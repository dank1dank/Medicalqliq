// Created by Developer Toy
//InsuranceListView.m
#import "InsuranceListView.h"

@implementation InsuranceListView

- (void)loadView {
    [super loadView];
    _rightTitle = NSLocalizedString(@"Insurance", @"Insurance");
    _elements = [[NSArray alloc] initWithObjects:
                 @"Medicare",
                 @"Medicaid",
                 @"Selfpay",
                 @"Private",
                 nil];

}


-(IBAction)clickDoneSelectInsurance:(NSIndexPath *)indexPath {
	NSArray *controllers =self.navigationController.viewControllers;
	int level=[controllers count]-2;
	if (level>=0) {
		UIViewController *last=(UIViewController *)[controllers objectAtIndex:level];
		[last.navigationController popViewControllerAnimated:YES];
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self clickDoneSelectInsurance:indexPath];
}

- (void)viewDidUnload {
}

- (void)dealloc {
	[super dealloc];
}
@end

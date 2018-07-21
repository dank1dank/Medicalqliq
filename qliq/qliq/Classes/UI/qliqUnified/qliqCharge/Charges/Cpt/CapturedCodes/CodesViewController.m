//
//  CodesViewController.m
//  qliq
//
//  Created by Paul Bar on 3/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CodesViewController.h"
#import "CodesView.h"
#import "RightNavigationViewWithSlider.h"
#import "LabelSliderViewItem.h"
#import "SliderView.h"
#import "NSDate+Helper.h"
#import "Helper.h"
#import "PatientVisit.h"
#import "PatientVisitService.h"

@interface CodesViewController()

@property (nonatomic, retain) NSArray *pickerViewArray;
@property (nonatomic, retain) NSDateFormatter* dateFormatter;
@property (nonatomic, assign) NSInteger futureDaysToShow;
@property (nonatomic, assign) NSInteger pastDaysToShow;
@property (nonatomic, retain) PatientVisitService* patientVisitService;

@end

@implementation CodesViewController
@synthesize dateFormatter;
@synthesize futureDaysToShow;
@synthesize pastDaysToShow;
@synthesize pickerViewArray;
@synthesize selectedDate;
@synthesize patientVisit;
@synthesize patientVisitService;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
        pickerViewArray = [[NSMutableArray alloc] init];
        [pickerViewArray addObjectsFromArray:[Helper getFutureDates:self.futureDaysToShow]];
        NSDate *today = [NSDate dateWithoutTime];
        [pickerViewArray addObject:today];
        self.selectedDate = today;
        [pickerViewArray addObjectsFromArray:[Helper getPastDates:self.pastDaysToShow]];
        
        horizontalPickerView = [[HorizontalPickerView alloc] initWithFrame: CGRectMake(0.0, 40.0, 320, 55)];
        horizontalPickerView.rowWidth = 90.0;
        horizontalPickerView.delegate = self;
        horizontalPickerView.dividerView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"picker-selector"]] autorelease];
        horizontalPickerView.dividerView.userInteractionEnabled = NO;
        
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setDateFormat:@"MM/dd/yy"];
        
        self.futureDaysToShow = 7;
        self.pastDaysToShow = 30;
    }
    return self;
}

-(void) dealloc
{
    [patientVisitService release];
    [patientVisit release];
    [selectedDate release];
    [pickerViewArray release];
    [dateFormatter release];
    [super dealloc];
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
    codesView = [[CodesView alloc] init];
    self.view = codesView;
    [codesView release];
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view addSubview:horizontalPickerView];
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    RightNavigationViewWithSlider *rightNavView = [[RightNavigationViewWithSlider alloc] init];
    LabelSliderViewItem *labelSliderItem1 = [[LabelSliderViewItem alloc] init];
    labelSliderItem1.label.font = [UIFont fontWithName:@"Arial-BoldMT" size:12];
    labelSliderItem1.label.text = @"CPT";
    labelSliderItem1.labelColor = [UIColor colorWithRed:(47.0/255.0) green:(114.0/255.0) blue:(170.0/255.0) alpha:1.0];
    labelSliderItem1.selectedLabelColor = [UIColor colorWithRed:(0.0/255.0) green:(57.0/255.0) blue:(100.0/255.0) alpha:1.0];
    
    LabelSliderViewItem *labelSliderItem2 = [[LabelSliderViewItem alloc] init];
    labelSliderItem2.label.font = [UIFont fontWithName:@"Arial-BoldMT" size:12];
    labelSliderItem2.label.text = @"Non-CPT";
    labelSliderItem2.labelColor = [UIColor colorWithRed:(47.0/255.0) green:(114.0/255.0) blue:(170.0/255.0) alpha:1.0];
    labelSliderItem2.selectedLabelColor = [UIColor colorWithRed:(0.0/255.0) green:(57.0/255.0) blue:(100.0/255.0) alpha:1.0];
    NSArray *sliderItems = [NSArray arrayWithObjects:labelSliderItem1,labelSliderItem2, nil];
    [rightNavView.sliderView setItems:sliderItems];
    
    rightNavView.sliderView.delegate = self;
    
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:rightNavView];
    self.navigationItem.rightBarButtonItem = barButtonItem;
    rightNavView.frame = CGRectMake(rightNavView.frame.origin.x,
                                    rightNavView.frame.origin.y,
                                    [[UIScreen mainScreen] bounds].size.width / 2.0,
                                    self.navigationController.navigationBar.frame.size.height);
    [rightNavView release];
    [barButtonItem release];
    
    [horizontalPickerView reload];
    [horizontalPickerView selectRow:0 animated:NO];
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


#pragma mark -
#pragma mark SliderViewDelegate

-(void) sliderView:(SliderView *)sliderView didSelectItemAtIndex:(NSInteger)index
{
    
}

#pragma mark - 
#pragma mark HorisontalPickerViewDelegate

- (NSString*) horizontalPickerView: (HorizontalPickerView*) pickerView 
                        dateForRow: (NSInteger) row
{
    return [self.dateFormatter stringFromDate:[pickerViewArray objectAtIndex:row]];
}


- (NSString*) horizontalPickerView: (HorizontalPickerView*) pickerView 
                         dayForRow: (NSInteger) row
{
    NSString* result;
    
    NSDateFormatter *tmpdateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    NSDate *date = [pickerViewArray objectAtIndex:row];
    
    if (date != nil) 
    {
        [tmpdateFormatter setDoesRelativeDateFormatting:YES];
        [tmpdateFormatter setTimeStyle:NSDateFormatterNoStyle];
        [tmpdateFormatter setDateStyle:NSDateFormatterShortStyle];
        NSDate *today = [NSDate dateWithoutTime];
        NSString *str = nil;
        if (![date isEqualToDate:today])
        {
            [tmpdateFormatter setDoesRelativeDateFormatting:NO];
            [tmpdateFormatter setDateFormat:@"EE"];
            str = [tmpdateFormatter stringFromDate:date];
            str = [str uppercaseString];
        }
        else
        {
            str = [tmpdateFormatter stringFromDate:date];
        }
        result = str;
    }
    else 
    {
        result = NSLocalizedString(@"ALL", @"ALL");
    }
    return result;
}


- (NSInteger) horizontalPickerViewNumberOfRows: (HorizontalPickerView*) pickerView
{
    return [pickerViewArray count];
}

- (void) horizontalPickerView: (HorizontalPickerView*) pickerView
                 didSelectRow: (NSInteger) row
{
    self.selectedDate = [pickerViewArray objectAtIndex:row];
    /*self.searchBar.text = @"";
    [self refresh];*/
}

@end

//
//  SearchPatientsTableViewCell.h
//  qliq
//
//  Created by Valerii Lider on 01/03/2017.
//
//

#import <UIKit/UIKit.h>

@interface SearchPatientsTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIButton *searchButton;
@property (weak, nonatomic) IBOutlet UITextField *lastNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *firstNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *dateOfBirthTextField;
@property (weak, nonatomic) IBOutlet UITextField *mrnTextField;

//Constraints
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *searchFieldImageFrameHeightConstraint;

- (BOOL)isFillSearchTextFieldWithTag:(NSInteger)tag;

@end

//
//  MYCustomPanel.h
//  MYBlurIntroductionView-Example
//
//  Created by Matthew York on 10/17/13.
//  Copyright (c) 2013 Matthew York. All rights reserved.
//

#import "MYIntroductionPanel.h"
#import "HTAutocompleteTextField.h"

@interface OAInitViewPanel : MYIntroductionPanel <UITextViewDelegate> {
    
}

@property (weak, nonatomic) IBOutlet UIButton *nextButton;
@property (weak, nonatomic) IBOutlet UILabel *labelView;
@property (weak, nonatomic) IBOutlet UILabel *descriptionView;
@property (weak, nonatomic) IBOutlet HTAutocompleteTextField *countryName;

- (IBAction)nextButtonClicked:(id)sender;
- (id)initWithFrame:(CGRect)frame nibNamed:(NSString *)nibName;

@end

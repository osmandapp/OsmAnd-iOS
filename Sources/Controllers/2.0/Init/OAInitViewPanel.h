//
//  MYCustomPanel.h
//  MYBlurIntroductionView-Example
//
//  Created by Matthew York on 10/17/13.
//  Copyright (c) 2013 Matthew York. All rights reserved.
//

#import "MYIntroductionPanel.h"

@interface OAInitViewPanel : MYIntroductionPanel <UITextViewDelegate, UITextFieldDelegate> {
    
}

@property (weak, nonatomic) IBOutlet UIButton *nextButton;
@property (weak, nonatomic) IBOutlet UILabel *labelView;
@property (weak, nonatomic) IBOutlet UILabel *descriptionView;
@property (weak, nonatomic) IBOutlet UITextField *countryName;

- (IBAction)nextButtonClicked:(id)sender;
- (id)initWithFrame:(CGRect)frame nibNamed:(NSString *)nibName;

@end

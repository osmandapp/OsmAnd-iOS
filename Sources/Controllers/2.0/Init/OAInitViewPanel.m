//
//  MYCustomPanel.m
//  MYBlurIntroductionView-Example
//
//  Created by Matthew York on 10/17/13.
//  Copyright (c) 2013 Matthew York. All rights reserved.
//

#import "OAInitViewPanel.h"
#import "MYBlurIntroductionView.h"
#import "Localization.h"

@implementation OAInitViewPanel

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame nibNamed:(NSString *)nibName
{
    self = [super initWithFrame:frame nibNamed:nibName];
    
    _offlineMapsLabel.text = OALocalizedString(@"offline_maps");
    _downloadMapLabel.text = [OALocalizedString(@"download_map") uppercaseStringWithLocale:[NSLocale currentLocale]];
    [_nextButton setTitle:OALocalizedStringUp(@"intro_next") forState:UIControlStateNormal];
    _countryName.placeholder = OALocalizedString(@"intro_placeholder");

    self.countryName.delegate = self;
    [self.parentIntroductionView setEnabled:NO];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    [self addGestureRecognizer:tap];
    
    return self;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    [self.parentIntroductionView.delegate introduction:self.parentIntroductionView didFinishWithType:MYFinishTypeSwipeOut];
    return NO;
}

#pragma mark - Interaction Methods
//Override them if you want them!

-(void)panelDidAppear
{
    /*
    //You can use a MYIntroductionPanel subclass to create custom events and transitions for your introduction view
    self.countryName.delegate = self;
    [self.parentIntroductionView setEnabled:NO];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    [self addGestureRecognizer:tap];
     */

}

- (void)tap:(id)sender
{
    [self endEditing:YES];
}


-(void)panelDidDisappear
{
}

#pragma mark Outlets

- (IBAction)nextButtonClicked:(id)sender
{
    if (self.parentIntroductionView.CurrentPanelIndex == 0)
        [self.parentIntroductionView.delegate introduction:self.parentIntroductionView didFinishWithType:MYFinishTypeSkipButton];
    else
        [self.parentIntroductionView changeToPanelAtIndex:self.parentIntroductionView.CurrentPanelIndex+1];
}

- (IBAction)countryNameChanged:(id)sender
{
}

@end

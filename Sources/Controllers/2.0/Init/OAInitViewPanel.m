//
//  MYCustomPanel.m
//  MYBlurIntroductionView-Example
//
//  Created by Matthew York on 10/17/13.
//  Copyright (c) 2013 Matthew York. All rights reserved.
//

#import "OAInitViewPanel.h"
#import "MYBlurIntroductionView.h"
#import "OAAutocompleteManager.h"

@implementation OAInitViewPanel

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame nibNamed:(NSString *)nibName {
    self = [super initWithFrame:frame nibNamed:nibName];
    [self.parentIntroductionView setEnabled:NO];
    
    [HTAutocompleteTextField setDefaultAutocompleteDataSource:[OAAutocompleteManager sharedManager]];
    
    return self;
}


#pragma mark - Interaction Methods
//Override them if you want them!

-(void)panelDidAppear{
    NSLog(@"Panel Did Appear");
    //You can use a MYIntroductionPanel subclass to create custom events and transitions for your introduction view
    [self.parentIntroductionView setEnabled:NO];
}

-(void)panelDidDisappear{
    NSLog(@"Panel Did Disappear");
    
}

#pragma mark Outlets

- (IBAction)nextButtonClicked:(id)sender {
    if (self.parentIntroductionView.CurrentPanelIndex == 2)
        [self.parentIntroductionView.delegate introduction:self.parentIntroductionView didFinishWithType:MYFinishTypeSwipeOut];
    else
        [self.parentIntroductionView changeToPanelAtIndex:self.parentIntroductionView.CurrentPanelIndex+1];
}

- (IBAction)countryNameChanged:(id)sender {
    
}

@end

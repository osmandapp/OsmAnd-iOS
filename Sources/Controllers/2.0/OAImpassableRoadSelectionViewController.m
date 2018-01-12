//
//  OAImpassableRoadSelectionViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 06/01/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAImpassableRoadSelectionViewController.h"
#import "Localization.h"
#import "OARootViewController.h"

@interface OAImpassableRoadSelectionViewController ()

@end

@implementation OAImpassableRoadSelectionViewController

- (NSAttributedString *) getAttributedTypeStr
{
    return [[NSAttributedString alloc] initWithString:OALocalizedString(@"shared_string_select_avoid_road_on_map")];
}

- (BOOL) supportMapInteraction
{
    return YES;
}

- (BOOL) supportFullScreen
{
    return YES;
}

- (BOOL) hasTopToolbar
{
    return YES;
}

- (BOOL) shouldShowToolbar:(BOOL)isViewVisible;
{
    return YES;
}

- (BOOL) hasContent
{
    return NO;
}

- (void) applyLocalization
{
    [self.buttonCancel setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [self.buttonCancel setImage:[UIImage imageNamed:@"ic_close.png"] forState:UIControlStateNormal];
    [self.buttonCancel setTintColor:[UIColor whiteColor]];
    self.buttonCancel.titleEdgeInsets = UIEdgeInsetsMake(0.0, 12.0, 0.0, 0.0);
    self.buttonCancel.imageEdgeInsets = UIEdgeInsetsMake(0.0, -12.0, 0.0, 0.0);
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.titleView.text = OALocalizedString(@"shared_string_select_on_map");
}

- (void) cancelPressed
{
    if (self.delegate)
        [self.delegate btnCancelPressed];
}

@end

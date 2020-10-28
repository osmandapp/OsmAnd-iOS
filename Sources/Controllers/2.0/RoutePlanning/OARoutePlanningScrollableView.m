//
//  OARoutePlanningScrollableView.m
//  OsmAnd
//
//  Created by Paul on 17.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OARoutePlanningScrollableView.h"
#import "Localization.h"
#import "OAColors.h"


@interface OARoutePlanningScrollableView()

@property (weak, nonatomic) IBOutlet UIButton *optionsButton;
@property (weak, nonatomic) IBOutlet UIButton *undoButton;
@property (weak, nonatomic) IBOutlet UIButton *redoButton;
@property (weak, nonatomic) IBOutlet UIButton *addPointButton;
@property (weak, nonatomic) IBOutlet UIButton *expandButton;
@property (weak, nonatomic) IBOutlet UIImageView *leftImageVIew;

@end

@implementation OARoutePlanningScrollableView

- (void)awakeFromNib
{
    [super awakeFromNib];
    [_optionsButton setTitle:OALocalizedString(@"shared_string_options") forState:UIControlStateNormal];
    [_addPointButton setTitle:OALocalizedString(@"add_point") forState:UIControlStateNormal];
    _expandButton.imageView.tintColor = UIColorFromRGB(color_icon_inactive);
    [_expandButton setImage:[[UIImage imageNamed:@"ic_custom_arrow_up"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    
    [_undoButton setImage:[[UIImage imageNamed:@"ic_custom_undo"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [_redoButton setImage:[[UIImage imageNamed:@"ic_custom_redo"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    
    _undoButton.imageView.tintColor = UIColorFromRGB(color_primary_purple);
    _redoButton.imageView.tintColor = UIColorFromRGB(color_primary_purple);
}

- (BOOL)supportsFullScreen
{
    return NO;
}

- (CGFloat)initialMenuHeight
{
    return 60. + self.toolBarView.frame.size.height;
}

- (CGFloat)expandedMenuHeight
{
    return DeviceScreenHeight / 2;
}

- (void) onDragged:(UIPanGestureRecognizer *)recognizer
{
    return;
}

- (CGFloat) additionalLandscapeOffset
{
    return 100.;
}

- (IBAction)onExpandButtonPressed:(id)sender
{
    if ([sender isKindOfClass:UIButton.class])
    {
        UIButton *button = (UIButton *) sender;
        if (self.currentState == EOADraggableMenuStateInitial)
        {
            [self goExpanded];
            [button setImage:[[UIImage imageNamed:@"ic_custom_arrow_down"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        }
        else
        {
            [self goMinimized];
            [button setImage:[[UIImage imageNamed:@"ic_custom_arrow_up"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        }
    }
}
- (IBAction)onOptionsButtonPressed:(id)sender
{
    if (_routePlanningDelegate)
        [_routePlanningDelegate onOptionsPressed];
}

- (IBAction)onUndoButtonPressed:(id)sender
{
    if (_routePlanningDelegate)
        [_routePlanningDelegate onUndoPressed];
}

- (IBAction)onRedoButtonPressed:(id)sender
{
    if (_routePlanningDelegate)
        [_routePlanningDelegate onRedoPressed];
}

- (IBAction)onAddPointPressed:(id)sender
{
    if (_routePlanningDelegate)
        [_routePlanningDelegate onAddPointPressed];
}

@end

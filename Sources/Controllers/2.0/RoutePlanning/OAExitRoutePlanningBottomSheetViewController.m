//
//  OAExitRoutePlanningBottomSheetViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 19.01.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAExitRoutePlanningBottomSheetViewController.h"

#import "Localization.h"
#import "OAColors.h"

#define kOABottomSheetWidth 320.0
#define kOABottomSheetWidthIPad (DeviceScreenWidth / 2)
#define kVerticalMargin 16.
#define kHorizontalMargin 20.
#define kButtonsHeightWithoutBottomPadding 116.0

@interface OAExitRoutePlanningBottomSheetViewController ()

@property (strong, nonatomic) IBOutlet UILabel *messageView;
@property (strong, nonatomic) IBOutlet UIButton *exitButton;
@property (strong, nonatomic) IBOutlet UIButton *saveButton;
@property (strong, nonatomic) IBOutlet UIButton *cancelButton;

@end

@implementation OAExitRoutePlanningBottomSheetViewController


- (instancetype) init
{
    self = [super initWithNibName:@"OAExitRoutePlanningBottomSheetViewController" bundle:nil];

    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    [self.rightButton removeFromSuperview];
    [self.leftIconView setImage:[UIImage imageNamed:@"ic_custom_routes"]];
    
    self.exitButton.layer.cornerRadius = 9.;
    self.saveButton.layer.cornerRadius = 9.;
    self.cancelButton.layer.cornerRadius = 9.;
    
    self.isFullScreenAvailable = NO;
}

- (void) applyLocalization
{
    self.titleView.text = OALocalizedString(@"osm_editing_lost_changes_title");
    self.messageView.text = OALocalizedString(@"plan_route_exit_message");
    [self.exitButton setTitle:OALocalizedString(@"shared_string_exit") forState:UIControlStateNormal];
    [self.saveButton setTitle:OALocalizedString(@"shared_string_save") forState:UIControlStateNormal];
    [self.cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
}

- (CGFloat) initialHeight
{
    CGFloat width;
    if ([OAUtilities isLandscape])
        width = OAUtilities.isIPad ? kOABottomSheetWidthIPad : kOABottomSheetWidth;
    else
        width = DeviceScreenWidth;
    
    CGFloat headerHeight = self.headerView.frame.size.height;
    CGFloat contentHeight = [OAUtilities calculateTextBounds:OALocalizedString(@"plan_route_exit_message") width:width font:[UIFont systemFontOfSize:15.]].height;
    contentHeight += _exitButton.frame.size.height + kVerticalMargin * 2;
    CGFloat buttonsHeight = [self buttonsViewHeight];
    return headerHeight + contentHeight + buttonsHeight + kVerticalMargin * 2;
}

- (CGFloat) buttonsViewHeight
{
    CGFloat bottomPadding = [OAUtilities getBottomMargin];
    bottomPadding = bottomPadding == 0 ? kVerticalMargin : bottomPadding;
    return kButtonsHeightWithoutBottomPadding + bottomPadding;
}

- (CGFloat) getViewHeight
{
    return [self initialHeight];
}

- (void) adjustFrame
{
    CGRect f = self.bottomSheetView.frame;
    CGFloat bottomMargin = [OAUtilities getBottomMargin];
    if ([OAUtilities isLandscape])
    {
        f.size.height = [self getViewHeight];
        f.size.width = OAUtilities.isIPad ? kOABottomSheetWidthIPad : kOABottomSheetWidth;
        f.origin = CGPointMake(DeviceScreenWidth/2 - f.size.width / 2, DeviceScreenHeight - f.size.height);

        CGRect buttonsFrame = self.buttonsView.frame;
        buttonsFrame.origin.y = f.size.height - self.buttonsViewHeight;
        buttonsFrame.size.height = self.buttonsViewHeight;
        buttonsFrame.size.width = f.size.width;
        self.buttonsView.frame = buttonsFrame;

        CGRect contentFrame = self.contentContainer.frame;
        contentFrame.size.height = f.size.height - buttonsFrame.size.height;
        contentFrame.origin = CGPointZero;
        self.contentContainer.frame = contentFrame;
    }
    else
    {
        f.size.height = [self getViewHeight];
        f.size.width = DeviceScreenWidth;
        f.origin = CGPointMake(0, DeviceScreenHeight - f.size.height);
        
        CGRect buttonsFrame = self.buttonsView.frame;
        buttonsFrame.size.height = self.buttonsViewHeight;
        buttonsFrame.size.width = f.size.width;
        buttonsFrame.origin.y = f.size.height - buttonsFrame.size.height;
        self.buttonsView.frame = buttonsFrame;
        
        CGRect contentFrame = self.contentContainer.frame;
        contentFrame.size.height = f.size.height - buttonsFrame.size.height;
        contentFrame.origin = CGPointZero;
        self.contentContainer.frame = contentFrame;
    }
    self.bottomSheetView.frame = f;
}

- (IBAction)exitButtonPressed:(id)sender
{
    [self dismissViewControllerAnimated:NO completion:nil];
    if (_delegate)
        [_delegate onExitRoutePlanningPressed];
}

- (IBAction)saveButtonPressed:(id)sender
{
    [self dismissViewControllerAnimated:NO completion:nil];
    if (_delegate)
        [_delegate onSaveResultPressed];
}

#pragma mark - UIPanGestureRecognizer

- (void) onDragged:(UIPanGestureRecognizer *)recognizer
{
    CGFloat heightBackup = self.contentContainer.frame.size.height;
    [super onDragged: recognizer];
    CGRect editedContentFrame = self.contentContainer.frame;
    editedContentFrame.size.height = heightBackup;
    self.contentContainer.frame = editedContentFrame;
}

@end

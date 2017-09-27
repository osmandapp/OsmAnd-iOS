//
//  OAOptionsPanelBlackViewController.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 04.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAOptionsPanelBlackViewController.h"
#import "OAMapSettingsViewController.h"
#import "OASettingsViewController.h"
#import "OAFavoriteListViewController.h"
#import "OAGPXListViewController.h"
#import "OAWebViewController.h"
#import "Localization.h"
#import "OAUtilities.h"

#import <JASidePanelController.h>
#import <UIViewController+JASidePanel.h>

#import "OARootViewController.h"
#import "OAFirebaseHelper.h"

@interface OAOptionsPanelBlackViewController () <UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIButton *menuButtonMaps;
@property (weak, nonatomic) IBOutlet UIButton *menuButtonMyData;
@property (weak, nonatomic) IBOutlet UIButton *menuButtonMyTrips;
@property (weak, nonatomic) IBOutlet UIButton *menuButtonMyWaypoints;
@property (weak, nonatomic) IBOutlet UIButton *menuButtonNavigation;
@property (weak, nonatomic) IBOutlet UIButton *menuButtonSettings;
@property (weak, nonatomic) IBOutlet UIButton *menuButtonMapsAndResources;
@property (weak, nonatomic) IBOutlet UIButton *menuButtonHelp;

@end

@implementation OAOptionsPanelBlackViewController
{
    CALayer *_menuButtonMapsDiv;
    CALayer *_menuButtonMyDataDiv;
    CALayer *_menuButtonMyTripsDiv;
    CALayer *_menuButtonMyWaypointsDiv;
    CALayer *_menuButtonNavigationDiv;
    CALayer *_menuButtonSettingsDiv;
    CALayer *_menuButtonMapsAndResourcesDiv;
}

- (void) viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    [self updateLayout:self.interfaceOrientation];
}

- (void) updateLayout:(UIInterfaceOrientation)interfaceOrientation
{
    CGFloat big;
    CGFloat small;
    
    CGRect rect = self.view.bounds;
    if (rect.size.width > rect.size.height)
    {
        big = rect.size.width;
        small = rect.size.height;
    }
    else
    {
        big = rect.size.height;
        small = rect.size.width;
    }
    
    CGFloat topY = 20.0;
    CGFloat buttonHeight = 50.0;

    _menuButtonNavigationDiv.hidden = NO;
    
    if (UIInterfaceOrientationIsPortrait(interfaceOrientation))
    {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            CGFloat scrollHeight = big - topY;
            
            self.scrollView.frame = CGRectMake(0.0, topY, small, scrollHeight);
            self.scrollView.contentSize = CGSizeMake(small, scrollHeight);
            
            self.menuButtonMaps.frame = CGRectMake(0.0, 0.0, small, buttonHeight);
            self.menuButtonMyData.frame = CGRectMake(0.0, buttonHeight * 1.0, small, buttonHeight);
            self.menuButtonMyTrips.frame = CGRectMake(0.0, buttonHeight * 2.0, small, buttonHeight);
            self.menuButtonMyWaypoints.frame = CGRectMake(0.0, buttonHeight * 3.0, small, buttonHeight);
            self.menuButtonMapsAndResources.frame = CGRectMake(0.0, buttonHeight * 4.0, small, buttonHeight);
            self.menuButtonNavigation.frame = CGRectMake(0.0, buttonHeight * 5.0, small, buttonHeight);
            
            self.menuButtonSettings.frame = CGRectMake(0.0, scrollHeight - buttonHeight * 2.0, small, buttonHeight);
            self.menuButtonHelp.frame = CGRectMake(0.0, scrollHeight - buttonHeight, small, buttonHeight);
        }
        else
        {
            CGFloat scrollHeight = big - topY;
            
            self.scrollView.frame = CGRectMake(0.0, topY, small, scrollHeight);
            self.scrollView.contentSize = CGSizeMake(small, scrollHeight);
            
            self.menuButtonMaps.frame = CGRectMake(0.0, 0.0, small, buttonHeight);
            self.menuButtonMyData.frame = CGRectMake(0.0, buttonHeight * 1.0, small, buttonHeight);
            self.menuButtonMyTrips.frame = CGRectMake(0.0, buttonHeight * 2.0, small, buttonHeight);
            self.menuButtonMyWaypoints.frame = CGRectMake(0.0, buttonHeight * 3.0, small, buttonHeight);
            self.menuButtonMapsAndResources.frame = CGRectMake(0.0, buttonHeight * 4.0, small, buttonHeight);
            self.menuButtonNavigation.frame = CGRectMake(0.0, buttonHeight * 5.0, small, buttonHeight);

            self.menuButtonSettings.frame = CGRectMake(0.0, scrollHeight - buttonHeight * 2.0, small, buttonHeight);
            self.menuButtonHelp.frame = CGRectMake(0.0, scrollHeight - buttonHeight, small, buttonHeight);
        }
    }
    else
    {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            CGFloat scrollHeight = small - topY;
            
            self.scrollView.frame = CGRectMake(0.0, topY, big, scrollHeight);
            self.scrollView.contentSize = CGSizeMake(big, scrollHeight);
            
            self.menuButtonMaps.frame = CGRectMake(0.0, 0.0, big, buttonHeight);
            self.menuButtonMyData.frame = CGRectMake(0.0, buttonHeight * 1.0, big, buttonHeight);
            self.menuButtonMyTrips.frame = CGRectMake(0.0, buttonHeight * 2.0, big, buttonHeight);
            self.menuButtonMyWaypoints.frame = CGRectMake(0.0, buttonHeight * 3.0, big, buttonHeight);
            self.menuButtonMapsAndResources.frame = CGRectMake(0.0, buttonHeight * 4.0, big, buttonHeight);
            self.menuButtonNavigation.frame = CGRectMake(0.0, buttonHeight * 5.0, big, buttonHeight);
            
            self.menuButtonSettings.frame = CGRectMake(0.0, scrollHeight - buttonHeight * 2.0, big, buttonHeight);
            self.menuButtonHelp.frame = CGRectMake(0.0, scrollHeight - buttonHeight, big, buttonHeight);
        }
        else
        {
            CGFloat viewWidth = self.view.bounds.size.width;
            CGFloat scrollHeight = small - topY;

            self.scrollView.frame = CGRectMake(0.0, topY, viewWidth, scrollHeight);
            
            if (8 * buttonHeight < self.scrollView.frame.size.height)
            {
                self.menuButtonMaps.frame = CGRectMake(0.0, 0.0, viewWidth, buttonHeight);
                self.menuButtonMyData.frame = CGRectMake(0.0, buttonHeight * 1.0, viewWidth, buttonHeight);
                self.menuButtonMyTrips.frame = CGRectMake(0.0, buttonHeight * 2.0, viewWidth, buttonHeight);
                self.menuButtonMyTrips.frame = CGRectMake(0.0, buttonHeight * 3.0, viewWidth, buttonHeight);
                self.menuButtonMapsAndResources.frame = CGRectMake(0.0, buttonHeight * 4.0, viewWidth, buttonHeight);
                self.menuButtonNavigation.frame = CGRectMake(0.0, buttonHeight * 5.0, viewWidth, buttonHeight);
                
                self.menuButtonSettings.frame = CGRectMake(0.0, scrollHeight - buttonHeight * 2.0, viewWidth, buttonHeight);
                self.menuButtonHelp.frame = CGRectMake(0.0, scrollHeight - buttonHeight, viewWidth, buttonHeight);
                
                self.scrollView.contentSize = CGSizeMake(viewWidth, scrollHeight);
            }
            else
            {
                self.menuButtonMaps.frame = CGRectMake(0.0, 0.0, viewWidth, buttonHeight);
                self.menuButtonMyData.frame = CGRectMake(0.0, buttonHeight * 1.0, viewWidth, buttonHeight);
                self.menuButtonMyTrips.frame = CGRectMake(0.0, buttonHeight * 2.0, viewWidth, buttonHeight);
                self.menuButtonMyWaypoints.frame = CGRectMake(0.0, buttonHeight * 3.0, viewWidth, buttonHeight);
                self.menuButtonMapsAndResources.frame = CGRectMake(0.0, buttonHeight * 4.0, viewWidth, buttonHeight);
                self.menuButtonNavigation.frame = CGRectMake(0.0, buttonHeight * 5.0, viewWidth, buttonHeight);
                
                self.menuButtonSettings.frame = CGRectMake(0.0, buttonHeight * 6.0, viewWidth, buttonHeight);
                self.menuButtonHelp.frame = CGRectMake(0.0, buttonHeight * 7.0, viewWidth, buttonHeight);

                self.scrollView.contentSize = CGSizeMake(viewWidth, buttonHeight * 7.0 + buttonHeight);
                _menuButtonNavigationDiv.hidden = YES;
            }
        }
    }
    
    CGFloat divX = 60.0;
    CGFloat divY = 49.5;
    CGFloat divW = self.menuButtonMaps.frame.size.width - divX;
    CGFloat divH = 0.5;

    _menuButtonMapsDiv.frame = CGRectMake(divX, divY, divW, divH);
    _menuButtonMyDataDiv.frame = CGRectMake(divX, divY, divW, divH);
    _menuButtonMyTripsDiv.frame = CGRectMake(divX, divY, divW, divH);
    _menuButtonMyWaypointsDiv.frame = CGRectMake(divX, divY, divW, divH);
    _menuButtonNavigationDiv.frame = CGRectMake(divX, divY, divW, divH);
    _menuButtonMapsAndResourcesDiv.frame = CGRectMake(divX, divY, divW, divH);
    _menuButtonSettingsDiv.frame = CGRectMake(divX, divY, divW, divH);
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.automaticallyAdjustsScrollViewInsets = NO;

    _menuButtonMapsDiv = [[CALayer alloc] init];
    _menuButtonMyDataDiv = [[CALayer alloc] init];
    _menuButtonMyTripsDiv = [[CALayer alloc] init];
    _menuButtonMyWaypointsDiv = [[CALayer alloc] init];
    _menuButtonNavigationDiv = [[CALayer alloc] init];
    _menuButtonMapsAndResourcesDiv = [[CALayer alloc] init];
    _menuButtonSettingsDiv = [[CALayer alloc] init];

    UIColor *divColor = UIColorFromRGB(0xe2e1e6);

    _menuButtonMapsDiv.backgroundColor = divColor.CGColor;
    _menuButtonMyDataDiv.backgroundColor = divColor.CGColor;
    _menuButtonMyTripsDiv.backgroundColor = divColor.CGColor;
    _menuButtonMyWaypointsDiv.backgroundColor = divColor.CGColor;
    _menuButtonNavigationDiv.backgroundColor = divColor.CGColor;
    _menuButtonMapsAndResourcesDiv.backgroundColor = divColor.CGColor;
    _menuButtonSettingsDiv.backgroundColor = divColor.CGColor;

    self.navigationController.delegate = self;
    
    [_menuButtonMaps setTitle:OALocalizedString(@"map_settings_map") forState:UIControlStateNormal];
    [_menuButtonMyData setTitle:OALocalizedString(@"my_favorites") forState:UIControlStateNormal];
    [_menuButtonMyTrips setTitle:OALocalizedString(@"menu_my_trips") forState:UIControlStateNormal];
    [_menuButtonMyWaypoints setTitle:OALocalizedString(@"map_markers") forState:UIControlStateNormal];
    [_menuButtonMapsAndResources setTitle:OALocalizedString(@"res_mapsres") forState:UIControlStateNormal];
    [_menuButtonSettings setTitle:OALocalizedString(@"sett_settings") forState:UIControlStateNormal];
    [_menuButtonHelp setTitle:OALocalizedString(@"menu_about") forState:UIControlStateNormal];
    
    [_menuButtonMaps.layer addSublayer:_menuButtonMapsDiv];
    [_menuButtonMyData.layer addSublayer:_menuButtonMyDataDiv];
    [_menuButtonMyTrips.layer addSublayer:_menuButtonMyTripsDiv];
    [_menuButtonMyWaypoints.layer addSublayer:_menuButtonMyWaypointsDiv];
    [_menuButtonMapsAndResources.layer addSublayer:_menuButtonMapsAndResourcesDiv];
    [_menuButtonNavigation.layer addSublayer:_menuButtonNavigationDiv];
    [_menuButtonSettings.layer addSublayer:_menuButtonSettingsDiv];
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction) mapsButtonClicked:(id)sender
{
    [self.sidePanelController toggleLeftPanel:self];
    [[OARootViewController instance].mapPanel mapSettingsButtonClick:sender];
}

- (IBAction) myDataButtonClicked:(id)sender
{
    [OAFirebaseHelper logEvent:@"favorites_open"];

    OAFavoriteListViewController* settingsViewController = [[OAFavoriteListViewController alloc] init];
    [self.navigationController pushViewController:settingsViewController animated:YES];
}

- (IBAction) myTripsButtonClicked:(id)sender
{
    [OAFirebaseHelper logEvent:@"trips_open"];

    if ([[OARootViewController instance].mapPanel hasGpxActiveTargetType])
    {
        [self.sidePanelController toggleLeftPanel:self];
    }
    else
    {
        OAGPXListViewController* gpxViewController = [[OAGPXListViewController alloc] init];
        [self.navigationController pushViewController:gpxViewController animated:YES];
    }
}

- (IBAction) myWaypointsButtonClicked:(id)sender
{
    [self.sidePanelController toggleLeftPanel:self];
    [[OARootViewController instance].mapPanel showCards];
}

- (IBAction) navigationButtonClicked:(id)sender
{
    [self.sidePanelController toggleLeftPanel:self];
    [[OARootViewController instance].mapPanel onNavigationClick:NO];
}

- (IBAction) settingsButtonClicked:(id)sender
{
    [OAFirebaseHelper logEvent:@"settings_open"];

    OASettingsViewController* settingsViewController = [[OASettingsViewController alloc] initWithSettingsType:kSettingsScreenMain];
    [self.navigationController pushViewController:settingsViewController animated:YES];
}

- (IBAction) mapsAndResourcesButtonClicked:(id)sender
{
    [OAFirebaseHelper logEvent:@"download_maps_open"];

    OASuperViewController* resourcesViewController = [[UIStoryboard storyboardWithName:@"Resources" bundle:nil] instantiateInitialViewController];
    [self.navigationController pushViewController:resourcesViewController animated:YES];
}

- (IBAction) helpButtonClicked:(id)sender
{
    [OAFirebaseHelper logEvent:@"help_open"];

    // Data is powered by OpenStreetMap ODbL, &#169; http://www.openstreetmap.org/copyright
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Copyright OsmAnd 2017\n\nData is powered by OpenStreetMap ODbL, ©\nhttp://www.openstreetmap.org/copyright" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];
}

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

- (BOOL) prefersStatusBarHidden
{
    return NO;
}

- (void) navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [[OARootViewController instance] closeMenuAndPanelsAnimated:NO];
}

@end
